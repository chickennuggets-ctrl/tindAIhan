//
//  OnboardingView.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Matches exact Figma wireframes: Onboarding, Continue (PABILI PO!), and All set (Prepare your tindahan).
//  Includes smooth 0% -> 64% AI download animation, floating store physics, and natural Tagalog TTS.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: Int = 1 // 1: Splash Illustration, 2: Pabili Po!, 3: Prepare your tindahan

    @AppStorage("storeName") private var storeName: String = "Nena's Sari-Sari Store"
    @AppStorage("defaultCutoff") private var defaultCutoff: String = "Kinsenas"

    // Animation states
    @State private var downloadProgress: Double = 0.0
    @State private var displayPercent: Int = 0
    @State private var hasStartedDownloadAnim = false
    @State private var isSplashAppearing = false
    @State private var floatOffset: CGFloat = 0
    @State private var isPabiliPoPulsing = false

    var body: some View {
        ZStack(alignment: .top) {
            TindAITheme.cream
                .ignoresSafeArea()

            // Top Scalloped Sari-Sari Store Roof Awning on all onboarding screens
            TindahanRoofAwning(height: 72)
                .zIndex(10)

            // Screen Content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 72)

                if currentStep == 1 {
                    screenOneSplash
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .offset(x: -60))
                        ))
                } else if currentStep == 2 {
                    screenTwoPabiliPo
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 60)),
                            removal: .opacity.combined(with: .offset(x: -60))
                        ))
                } else {
                    screenThreePrepare
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 60)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: currentStep)
    }

    // MARK: - Screen 1: Onboarding Illustration Splash
    private var screenOneSplash: some View {
        ZStack {
            // Full screen tap to proceed
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    advanceToStepTwo()
                }

            VStack(spacing: 0) {
                Spacer()

                // Animated Tindahan Store with floating physics and light beam
                TindahanIllustration(size: 290, showGroundOval: false, showLightBeam: true)
                    .offset(y: floatOffset)
                    .scaleEffect(isSplashAppearing ? 1.0 : 0.9)
                    .opacity(isSplashAppearing ? 1.0 : 0.0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        advanceToStepTwo()
                    }

                Spacer()

                // Tap prompt capsule matching wireframe
                Button {
                    advanceToStepTwo()
                } label: {
                    HStack(spacing: 8) {
                        Text("Magpatuloy")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(TindAITheme.brandRed)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(TindAITheme.brandRed)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.85), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(TindAITheme.brandRed.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                }
                .buttonStyle(.pressable(scale: 0.95))
                .opacity(isSplashAppearing ? 1.0 : 0.0)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                isSplashAppearing = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                floatOffset = -8
            }
            TextToSpeechService.shared.speakTagalog(
                "Maligayang pagdating sa TindAIhan! Ang iyong offline voice listahan para sa sari-sari store."
            )
        }
    }

    private func advanceToStepTwo() {
        Haptics.medium()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentStep = 2
        }
    }

    // MARK: - Screen 2: Continue ("PABILI PO!")
    private var screenTwoPabiliPo: some View {
        VStack(spacing: 0) {
            Spacer()

            // Centered Tindahan icon with yellow ground oval matching Figma middle screen
            TindahanIllustration(size: 195, showGroundOval: true, showLightBeam: false)

            Spacer()
                .frame(height: 28)

            // Huge bold title "PABILI PO!" matching Figma
            Text("PABILI PO!")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(TindAITheme.textPrimary)
                .tracking(1.0)
                .scaleEffect(isPabiliPoPulsing ? 1.03 : 1.0)

            Spacer()

            // Page Dots (Red capsule left, gray dot right)
            HStack(spacing: 8) {
                Capsule()
                    .fill(TindAITheme.brandRed)
                    .frame(width: 24, height: 7)
                Circle()
                    .fill(Color.gray.opacity(0.35))
                    .frame(width: 7, height: 7)
            }
            .padding(.bottom, 22)

            // Continue Button
            Button {
                Haptics.medium()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    currentStep = 3
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(TindAITheme.brandRed, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: TindAITheme.brandRed.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.pressable(scale: 0.96))
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                isPabiliPoPulsing = true
            }
            TextToSpeechService.shared.speakTagalog(
                "Pabili po! Sabihin lang ang utang, kami na ang bahalang maglista offline nang walang internet."
            )
        }
    }

    // MARK: - Screen 3: All set ("Prepare your tindahan")
    private var screenThreePrepare: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Prepare your tindahan")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                    .padding(.top, 10)

                // 1. Pangalan ng tindahan
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pangalan ng tindahan")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(TindAITheme.textSecondary)

                    TextField("Hal. Nena's Sari-Sari Store", text: $storeName)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(red: 29/255, green: 43/255, blue: 58/255).opacity(0.8), lineWidth: 1.5)
                        )
                }

                // 2. Kailan ang karaniwang singilan?
                VStack(alignment: .leading, spacing: 10) {
                    Text("Kailan ang karaniwang singilan?")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(TindAITheme.textSecondary)

                    HStack(spacing: 10) {
                        cutoffChip("Weekly")
                        cutoffChip("Kinsenas")
                        cutoffChip("Katapusan")
                    }
                }

                // 3. Download your AIssistant Card (Dark Navy with Animated Progress Bar)
                VStack(alignment: .leading, spacing: 10) {
                    // Title: Download your AIssistant with red "AI"
                    HStack(spacing: 0) {
                        Text("Download your ")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("AI")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(TindAITheme.brandRed)
                        Text("ssistant")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text("You will need internet just for this one. After that, you can now fully use it offline.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                        .lineSpacing(2)

                    // Yellow Progress Bar with Smooth Animation
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 10)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(TindAITheme.accentYellow)
                                .frame(width: max(0, barGeo.size.width * CGFloat(downloadProgress)), height: 10)
                                .animation(.easeOut(duration: 1.4), value: downloadProgress)
                        }
                    }
                    .frame(height: 10)
                    .padding(.vertical, 6)

                    // Progress label updating live
                    HStack {
                        let gbText = String(format: "%.1f", Double(displayPercent) / 100.0 * 2.1875)
                        Text("\(displayPercent)% · \(gbText) of 2.1 GB")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                            .contentTransition(.numericText())

                        Spacer()

                        HStack(spacing: 5) {
                            Circle()
                                .fill(displayPercent >= 64 ? Color.green : TindAITheme.accentYellow)
                                .frame(width: 7, height: 7)
                            Text("100% Offline Capable")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(TindAITheme.accentYellow)
                        }
                    }
                }
                .padding(20)
                .background(TindAITheme.darkNavy, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: TindAITheme.darkNavy.opacity(0.12), radius: 8, y: 4)

                Spacer()
                    .frame(height: 16)

                // Page Dots (Gray dot left, Red capsule right)
                HStack(spacing: 8) {
                    Spacer()
                    Circle()
                        .fill(Color.gray.opacity(0.35))
                        .frame(width: 7, height: 7)
                    Capsule()
                        .fill(TindAITheme.brandRed)
                        .frame(width: 24, height: 7)
                    Spacer()
                }
                .padding(.bottom, 6)

                // "You’re all set!" Button
                Button {
                    Haptics.success()
                    TextToSpeechService.shared.speakTagalog(
                        "Handa na ang iyong tindahan! Pindutin ang mikropono para maglista ng utang."
                    )
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isCompleted = true
                        dismiss()
                    }
                } label: {
                    Text("You’re all set!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(TindAITheme.brandRed, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: TindAITheme.brandRed.opacity(0.35), radius: 10, y: 4)
                }
                .buttonStyle(.pressable(scale: 0.96))
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            runDownloadAnimation()
        }
    }

    private func runDownloadAnimation() {
        guard !hasStartedDownloadAnim else { return }
        hasStartedDownloadAnim = true

        downloadProgress = 0.0
        displayPercent = 0

        withAnimation(.easeOut(duration: 1.3)) {
            downloadProgress = 0.64
        }

        Task {
            for p in 0...64 {
                try? await Task.sleep(nanoseconds: 18_000_000) // ~18ms per step
                await MainActor.run {
                    self.displayPercent = p
                }
            }
        }
    }

    private func cutoffChip(_ title: String) -> some View {
        Button {
            Haptics.light()
            defaultCutoff = title
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(TindAITheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    defaultCutoff == title ? TindAITheme.accentYellow : Color.white,
                    in: RoundedRectangle(cornerRadius: 22)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            defaultCutoff == title ? Color.clear : Color(red: 29/255, green: 43/255, blue: 58/255).opacity(0.8),
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.pressable(scale: 0.95))
    }
}

#Preview {
    OnboardingView(isCompleted: .constant(false))
}
