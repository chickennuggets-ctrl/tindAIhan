//
//  Theme.swift
//  TindAIhan
//

import SwiftUI

/// Design system tokens extracted directly from Figma wireframes
enum TindAITheme {
    // Backgrounds
    static let cream = Color(red: 255/255, green: 248/255, blue: 234/255) // #FFF8EA Warm cream
    static let darkNavy = Color(red: 29/255, green: 43/255, blue: 58/255) // #1D2B3A Deep Navy
    static let cardNavy = Color(red: 29/255, green: 43/255, blue: 58/255)
    static let cardNavyLight = Color(red: 39/255, green: 55/255, blue: 74/255) // #27374A
    static let cardBackground = Color.white
    static let lightBorder = Color(red: 234/255, green: 223/255, blue: 200/255) // #EADFC8

    // Brand Colors
    static let brandRed = Color(red: 215/255, green: 38/255, blue: 61/255) // #D7263D
    static let brandRedPressed = Color(red: 190/255, green: 30/255, blue: 51/255)
    static let accentYellow = Color(red: 255/255, green: 201/255, blue: 60/255) // #FFC93C
    static let accentYellowDark = Color(red: 224/255, green: 159/255, blue: 0/255)
    static let tealButton = Color(red: 27/255, green: 153/255, blue: 139/255) // #1B998B

    // Status Badges
    static let badgeGreenBg = Color(red: 217/255, green: 242/255, blue: 238/255) // #D9F2EE
    static let badgeGreenText = Color(red: 11/255, green: 95/255, blue: 85/255) // #0B5F55
    static let badgeRedBg = Color(red: 254/255, green: 226/255, blue: 226/255)
    static let badgeRedText = Color(red: 215/255, green: 38/255, blue: 61/255)

    // Avatar Palettes
    static let avatarYellow = Color(red: 255/255, green: 201/255, blue: 60/255) // #FFC93C
    static let avatarTeal = Color(red: 191/255, green: 232/255, blue: 226/255) // #BFE8E2
    static let avatarPink = Color(red: 247/255, green: 198/255, blue: 204/255) // #F7C6CC
    static let avatarOrange = Color(red: 254/255, green: 215/255, blue: 170/255)
    static let avatarBlue = Color(red: 195/255, green: 218/255, blue: 254/255)

    // Text Colors
    static let textPrimary = Color(red: 29/255, green: 43/255, blue: 58/255) // #1D2B3A
    static let textSecondary = Color(red: 91/255, green: 102/255, blue: 112/255) // #5B6670
    static let textMuted = Color(red: 139/255, green: 151/255, blue: 162/255) // #8B97A2

    static func avatarColor(for name: String) -> Color {
        let colors = [avatarYellow, avatarTeal, avatarPink, avatarOrange, avatarBlue]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback Helpers
enum Haptics {
    static func light() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func medium() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func heavy() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }

    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func error() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}

// MARK: - Pressable Button Style with Spring Scale
struct PressableScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableScaleButtonStyle {
    static var pressable: PressableScaleButtonStyle { PressableScaleButtonStyle() }
    static func pressable(scale: CGFloat) -> PressableScaleButtonStyle { PressableScaleButtonStyle(scale: scale) }
}
