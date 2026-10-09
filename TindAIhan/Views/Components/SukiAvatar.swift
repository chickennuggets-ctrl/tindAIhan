//
//  SukiAvatar.swift
//  TindAIhan
//

import SwiftUI

/// Pastel circular avatar with customer initial matching the Figma design
struct SukiAvatar: View {
    let name: String
    var size: CGFloat = 46

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if lower.hasPrefix("aling ") {
            return "N"
        }
        if lower.hasPrefix("mang ") {
            return "M"
        }
        if lower.hasPrefix("tita ") {
            return "T"
        }
        return String(trimmed.prefix(1)).uppercased()
    }

    private var backgroundColor: Color {
        TindAITheme.avatarColor(for: name)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Text(initial)
                .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                .foregroundStyle(TindAITheme.textPrimary)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        SukiAvatar(name: "Aling Nena")
        SukiAvatar(name: "Mang Jose")
        SukiAvatar(name: "Pedro")
        SukiAvatar(name: "Tita Baby")
    }
    .padding()
    .background(TindAITheme.cream)
}
