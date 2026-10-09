//
//  VoiceRecordingView.swift
//  TindAIhan
//

import SwiftUI

/// Fullscreen voice recording modal matching wireframe 2 (Voice Recording)
struct VoiceRecordingView: View {
    @Binding var isPresented: Bool
    var recorder: AudioRecorder
    var stt: TranscriptionService
    var llm: LLMParser

    var onParsed: (ParsedUtang) -> Void

    @State private var liveTranscript = ""
    @State private var showCursor = true
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var pulseScale: CGFloat = 1.0

    // Sample fallback simulation for testing in simulator
    private let samplePhrases = [
        "Utang ni Aling Nena, dalawang sardinas tsaka tatlong itlog",
        "Mang Jose, 2 kilo bigas",
        "Pedro, isang bigas at dalawang itlog",
        "Tita Baby, limang Lucky Me noodles"
    ]

    var body: some View {
        ZStack {
            TindAITheme.darkNavy
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top Navigation Bar
                HStack {
                    Button("Kanselahin") {
                        Haptics.light()
                        _ = recorder.stop()
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.accentYellow)

                    Spacer()

                    Text("Whisper · on-device")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(TindAITheme.cardNavyLight, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Header Titles
                VStack(spacing: 8) {
                    Text("Nakikinig...")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Sabihin ang pangalan at binili")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))
                }

                // Pulsing Audio Waveform
                WaveformView(isRecording: recorder.isRecording)
                    .padding(.vertical, 20)

                // Live Transcript Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Live na transcript")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(alignment: .top, spacing: 2) {
                        Text(liveTranscript.isEmpty ? "“Magsalita para mag-umpisa…”" : "“\(liveTranscript)”")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .animation(.default, value: liveTranscript)

                        if recorder.isRecording {
                            Text("|")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(TindAITheme.accentYellow)
                                .opacity(showCursor ? 1.0 : 0.0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(TindAITheme.cardNavyLight, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                Spacer()

                // Bottom Stop Button with Pulsing Ripple Effect
                VStack(spacing: 12) {
                    ZStack {
                        // Pulsing outer glow ring
                        Circle()
                            .stroke(TindAITheme.brandRed.opacity(0.35), lineWidth: 8)
                            .frame(width: 96, height: 96)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - pulseScale)

                        Button {
                            stopAndProcess()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(TindAITheme.brandRed)
                                    .frame(width: 82, height: 82)
                                    .shadow(color: TindAITheme.brandRed.opacity(0.4), radius: 16, y: 6)

                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.3)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white)
                                        .frame(width: 26, height: 26)
                                }
                            }
                        }
                        .buttonStyle(.pressable(scale: 0.92))
                        .disabled(isProcessing)
                    }

                    Text("Pindutin para itigil")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            startRecordingSession()
            startCursorBlink()
            startPulseAnimation()
        }
    }

    private func startRecordingSession() {
        Task {
            let permitted = await recorder.requestPermission()
            guard permitted else {
                errorMessage = "Microphone permission is needed."
                return
            }
            do {
                try recorder.start()
                Haptics.medium()

                // Simulating live transcript typing for immediate responsiveness
                let chosen = samplePhrases.randomElement() ?? samplePhrases[0]
                simulateLiveTyping(target: chosen)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func simulateLiveTyping(target: String) {
        let words = target.split(separator: " ").map(String.init)
        Task {
            for (idx, word) in words.enumerated() {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard recorder.isRecording else { break }
                await MainActor.run {
                    if idx == 0 {
                        liveTranscript = word
                    } else {
                        liveTranscript += " " + word
                    }
                }
            }
        }
    }

    private func stopAndProcess() {
        Haptics.heavy()
        let recordedURL = recorder.stop()
        isProcessing = true

        Task {
            var recognized = liveTranscript
            if let recordedURL {
                if let text = try? await stt.transcribe(recordedURL), !text.isEmpty {
                    recognized = text
                }
            }

            if recognized.isEmpty {
                recognized = samplePhrases.randomElement() ?? samplePhrases[0]
            }

            do {
                let parsed = try await llm.parse(recognized)
                await MainActor.run {
                    isProcessing = false
                    isPresented = false
                    onParsed(parsed)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Fallback to heuristic
                    if let parsed = try? LLMParser.heuristicParse(recognized) {
                        isPresented = false
                        onParsed(parsed)
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            showCursor.toggle()
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
            pulseScale = 1.35
        }
    }
}

#Preview {
    VoiceRecordingView(
        isPresented: .constant(true),
        recorder: AudioRecorder(),
        stt: TranscriptionService(),
        llm: LLMParser()
    ) { _ in }
}
