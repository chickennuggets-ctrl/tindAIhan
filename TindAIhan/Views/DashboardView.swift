//
//  DashboardView.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Main root view managing tabs, the floating microphone action button (88x88pt),
//  onboarding flows (Screens 4 & 5), and AI modal transitions.
//

import SwiftUI
import SwiftData

/// Main root view managing tabs, the floating microphone action button, and AI sheets
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [LedgerEntry]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var selectedTab: TabItem = .list
    @State private var isShowingVoiceModal = false
    @State private var isShowingConfirmModal = false
    @State private var pendingParsedUtang: ParsedUtang? = nil
    @State private var isShowingManualType = false
    @State private var typedUtangText = ""

    // AI Parser Service
    @State private var llm = LLMParser()

    enum TabItem: String, CaseIterable {
        case list = "List"
        case collect = "Collect"
        case core = "Core"
        case suki = "Suki"
    }

    private var overdueCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return entries.filter { !$0.isPaid && $0.dueDate < today }.count
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(isCompleted: $hasCompletedOnboarding)
            } else {
                mainDashboardContent
            }
        }
        .onAppear {
            seedInitialDataIfNeeded()
        }
    }

    private var mainDashboardContent: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .list:
                    HomeView()
                case .collect:
                    SingilView()
                case .core:
                    BuodView()
                case .suki:
                    SukiDirectoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Floating Bottom Navigation Bar matching wireframes
            customBottomBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $isShowingVoiceModal) {
            VoiceRecordingView(
                isPresented: $isShowingVoiceModal,
                llm: llm
            ) { parsed in
                self.pendingParsedUtang = parsed
            }
        }
        .sheet(item: $pendingParsedUtang) { pending in
            ConfirmEntryView(
                parsed: pending,
                onSaveComplete: {
                    pendingParsedUtang = nil
                    Haptics.success()
                },
                onRerecord: {
                    pendingParsedUtang = nil
                    isShowingVoiceModal = true
                }
            )
        }
        .sheet(isPresented: $isShowingManualType) {
            manualTypeSheet
        }
    }

    // MARK: - Custom Floating Bottom Bar matching Figma
    private var customBottomBar: some View {
        ZStack(alignment: .top) {
            // White Background Bar with subtle shadow
            HStack(spacing: 0) {
                // Left Tabs: List, Collect
                tabButton(for: .list)
                tabButton(for: .collect)

                // Center Spacer for Floating Mic Button
                Spacer()
                    .frame(width: 80)

                // Right Tabs: Core, Suki
                tabButton(for: .core)
                tabButton(for: .suki)
            }
            .frame(height: 60)
            .padding(.horizontal, 6)
            .background(
                Color.white
                    .shadow(color: Color.black.opacity(0.06), radius: 10, y: -4)
                    .ignoresSafeArea(edges: .bottom)
            )

            // Center Elevated Floating Red Mic Button (88pt with cream border)
            Button {
                Haptics.heavy()
                isShowingVoiceModal = true
            } label: {
                ZStack {
                    // Outer 80x80 ring with cream border
                    Circle()
                        .fill(TindAITheme.cream)
                        .frame(width: 80, height: 80)

                    // Inner 68x68 Red Mic Circle
                    Circle()
                        .fill(TindAITheme.brandRed)
                        .frame(width: 68, height: 68)
                        .shadow(color: TindAITheme.brandRed.opacity(0.4), radius: 10, y: 5)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.pressable(scale: 0.92))
            .offset(y: -24) // Floats above the tab bar notch
        }
    }

    private func tabButton(for tab: TabItem) -> some View {
        Button {
            Haptics.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 3) {
                    Group {
                        if tab == .list {
                            ReceiptTabIcon(isSelected: selectedTab == tab)
                        } else {
                            Image(systemName: tabIcon(for: tab))
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? TindAITheme.brandRed : Color(hex: "#8B97A2"))
                        }
                    }
                    .frame(height: 22)

                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                        .foregroundStyle(selectedTab == tab ? TindAITheme.brandRed : Color(hex: "#8B97A2"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)

                // Red indicator dot for overdue debts on Collect tab
                if tab == .collect && overdueCount > 0 {
                    Circle()
                        .fill(TindAITheme.brandRed)
                        .frame(width: 7, height: 7)
                        .offset(x: -8, y: 4)
                }
            }
        }
        .buttonStyle(.pressable(scale: 0.95))
    }

    private func tabIcon(for tab: TabItem) -> String {
        switch tab {
        case .list: return "doc.plaintext"
        case .collect: return "creditcard"
        case .core: return "checkmark.square"
        case .suki: return "person.2"
        }
    }

    // MARK: - Manual Type Sheet (Fallback)
    private var manualTypeSheet: some View {
        NavigationStack {
            Form {
                Section("I-type ang utang") {
                    TextField("Hal. Utang ni Pedro, 2 itlog tsaka 1 bigas", text: $typedUtangText)
                }
            }
            .navigationTitle("Mano-manong Paglista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kanselahin") { isShowingManualType = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("I-parse") {
                        if !typedUtangText.isEmpty {
                            Task {
                                if let parsed = try? await llm.parse(typedUtangText) {
                                    await MainActor.run {
                                        isShowingManualType = false
                                        pendingParsedUtang = parsed
                                        isShowingConfirmModal = true
                                    }
                                }
                            }
                        }
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    // Seed mock items matching wireframes on first run so the UI matches Figma
    private func seedInitialDataIfNeeded() {
        if entries.isEmpty || entries.count < 7 {
            for entry in entries {
                modelContext.delete(entry)
            }
            for sample in LedgerEntry.previewSamples {
                modelContext.insert(sample)
            }
            try? modelContext.save()
        }
    }
}

/// Custom receipt icon with zigzag bottom matching Figma wireframe exactly
struct ReceiptTabIcon: View {
    var isSelected: Bool

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let color: Color = isSelected ? TindAITheme.brandRed : Color(hex: "#8B97A2")

            var path = Path()
            // Top left rounded corner
            path.move(to: CGPoint(x: 3, y: 3))
            path.addLine(to: CGPoint(x: w - 3, y: 3))
            path.addLine(to: CGPoint(x: w - 3, y: h - 3))

            // Zigzag bottom
            let teeth = 3
            let step = (w - 6) / CGFloat(teeth * 2)
            for i in 0..<(teeth * 2) {
                let x = (w - 3) - CGFloat(i + 1) * step
                let y = (i % 2 == 0) ? h - 7 : h - 3
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: 3, y: 3))
            path.closeSubpath()

            context.stroke(path, with: .color(color), lineWidth: 1.8)

            // Inner lines
            var line1 = Path()
            line1.move(to: CGPoint(x: 7, y: 8))
            line1.addLine(to: CGPoint(x: w - 7, y: 8))
            context.stroke(line1, with: .color(color), lineWidth: 1.8)

            var line2 = Path()
            line2.move(to: CGPoint(x: 7, y: 12))
            line2.addLine(to: CGPoint(x: w - 10, y: 12))
            context.stroke(line2, with: .color(color), lineWidth: 1.8)
        }
        .frame(width: 22, height: 22)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: LedgerEntry.self, inMemory: true)
}
