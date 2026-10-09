//
//  DashboardView.swift
//  TindAIhan
//

import SwiftUI
import SwiftData

/// Main root view managing tabs, the floating microphone action button, and AI sheets
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [LedgerEntry]

    @State private var selectedTab: TabItem = .listahan
    @State private var isShowingVoiceModal = false
    @State private var isShowingConfirmModal = false
    @State private var pendingParsedUtang: ParsedUtang? = nil
    @State private var isShowingManualType = false
    @State private var typedUtangText = ""

    // AI & Speech Services
    @State private var recorder = AudioRecorder()
    @State private var stt = TranscriptionService()
    @State private var llm = LLMParser()

    enum TabItem: String, CaseIterable {
        case listahan = "Listahan"
        case singil = "Singil"
        case buod = "Buod"
        case suki = "Suki"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .listahan:
                    HomeView()
                case .singil:
                    SingilView()
                case .buod:
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
                recorder: recorder,
                stt: stt,
                llm: llm
            ) { parsed in
                self.pendingParsedUtang = parsed
                // Smooth transition to confirmation sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isShowingConfirmModal = true
                }
            }
        }
        .sheet(isPresented: $isShowingConfirmModal) {
            if let pending = pendingParsedUtang {
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
        }
        .sheet(isPresented: $isShowingManualType) {
            manualTypeSheet
        }
        .onAppear {
            seedInitialDataIfNeeded()
        }
    }

    // MARK: - Custom Floating Bottom Bar
    private var customBottomBar: some View {
        ZStack(alignment: .top) {
            // White Background Bar with subtle shadow
            HStack(spacing: 0) {
                // Left Tabs: Listahan, Singil
                tabButton(for: .listahan)
                tabButton(for: .singil)

                // Center Spacer for Floating Mic Button
                Spacer()
                    .frame(width: 72)

                // Right Tabs: Buod, Suki
                tabButton(for: .buod)
                tabButton(for: .suki)
            }
            .frame(height: 64)
            .padding(.horizontal, 10)
            .background(
                Color.white
                    .shadow(color: Color.black.opacity(0.06), radius: 10, y: -4)
                    .ignoresSafeArea(edges: .bottom)
            )

            // Center Elevated Floating Red Mic Button
            Button {
                Haptics.heavy()
                isShowingVoiceModal = true
            } label: {
                ZStack {
                    // Outer subtle halo ring
                    Circle()
                        .fill(TindAITheme.cream)
                        .frame(width: 72, height: 72)

                    // Red Mic Circle
                    Circle()
                        .fill(TindAITheme.brandRed)
                        .frame(width: 62, height: 62)
                        .shadow(color: TindAITheme.brandRed.opacity(0.4), radius: 10, y: 4)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.pressable(scale: 0.92))
            .offset(y: -22) // Floats above the tab bar notch
        }
    }

    private func tabButton(for tab: TabItem) -> some View {
        Button {
            Haptics.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Text(tab.rawValue)
                    .font(.system(size: 15, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                    .foregroundStyle(selectedTab == tab ? TindAITheme.brandRed : TindAITheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.pressable(scale: 0.95))
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
        if entries.isEmpty {
            for sample in LedgerEntry.previewSamples {
                modelContext.insert(sample)
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: LedgerEntry.self, inMemory: true)
}
