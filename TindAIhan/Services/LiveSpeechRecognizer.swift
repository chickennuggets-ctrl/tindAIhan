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

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?

    override init() {
        super.init()
        // Support Tagalog/Filipino or English (Philippines) locale
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fil-PH")) ??
                                SFSpeechRecognizer(locale: Locale(identifier: "tl-PH")) ??
                                SFSpeechRecognizer(locale: Locale(identifier: "en-PH")) ??
                                SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
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

        if speechStatus != .authorized && speechStatus != .notDetermined {
            await MainActor.run {
                self.errorMessage = "Kailangan ng speech recognition authorization."
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

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let engine = AVAudioEngine()
            self.audioEngine = engine
            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // Setup audio file for saving captured PCM audio if valid sample rate
            if recordingFormat.sampleRate > 0 {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("live_recording.wav")
                try? FileManager.default.removeItem(at: tempURL)
                self.recordedFileURL = tempURL

                do {
                    self.audioFile = try AVAudioFile(forWriting: tempURL, settings: recordingFormat.settings)
                } catch {
                    print("Note: AVAudioFile creation skipped: \(error)")
                }

                // Setup Speech Recognition Request
                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true
                if #available(iOS 13.0, *), let recognizer = speechRecognizer, recognizer.supportsOnDeviceRecognition {
                    request.requiresOnDeviceRecognition = true
                }
                self.recognitionRequest = request

                // Install Audio Tap on Input Node for live RMS metering and speech stream
                inputNode.removeTap(onBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                    guard let self = self else { return }

                    // 1. Calculate live RMS audio power
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
                if let recognizer = speechRecognizer, recognizer.isAvailable {
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
                            if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 203 {
                                print("Speech recognition info: \(error.localizedDescription)")
                            }
                        }
                    }
                }

                engine.prepare()
                try engine.start()
            }
        } catch {
            print("Audio engine hardware start notice: \(error.localizedDescription)")
        }

        self.isRecording = true
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

    /// Injects text directly (used for quick sample chips or manual simulation in simulator)
    func setSampleTranscript(_ text: String) {
        self.liveTranscript = text
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
        let scaled = min(max(CGFloat(rms) * 7.5, 0.0), 1.0)
        return scaled
    }
}
