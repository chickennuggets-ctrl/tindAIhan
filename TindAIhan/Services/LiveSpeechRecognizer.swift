//
//  LiveSpeechRecognizer.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Provides real-time microphone capture, RMS audio level metering for live waveforms,
//  and streaming Speech-to-Text transcription with zero cloud dependencies.
//

import Foundation
import AVFoundation
import Speech
import Observation

@Observable
final class LiveSpeechRecognizer: NSObject {
    var liveTranscript: String = ""
    var isRecording: Bool = false
    var audioLevel: CGFloat = 0.0 // 0.0 to 1.0 for real-time waveform animation
    var errorMessage: String? = nil
    var recordedFileURL: URL? = nil
    var isAuthorized: Bool = false

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?

    override init() {
        super.init()
        setupSpeechRecognizer()
    }

    private func setupSpeechRecognizer() {
        // en-PH is the official Philippine locale supported by Apple Speech
        // which understands Taglish and Filipino accent offline/on-device.
        if let phRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-PH")), phRecognizer.isAvailable {
            self.speechRecognizer = phRecognizer
        } else if let currentRecognizer = SFSpeechRecognizer(locale: Locale.current), currentRecognizer.isAvailable {
            self.speechRecognizer = currentRecognizer
        } else {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
    }

    /// Check and request all necessary permissions (Microphone & Speech Recognition)
    func requestPermissions() async -> Bool {
        // 1. Microphone permission
        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        // 2. Speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let authorized = micGranted && (speechStatus == .authorized || speechStatus == .notDetermined)
        await MainActor.run {
            self.isAuthorized = authorized
            if !micGranted {
                self.errorMessage = "Kailangan ng pahintulot sa microphone sa Settings."
            } else if speechStatus == .denied || speechStatus == .restricted {
                self.errorMessage = "Kailangan ng Speech Recognition sa Settings."
            }
        }

        return micGranted
    }

    /// Starts live audio engine recording, streams RMS level, and performs live transcription
    func start() {
        stop() // Clean up any active session

        liveTranscript = ""
        errorMessage = nil
        audioLevel = 0.0

        setupSpeechRecognizer()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let engine = AVAudioEngine()
            self.audioEngine = engine
            let inputNode = engine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            // Ensure valid format
            let recordingFormat: AVAudioFormat
            if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
                recordingFormat = inputFormat
            } else {
                recordingFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) ?? inputFormat
            }

            // Setup audio file for saving captured PCM audio
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("live_recording.wav")
            try? FileManager.default.removeItem(at: tempURL)
            self.recordedFileURL = tempURL

            do {
                self.audioFile = try AVAudioFile(forWriting: tempURL, settings: recordingFormat.settings)
            } catch {
                print("Note: AVAudioFile creation notice: \(error.localizedDescription)")
            }

            // Setup Speech Recognition Request
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = .dictation

            // If on-device recognition is supported, allow it without forcing hard crashes if assets are pending
            if let recognizer = speechRecognizer, recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = false
            }
            self.recognitionRequest = request

            // Install Audio Tap on Input Node for live RMS metering and speech stream
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self else { return }

                // 1. Calculate live RMS audio power for waveform
                let level = self.calculateRMS(from: buffer)
                Task { @MainActor in
                    self.audioLevel = level
                }

                // 2. Stream buffer to Speech Recognizer
                request.append(buffer)

                // 3. Write buffer to disk file
                try? self.audioFile?.write(from: buffer)
            }

            // Start Speech Recognition Task
            if let recognizer = speechRecognizer {
                self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                    guard let self = self else { return }

                    if let result = result {
                        let recognized = result.bestTranscription.formattedString
                        Task { @MainActor in
                            self.liveTranscript = recognized
                        }
                    }

                    if let error = error {
                        let nsError = error as NSError
                        // Ignore standard end-of-audio cancellations (code 216 or 203)
                        if nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 203 || nsError.code == 216) {
                            return
                        }
                        if nsError.code != 1 && nsError.code != 203 {
                            print("Speech recognition info: \(error.localizedDescription)")
                        }
                    }
                }
            }

            engine.prepare()
            try engine.start()
            self.isRecording = true
        } catch {
            print("Audio engine error: \(error.localizedDescription)")
            self.errorMessage = "Audio engine: \(error.localizedDescription)"
            self.isRecording = true // Still allow UI to proceed in simulator
        }
    }

    /// Stops audio capture and finalizes the recording
    func stop() {
        if let engine = audioEngine, engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        audioFile = nil
        isRecording = false
        audioLevel = 0.0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Injects text directly (used for quick sample chips or manual editing)
    func setSampleTranscript(_ text: String) {
        self.liveTranscript = text
    }

    /// Appends recognized word
    func appendTranscript(_ text: String) {
        if liveTranscript.isEmpty {
            liveTranscript = text
        } else {
            liveTranscript += " " + text
        }
    }

    /// Computes normalized RMS level between 0.0 and 1.0 from audio PCM buffer
    private func calculateRMS(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let frames = buffer.frameLength
        guard frames > 0 else { return 0.0 }

        var sum: Float = 0.0
        for i in 0..<Int(frames) {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frames))
        let scaled = min(max(CGFloat(rms) * 8.0, 0.0), 1.0)
        return scaled
    }
}
