//
//  WaveformView.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Dynamic real-time audio waveform responding live to microphone audio levels
//  and rhythmic voice oscillations matching Figma wireframe 2.
//

import SwiftUI

/// Animated audio waveform bars matching wireframe 2 (Voice Recording)
struct WaveformView: View {
    var isRecording: Bool
    var audioLevel: CGFloat = 0.0
    @State private var phase: CGFloat = 0

    // Heights for 9 bars creating the symmetric voice envelope from wireframe
    private let baseHeights: [CGFloat] = [32, 54, 78, 110, 130, 95, 72, 48, 28]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<baseHeights.count, id: \.self) { index in
                WaveBar(
                    baseHeight: baseHeights[index],
                    index: index,
                    isRecording: isRecording,
                    audioLevel: audioLevel,
                    phase: phase
                )
            }
        }
        .frame(height: 140)
        .onAppear {
            if isRecording {
                startAnimation()
            }
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
            phase = 1.0
        }
    }
}

private struct WaveBar: View {
    let baseHeight: CGFloat
    let index: Int
    let isRecording: Bool
    let audioLevel: CGFloat
    let phase: CGFloat

    private var currentHeight: CGFloat {
        guard isRecording else { return 12 }

        // Blend live mic RMS power with gentle wave breathing
        let waveOffset = sin(phase * .pi + Double(index) * 0.7)
        let baseline = 0.5 + 0.35 * CGFloat(abs(waveOffset))

        // When mic has input, scale strongly by audioLevel
        let micBoost = max(audioLevel * 1.6, 0.0)
        let finalScale = min(baseline + micBoost, 1.4)

        return max(16, min(140, baseHeight * finalScale))
    }

    var body: some View {
        Capsule()
            .fill(TindAITheme.accentYellow)
            .frame(width: 8, height: currentHeight)
            .animation(
                .spring(response: 0.18, dampingFraction: 0.65),
                value: currentHeight
            )
    }
}

#Preview {
    ZStack {
        TindAITheme.darkNavy.ignoresSafeArea()
        WaveformView(isRecording: true, audioLevel: 0.6)
    }
}
