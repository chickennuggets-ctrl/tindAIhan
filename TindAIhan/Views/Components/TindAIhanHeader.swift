//
//  TindAIhanHeader.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  App header showing TindAIhan branding, 100% offline status capsule, and audio read-out button.
//

import SwiftUI

/// App header showing TindAIhan branding and offline status capsule
struct TindAIhanHeader: View {
    var isOfflineReady: Bool = true
    var onSettingsTapped: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Brand Logo: TindAIhan with red "AI"
            HStack(spacing: 0) {
                Text("Tind")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                Text("AI")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(TindAITheme.brandRed)
                Text("han")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
            }

            Spacer()

            // 100% Offline Status Pill
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 27/255, green: 153/255, blue: 139/255))
                    .frame(width: 8, height: 8)
                Text("100% offline")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.badgeGreenText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(TindAITheme.badgeGreenBg, in: Capsule())

            // Optional settings icon
            if let onSettingsTapped {
                Button {
                    Haptics.light()
                    onSettingsTapped()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TindAITheme.textSecondary)
                        .padding(8)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.pressable(scale: 0.92))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

#Preview {
    ZStack {
        TindAITheme.cream.ignoresSafeArea()
        TindAIhanHeader(onSettingsTapped: {})
    }
}
