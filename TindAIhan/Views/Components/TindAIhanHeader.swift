//
//  TindAIhanHeader.swift
//  TindAIhan
//

import SwiftUI

/// App header showing TindAIhan branding and offline status capsule
struct TindAIhanHeader: View {
    var isOfflineReady: Bool = true
    var onSearchTapped: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
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
                    .fill(Color(red: 16/255, green: 185/255, blue: 129/255))
                    .frame(width: 8, height: 8)
                Text("100% offline")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.badgeGreenText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TindAITheme.badgeGreenBg, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

#Preview {
    TindAIhanHeader()
        .background(TindAITheme.cream)
}
