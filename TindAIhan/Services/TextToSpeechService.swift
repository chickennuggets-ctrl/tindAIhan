//
//  TextToSpeechService.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Provides offline Text-to-Speech (TTS) for sari-sari store voice feedback,
//  audible listahan verification, and payment announcements.
//

import Foundation
import AVFoundation
import Observation

@Observable
final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TextToSpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking: Bool = false
    var isMuted: Bool = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks arbitrary text with optimal Taglish / Filipino voice settings
    func speak(_ text: String) {
        guard !isMuted else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Configure audio session to play through speaker even if silent switch is on
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("TTS audio session notice: \(error)")
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Select the best voice: fil-PH, en-PH, id-ID, or system default
        let preferredVoice = AVSpeechSynthesisVoice(language: "fil-PH") ??
                             AVSpeechSynthesisVoice(language: "en-PH") ??
                             AVSpeechSynthesisVoice(language: "id-ID") ??
                             AVSpeechSynthesisVoice(language: "en-US")

        utterance.voice = preferredVoice
        utterance.rate = 0.48 // Slightly slower, clear conversational pace for sari-sari store
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Convenience method for Tagalog speech
    func speakTagalog(_ text: String) {
        speak(text)
    }

    /// Speaks listahan confirmation when voice entry is captured
    func speakUtangSummary(customer: String, total: Double, items: [ParsedUtang.Line]) {
        let totalPesos = Int(total)
        let centavos = Int(round((total - Double(totalPesos)) * 100))

        let amountText: String
        if centavos > 0 {
            amountText = "\(totalPesos) pesos at \(centavos) sentimos"
        } else {
            amountText = "\(totalPesos) pesos"
        }

        let itemsText = items.map { "\($0.qty) \($0.item)" }.joined(separator: ", ")
        let speech = "Nailista na po para kay \(customer): \(itemsText). Kabuuang halaga: \(amountText)."
        speak(speech)
    }

    /// Speaks due date reminder for a customer
    func speakCollectionReminder(customer: String, amount: Double, dueText: String) {
        let totalPesos = Int(amount)
        let speech = "Paalala para kay \(customer): May utang na \(totalPesos) pesos. \(dueText)."
        speak(speech)
    }

    /// Speaks confirmation when customer pays
    func speakPaymentReceived(customer: String, amount: Double) {
        let totalPesos = Int(amount)
        let speech = "Salamat po! Bayad na ang utang ni \(customer) na \(totalPesos) pesos."
        speak(speech)
    }

    /// Stops any ongoing speech immediately
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
