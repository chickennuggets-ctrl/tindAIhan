//
//  AudioRecorder.swift
//  TindAIhan
//

import Foundation
import AVFoundation
import Observation

/// Records 16 kHz mono WAV, the format Whisper and CoreML speech models expect.
@Observable
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private(set) var isRecording = false
    private(set) var fileURL: URL?

    func requestPermission() async -> Bool {
        #if os(iOS) || os(visionOS)
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        #elseif os(macOS)
        if #available(macOS 14.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        }
        return true
        #else
        return true
        #endif
    }

    func start() throws {
        #if os(iOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("listahan.wav")
        try? FileManager.default.removeItem(at: url)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        let newRecorder = try AVAudioRecorder(url: url, settings: settings)
        newRecorder.delegate = self
        newRecorder.record()
        self.recorder = newRecorder
        self.fileURL = url
        self.isRecording = true
    }

    func stop() -> URL? {
        guard isRecording else { return fileURL }
        recorder?.stop()
        recorder = nil
        isRecording = false
        #if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        return fileURL
    }
}
