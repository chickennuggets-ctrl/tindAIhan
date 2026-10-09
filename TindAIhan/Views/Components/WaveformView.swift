//
//  WaveformView.swift
//  TindAIhan
//

import SwiftUI

/// Animated audio waveform bars matching wireframe 2 (Voice Recording)
struct WaveformView: View {
    var isRecording: Bool
    @State private var phase: CGFloat = 0

    // Heights for 9 bars to create that natural symmetric voice curve
    private let baseHeights: [CGFloat] = [32, 54, 78, 110, 130, 95, 72, 48, 28]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<baseHeights.count, id: \.self) { index in
                WaveBar(
                    baseHeight: baseHeights[index],
                    index: index,
                    isRecording: isRecording,
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
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            phase = 1.0
        }
    }
}

private struct WaveBar: View {
    let baseHeight: CGFloat
    let index: Int
    let isRecording: Bool
    let phase: CGFloat

    // Modulate height with sinusoidal phase offset
    private var currentHeight: CGFloat {
        guard isRecording else { return 12 }
        let offset = sin(phase * .pi + Double(index) * 0.7)
        let scale = 0.6 + 0.45 * CGFloat(abs(offset))
        return max(16, min(140, baseHeight * scale))
    }

    var body: some View {
        Capsule()
            .fill(TindAITheme.accentYellow)
            .frame(width: 8, height: currentHeight)
            .animation(
                .easeInOut(duration: 0.35 + Double(index % 3) * 0.1)
                .repeatForever(autoreverses: true),
                value: phase
            )
    }
}

#Preview {
    ZStack {
        TindAITheme.darkNavy.ignoresSafeArea()
        WaveformView(isRecording: true)
    }
}
