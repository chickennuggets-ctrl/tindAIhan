//
//  Theme.swift
//  TindAIhan
//

import SwiftUI

/// Design system tokens extracted directly from Figma wireframes
enum TindAITheme {
    // Backgrounds
    static let cream = Color(red: 250/255, green: 247/255, blue: 238/255) // #FAF7EE
    static let darkNavy = Color(red: 26/255, green: 37/255, blue: 54/255) // #1A2536
    static let cardNavy = Color(red: 30/255, green: 43/255, blue: 61/255) // #1E2B3D
    static let cardNavyLight = Color(red: 37/255, green: 50/255, blue: 69/255) // #253245
    static let cardBackground = Color.white

    // Brand Colors
    static let brandRed = Color(red: 224/255, green: 49/255, blue: 49/255) // #E03131
    static let brandRedPressed = Color(red: 195/255, green: 35/255, blue: 35/255)
    static let accentYellow = Color(red: 251/255, green: 191/255, blue: 36/255) // #FBBF24
    static let accentYellowDark = Color(red: 245/255, green: 158/255, blue: 11/255) // #F59E0B
    static let tealButton = Color(red: 13/255, green: 148/255, blue: 136/255) // #0D9488

    // Status Badges
    static let badgeGreenBg = Color(red: 209/255, green: 250/255, blue: 229/255) // #D1FAE5
    static let badgeGreenText = Color(red: 6/255, green: 95/255, blue: 70/255) // #065F46
    static let badgeRedBg = Color(red: 254/255, green: 226/255, blue: 226/255)
    static let badgeRedText = Color(red: 185/255, green: 28/255, blue: 28/255)

    // Avatar Palettes
    static let avatarYellow = Color(red: 252/255, green: 211/255, blue: 77/255) // #FCD34D
    static let avatarTeal = Color(red: 167/255, green: 243/255, blue: 208/255) // #A7F3D0
    static let avatarPink = Color(red: 251/255, green: 207/255, blue: 232/255) // #FBCFE8
    static let avatarOrange = Color(red: 254/255, green: 215/255, blue: 170/255) // #FED7AA
    static let avatarBlue = Color(red: 191/255, green: 219/255, blue: 254/255)

    // Text Colors
    static let textPrimary = Color(red: 29/255, green: 43/255, blue: 58/255) // #1D2B3A
    static let textSecondary = Color(red: 100/255, green: 116/255, blue: 139/255) // #64748B
    static let textMuted = Color(red: 148/255, green: 163/255, blue: 184/255)

    static func avatarColor(for name: String) -> Color {
        let colors = [avatarYellow, avatarTeal, avatarPink, avatarOrange, avatarBlue]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
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
