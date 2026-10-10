//
//  VoiceRecordingView.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Fullscreen voice recording modal matching Figma wireframe 2 (Voice Recording).
//  Seamlessly transitions directly to the Confirmation Log (ConfirmEntryView)
//  so the user can review/edit the customer name and utang items and save it to the listahan.
//

import SwiftUI

enum VoiceFlowStep {
    case recording
    case confirming
}

/// Fullscreen voice recording modal matching wireframe 2 (Voice Recording)
struct VoiceRecordingView: View {
    @Binding var isPresented: Bool
    var llm: LLMParser
    var onSaved: (() -> Void)? = nil

    @State private var step: VoiceFlowStep = .recording
    @State private var parsedUtang: ParsedUtang = ParsedUtang(
        name: "Pedro",
        items: [
            ParsedUtang.Line(item: "itlog", qty: 2),
            ParsedUtang.Line(item: "bigas", qty: 1)
        ]
    )

    @State private var speechRecognizer = LiveSpeechRecognizer()
    @State private var showCursor = true
    @State private var isProcessing = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var isEditingTranscript = false

    // Sample quick-tap phrases for instant testing (Tagalog & English)
    private let samplePhrases = [
        "Utang ni Pedro, 2 itlog tsaka 1 bigas",
        "Pedro, 2 eggs and 1 rice",
        "Utang ni Aling Nena, 2 sardinas tsaka 3 itlog",
        "Credit of John, 3 sardines and 2 bread",
        "Mang Jose, 2 kilo bigas",
        "Tita Baby, 5 Lucky Me noodles"
    ]

    var body: some View {
        Group {
            if step == .recording {
                recordingViewContent
                    .transition(.opacity)
            } else {
                ConfirmEntryView(
                    parsed: parsedUtang,
                    onSaveComplete: {
                        isPresented = false
                        onSaved?()
                    },
                    onRerecord: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            step = .recording
                            startLiveRecordingSession()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Recording View Content
    private var recordingViewContent: some View {
        ZStack {
            TindAITheme.darkNavy
                .ignoresSafeArea()

            VStack(spacing: 18) {
                // 1. Top Navigation Bar
                HStack {
                    Button("Cancel") {
                        Haptics.light()
                        speechRecognizer.stop()
                        TextToSpeechService.shared.stop()
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.accentYellow)

                    Spacer()

                    // Whisper · on · device Badge matching Image 3
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 27/255, green: 153/255, blue: 139/255))
                            .frame(width: 6, height: 6)
                        Text("Whisper · on · device")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(TindAITheme.cardNavyLight, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // 2. Header Titles matching Image 3
                VStack(spacing: 8) {
                    Text("Listening...")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Dictate buyer’s name and products")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))
                }

                // 3. Real-Time Dynamic Audio Waveform
                WaveformView(
                    isRecording: speechRecognizer.isRecording,
                    audioLevel: speechRecognizer.audioLevel
                )
                .padding(.vertical, 10)

                // 4. Live Transcript Card matching Figma layout
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Live transcript")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))

                        Spacer()

                        // Manual keyboard toggle button
                        Button {
                            Haptics.light()
                            isEditingTranscript.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isEditingTranscript ? "checkmark.circle.fill" : "keyboard")
                                Text(isEditingTranscript ? "Tapos" : "I-type")
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(TindAITheme.accentYellow)
                        }

                        if speechRecognizer.isRecording {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(TindAITheme.brandRed)
                                    .frame(width: 6, height: 6)
                                Text("MIC LIVE")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(TindAITheme.brandRed)
                            }
                            .padding(.leading, 8)
                        }
                    }

                    if isEditingTranscript {
                        TextField("I-type ang utang (Hal. Utang ni Pedro 2 itlog)", text: $speechRecognizer.liveTranscript)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        HStack(alignment: .top, spacing: 2) {
                            let text = speechRecognizer.liveTranscript.isEmpty
                                ? "“Magsalita ng utang o pumili sa ibaba…”"
                                : "“\(speechRecognizer.liveTranscript)”"

                            Text(text)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(speechRecognizer.liveTranscript.isEmpty ? .white.opacity(0.4) : .white)
                                .lineSpacing(4)
                                .animation(.default, value: speechRecognizer.liveTranscript)

                            if speechRecognizer.isRecording {
                                Text("|")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(TindAITheme.accentYellow)
                                    .opacity(showCursor ? 1.0 : 0.0)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(TindAITheme.cardNavyLight, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                // 5. Quick Test Suggestions (Tap to populate live transcript)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("💡 O pumili ng halimbawa para masubukan:")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(samplePhrases, id: \.self) { phrase in
                                Button {
                                    Haptics.light()
                                    speechRecognizer.setSampleTranscript(phrase)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mic.fill")
                                            .font(.system(size: 11))
                                        Text(phrase)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                    }
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        speechRecognizer.liveTranscript == phrase
                                            ? TindAITheme.brandRed
                                            : TindAITheme.cardNavyLight,
                                        in: Capsule()
                                    )
                                }
                                .buttonStyle(.pressable(scale: 0.95))
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 4)

                Spacer()

                // 6. Bottom Pulsing Stop / Process Button
                VStack(spacing: 12) {
                    ZStack {
                        // Pulsing outer ripple halo
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
                                    // Stop square icon
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white)
                                        .frame(width: 26, height: 26)
                                }
                            }
                        }
                        .buttonStyle(.pressable(scale: 0.92))
                        .disabled(isProcessing)
                    }

                    Text("Tap to Stop & View Log")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.bottom, 36)
            }
        }
        .presentationBackground(TindAITheme.darkNavy)
        .onAppear {
            startLiveRecordingSession()
            startCursorBlink()
            startPulseAnimation()
        }
        .onDisappear {
            speechRecognizer.stop()
            TextToSpeechService.shared.stop()
        }
    }

    private func startLiveRecordingSession() {
        Task {
            let permitted = await speechRecognizer.requestPermissions()
            if permitted {
                speechRecognizer.start()
                Haptics.medium()
            }
        }
    }

    private func stopAndProcess() {
        Haptics.heavy()
        speechRecognizer.stop()
        isProcessing = true

        Task {
            var utterance = speechRecognizer.liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)

            // If nothing was captured, use default sample
            if utterance.isEmpty {
                utterance = samplePhrases[0]
            }

            let parsedResult: ParsedUtang
            if let result = try? await llm.parse(utterance) {
                parsedResult = result
            } else if let fallback = try? LLMParser.heuristicParse(utterance) {
                parsedResult = fallback
            } else {
                parsedResult = ParsedUtang(name: "Pedro", items: [
                    ParsedUtang.Line(item: "itlog", qty: 2),
                    ParsedUtang.Line(item: "bigas", qty: 1)
                ])
            }

            await MainActor.run {
                self.parsedUtang = parsedResult
                self.isProcessing = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.step = .confirming
                }
            }
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
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
        llm: LLMParser()
    )
}
