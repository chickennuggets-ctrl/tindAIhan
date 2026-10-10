//
//  TindahanRoofAwning.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Faithful recreation of the iconic Philippine sari-sari store scalloped striped awning
//  and Tindahan "A" illustration from Figma Onboarding wireframe.
//

import SwiftUI

/// Sari-sari store awning with alternating red and cream vertical stripes and scalloped bottom edges
struct TindahanRoofAwning: View {
    var height: CGFloat = 68
    var scallopCount: Int = 11

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let stripeWidth = totalWidth / CGFloat(scallopCount)

            ZStack(alignment: .top) {
                // Alternating stripes
                HStack(spacing: 0) {
                    ForEach(0..<scallopCount, id: \.self) { index in
                        let isRed = index % 2 == 0
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(isRed ? TindAITheme.brandRed : TindAITheme.cream)
                                .frame(width: stripeWidth, height: height - 16)

                            // Scalloped semicircular flap at the bottom
                            Circle()
                                .fill(isRed ? TindAITheme.brandRed : TindAITheme.cream)
                                .frame(width: stripeWidth, height: stripeWidth)
                                .offset(y: -stripeWidth / 3)
                        }
                    }
                }
            }
            .clipped()
        }
        .frame(height: height)
        .ignoresSafeArea(edges: .top)
    }
}

/// The Tindahan "A" house illustration with electrical pole and star sparkle from Figma
struct TindahanIllustration: View {
    var size: CGFloat = 260
    var showGroundOval: Bool = false
    var showLightBeam: Bool = true
    @State private var isSparkling = false
    @State private var beamOpacity: Double = 0.65

    var body: some View {
        ZStack {
            if showLightBeam {
                // Light ground beam shadow with gentle breathing animation
                Path { path in
                    path.move(to: CGPoint(x: 20, y: size * 0.95))
                    path.addLine(to: CGPoint(x: size * 0.98, y: size * 0.95))
                    path.addLine(to: CGPoint(x: size * 0.85, y: size * 0.35))
                    path.addLine(to: CGPoint(x: size * 0.35, y: size * 0.35))
                    path.closeSubpath()
                }
                .fill(Color(red: 250/255, green: 242/255, blue: 226/255))
                .opacity(beamOpacity)
            }

            if showGroundOval {
                Ellipse()
                    .fill(TindAITheme.accentYellow)
                    .frame(width: size * 0.92, height: 20)
                    .offset(y: (size * 0.9) / 2 - 8)
            }

            // Main "A" Frame Sari-Sari Store
            HStack(alignment: .bottom, spacing: 0) {
                ZStack(alignment: .bottom) {
                    // Dark navy store base / counter
                    VStack(spacing: 6) {
                        Spacer()

                        // Counter with product boxes
                        HStack(spacing: 8) {
                            Circle().fill(TindAITheme.brandRed).frame(width: 14, height: 14)
                            Circle().fill(TindAITheme.accentYellow).frame(width: 14, height: 14)
                            Circle().fill(TindAITheme.tealButton).frame(width: 14, height: 14)
                        }

                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(TindAITheme.brandRed)
                                .frame(width: 22, height: 10)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(TindAITheme.tealButton)
                                .frame(width: 22, height: 10)
                        }
                    }
                    .frame(width: 110, height: 80)
                    .padding(.bottom, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(TindAITheme.darkNavy)
                    )

                    // Big Red "A" Roof
                    ZStack {
                        // Outer "A" triangle shape
                        RoofTriangleShape()
                            .stroke(TindAITheme.brandRed, style: StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round))
                            .frame(width: 110, height: 130)

                        // White dots along the roof line
                        RoofTriangleShape()
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 8]))
                            .frame(width: 110, height: 130)

                        // Scalloped mini awning under the roof peak
                        HStack(spacing: 3) {
                            ForEach(0..<5) { idx in
                                Circle()
                                    .fill(idx % 2 == 0 ? TindAITheme.brandRed : TindAITheme.cream)
                                    .frame(width: 14, height: 14)
                            }
                        }
                        .offset(y: 12)
                    }
                    .offset(y: -40)
                }

                // Electrical Utility Pole and Power Lines
                ZStack(alignment: .bottomLeading) {
                    // Dark navy pole
                    Rectangle()
                        .fill(TindAITheme.darkNavy)
                        .frame(width: 14, height: 130)
                        .offset(x: 20)

                    // Cross arms
                    Rectangle()
                        .fill(TindAITheme.darkNavy)
                        .frame(width: 44, height: 10)
                        .offset(x: 5, y: -90)

                    // Diagonal power cables
                    Path { path in
                        path.move(to: CGPoint(x: 48, y: 35))
                        path.addQuadCurve(to: CGPoint(x: 95, y: 48), control: CGPoint(x: 70, y: 55))
                    }
                    .stroke(TindAITheme.darkNavy, lineWidth: 3.5)

                    // Four-point sparkle star with pulsing scale and glow
                    FourPointStar()
                        .fill(TindAITheme.brandRed)
                        .frame(width: 24, height: 24)
                        .scaleEffect(isSparkling ? 1.25 : 0.85)
                        .rotationEffect(.degrees(isSparkling ? 15 : -15))
                        .shadow(color: TindAITheme.brandRed.opacity(isSparkling ? 0.7 : 0.2), radius: isSparkling ? 8 : 2)
                        .offset(x: 15, y: -130)
                }
                .frame(width: 80, height: 160)
            }
        }
        .frame(width: size, height: size * 0.9)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                isSparkling = true
                beamOpacity = 1.0
            }
        }
    }
}

private struct RoofTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + 12))
        path.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.maxY))
        return path
    }
}

private struct FourPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let w = rect.width / 2
        let h = rect.height / 2
        let inset = w * 0.3

        path.move(to: CGPoint(x: cx, y: cy - h))
        path.addQuadCurve(to: CGPoint(x: cx + w, y: cy), control: CGPoint(x: cx + inset, y: cy - inset))
        path.addQuadCurve(to: CGPoint(x: cx, y: cy + h), control: CGPoint(x: cx + inset, y: cy + inset))
        path.addQuadCurve(to: CGPoint(x: cx - w, y: cy), control: CGPoint(x: cx - inset, y: cy + inset))
        path.addQuadCurve(to: CGPoint(x: cx, y: cy - h), control: CGPoint(x: cx - inset, y: cy - inset))
        return path
    }
}

#Preview {
    VStack {
        TindahanRoofAwning()
        Spacer()
        TindahanIllustration()
        Spacer()
    }
    .background(TindAITheme.cream)
}
