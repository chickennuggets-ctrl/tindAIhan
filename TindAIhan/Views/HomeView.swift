//
//  HomeView.swift
//  TindAIhan
//

import SwiftUI
import SwiftData

/// Home screen matching wireframe 1 (Listahan)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LedgerEntry.createdAt, order: .reverse) private var allEntries: [LedgerEntry]

    @State private var isShowingSettings = false
    @State private var isShowingOnboarding = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedCustomer: String? = nil
    @State private var expandedGroupId: UUID? = nil

    // Compute stats
    private var unpaidEntries: [LedgerEntry] {
        allEntries.filter { !$0.isPaid }
    }

    private var totalUtang: Double {
        unpaidEntries.reduce(0) { $0 + $1.total }
    }

    private var formattedTotalUtang: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numStr = formatter.string(from: NSNumber(value: totalUtang)) ?? String(format: "%.2f", totalUtang)
        return "₱\(numStr)"
    }

    private var uniqueUnpaidCustomersCount: Int {
        Set(unpaidEntries.map(\.customer)).count
    }

    private var overdueCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let overdueSuki = Set(unpaidEntries.filter { $0.dueDate <= oneWeekAgo }.map(\.customer))
        return overdueSuki.count
    }

    // Group entries by transaction or customer for the list
    struct TransactionGroup: Identifiable {
        let id: UUID
        let customer: String
        let items: [LedgerEntry]
        let createdAt: Date
        let isPaid: Bool

        var total: Double {
            items.reduce(0) { $0 + $1.total }
        }

        var formattedTotal: String {
            String(format: "₱%.2f", total)
        }

        var itemsSummary: String {
            items.map { "\($0.quantity) \($0.item)" }.joined(separator: ", ")
        }

        var relativeTime: String {
            guard let date = items.first?.createdAt else { return "kanina" }
            let cal = Calendar.current
            if cal.isDateInToday(date) {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter.string(from: date).lowercased()
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                return formatter.string(from: date)
            }
        }
    }

    private var groupedTransactions: [TransactionGroup] {
        let filtered = allEntries.filter { entry in
            guard entry.quantity > 0 else { return false }
            if searchText.isEmpty { return true }
            return entry.customer.localizedCaseInsensitiveContains(searchText) ||
                   entry.item.localizedCaseInsensitiveContains(searchText)
        }

        // Group by transactionId
        let grouped = Dictionary(grouping: filtered) { $0.transactionId }
        let allGroups = grouped.map { id, entries in
            let sorted = entries.sorted { $0.createdAt > $1.createdAt }
            let first = sorted.first!
            return TransactionGroup(
                id: id,
                customer: first.customer,
                items: sorted,
                createdAt: first.createdAt,
                isPaid: entries.allSatisfy(\.isPaid)
            )
        }.sorted { $0.createdAt > $1.createdAt }

        // When not searching, show latest transaction per customer matching Figma Image 2
        if searchText.isEmpty {
            var seen = Set<String>()
            var distinct: [TransactionGroup] = []
            for g in allGroups {
                if !seen.contains(g.customer) {
                    seen.insert(g.customer)
                    distinct.append(g)
                }
            }
            return distinct
        }
        return allGroups
    }

    var body: some View {
        ZStack {
            TindAITheme.cream
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Header Branding
                    TindAIhanHeader(
                        onSettingsTapped: {
                            isShowingSettings = true
                        },
                        onSpeakTapped: {
                            speakHomeSummary()
                        }
                    )
                    .sheet(isPresented: $isShowingSettings) {
                        DemoSettingsSheet(
                            onResetData: { resetToFigmaDemoData() },
                            onRestartOnboarding: { isShowingOnboarding = true }
                        )
                    }
                    .fullScreenCover(isPresented: $isShowingOnboarding) {
                        OnboardingView(isCompleted: Binding(
                            get: { !isShowingOnboarding },
                            set: { if $0 { isShowingOnboarding = false } }
                        ))
                    }

                    // 2. Dark Navy Hero Card matching Figma Image 2
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Total amount of utang today")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))

                        Text(formattedTotalUtang)
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        HStack(spacing: 10) {
                            // Amber Suki Pill
                            Text("\(uniqueUnpaidCustomersCount) suki may utang")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(TindAITheme.accentYellow, in: Capsule())

                            // Overdue Pill
                            Text("\(overdueCount) lampas 1 linggo")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(TindAITheme.cardNavyLight, in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(TindAITheme.darkNavy, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: TindAITheme.darkNavy.opacity(0.12), radius: 14, y: 6)
                    .padding(.horizontal, 20)

                    // 3. Section Header: "Listahan" and "Hanapin"
                    HStack {
                        Text("Listahan")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(TindAITheme.textPrimary)

                        Spacer()

                        Button {
                            Haptics.light()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isSearching.toggle()
                                if !isSearching { searchText = "" }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                                    .font(.system(size: 14, weight: .bold))
                                Text(isSearching ? "Isara" : "Hanapin")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(TindAITheme.brandRed)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // Animated Search Bar
                    if isSearching {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(TindAITheme.textSecondary)
                            TextField("Maghanap ng suki o paninda…", text: $searchText)
                                .font(.system(size: 15, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 4. Transaction Rows matching Wireframe 1
                    VStack(spacing: 0) {
                        if groupedTransactions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .font(.system(size: 40))
                                    .foregroundStyle(TindAITheme.textSecondary.opacity(0.5))
                                Text("Walang laman ang listahan.")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(TindAITheme.textSecondary)
                                Text("Pindutin ang pulang mic button sa ibaba para magsalita ng utang.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(TindAITheme.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)
                        } else {
                            ForEach(Array(groupedTransactions.enumerated()), id: \.element.id) { index, group in
                                let isExpanded = expandedGroupId == group.id

                                VStack(spacing: 0) {
                                    Button {
                                        Haptics.light()
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            if expandedGroupId == group.id {
                                                expandedGroupId = nil
                                            } else {
                                                expandedGroupId = group.id
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 14) {
                                            // Customer Avatar
                                            SukiAvatar(name: group.customer, size: 48)

                                            // Customer Name & Items
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack(spacing: 6) {
                                                    Text(group.customer)
                                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                                        .foregroundStyle(TindAITheme.textPrimary)

                                                    Image(systemName: "chevron.down")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundStyle(TindAITheme.textSecondary)
                                                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                                }

                                                Text("\(group.itemsSummary) · \(group.relativeTime)")
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                                    .foregroundStyle(TindAITheme.textSecondary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            // Total Price
                                            VStack(alignment: .trailing, spacing: 3) {
                                                Text(group.formattedTotal)
                                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                                                    .foregroundStyle(group.isPaid ? Color.gray : TindAITheme.textPrimary)

                                                if group.isPaid {
                                                    Text("Bayad na")
                                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                                        .foregroundStyle(Color(red: 16/255, green: 185/255, blue: 129/255))
                                                }
                                            }
                                        }
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 20)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if isExpanded {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Divider().padding(.horizontal, 20)

                                            Text("Mga paninda:")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundStyle(TindAITheme.textSecondary)
                                                .padding(.horizontal, 20)

                                            ForEach(group.items) { item in
                                                HStack {
                                                    Text("• \(item.quantity)x \(item.item.capitalized)")
                                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                                        .foregroundStyle(TindAITheme.textPrimary)
                                                    Spacer()
                                                    Text(item.formattedTotal)
                                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                                        .foregroundStyle(TindAITheme.textSecondary)
                                                }
                                                .padding(.horizontal, 20)
                                            }

                                            HStack(spacing: 8) {
                                                // TTS Audio Button
                                                Button {
                                                    Haptics.light()
                                                    speakGroup(group)
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "speaker.wave.2.fill")
                                                        Text("Pakinggan")
                                                    }
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundStyle(TindAITheme.brandRed)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(TindAITheme.brandRed.opacity(0.08), in: Capsule())
                                                }

                                                // Full history details
                                                Button {
                                                    Haptics.light()
                                                    selectedCustomer = group.customer
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "list.bullet")
                                                        Text("Kasaysayan")
                                                    }
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundStyle(TindAITheme.textPrimary)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.gray.opacity(0.1), in: Capsule())
                                                }

                                                Spacer()

                                                // Mark paid directly
                                                Button {
                                                    Haptics.success()
                                                    markGroupPaid(group)
                                                } label: {
                                                    Text(group.isPaid ? "Bayad na" : "Bayaran")
                                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                                        .foregroundStyle(group.isPaid ? Color.green : TindAITheme.tealButton)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background((group.isPaid ? Color.green : TindAITheme.tealButton).opacity(0.12), in: Capsule())
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.bottom, 12)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                if index < groupedTransactions.count - 1 {
                                    Divider()
                                        .padding(.leading, 82)
                                        .padding(.trailing, 20)
                                }
                            }
                        }
                    }
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)
                    .padding(.horizontal, 20)

                    // Bottom padding to avoid floating mic overlap
                    Spacer()
                        .frame(height: 90)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(item: Binding(
            get: { selectedCustomer.map { CustomerDetailSheetItem(name: $0) } },
            set: { selectedCustomer = $0?.name }
        )) { item in
            CustomerDetailView(customerName: item.name)
        }
        .onAppear {
            if allEntries.contains(where: { $0.customer == "Kurt Paul" }) || overdueCount < 3 {
                resetToFigmaDemoData()
            }
        }
    }

    private func resetToFigmaDemoData() {
        for entry in allEntries {
            modelContext.delete(entry)
        }
        for sample in LedgerEntry.previewSamples {
            modelContext.insert(sample)
        }
        try? modelContext.save()
        Haptics.success()
    }

    private func speakHomeSummary() {
        let total = Int(totalUtang)
        let msg = "Magandang araw! Kabuuang utang para sa araw na ito: \(total) pesos mula sa \(uniqueUnpaidCustomersCount) na suki. May \(overdueCount) na lampas na ng isang linggo."
        TextToSpeechService.shared.speak(msg)
    }

    private func speakGroup(_ group: TransactionGroup) {
        let total = Int(group.total)
        let items = group.itemsSummary
        let msg = "\(group.customer): inutang ay \(items). Kabuuang halaga: \(total) pesos."
        TextToSpeechService.shared.speak(msg)
    }

    private func markGroupPaid(_ group: TransactionGroup) {
        withAnimation {
            for entry in group.items {
                entry.isPaid = true
                entry.paidAt = .now
            }
            try? modelContext.save()
            TextToSpeechService.shared.speakPaymentReceived(customer: group.customer, amount: group.total)
        }
    }
}

// MARK: - Hackathon Demo & Settings Sheet
struct DemoSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onResetData: () -> Void
    var onRestartOnboarding: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Hackathon Demo Controls") {
                    Button {
                        onResetData()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(TindAITheme.brandRed)
                            Text("I-load ang Figma Demo Dataset (₱6,767.67)")
                                .foregroundStyle(TindAITheme.textPrimary)
                        }
                    }

                    Button {
                        dismiss()
                        onRestartOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(TindAITheme.accentYellowDark)
                            Text("Ulitin ang Onboarding Setup Flow")
                                .foregroundStyle(TindAITheme.textPrimary)
                        }
                    }
                }

                Section("100% Local AI Engine Status") {
                    HStack {
                        Text("Speech-to-Text")
                        Spacer()
                        Text("Whisper on-device")
                            .foregroundStyle(Color(red: 27/255, green: 153/255, blue: 139/255))
                            .bold()
                    }
                    HStack {
                        Text("Language Parser")
                        Spacer()
                        Text("Local LLM / Offline NL Engine")
                            .foregroundStyle(TindAITheme.brandRed)
                            .bold()
                    }
                    HStack {
                        Text("Network Dependency")
                        Spacer()
                        Text("0% (Airplane Mode Ready)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Mga Setting at Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Isara") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct CustomerDetailSheetItem: Identifiable {
    var id: String { name }
    let name: String
}

// MARK: - Customer Ledger Detail Sheet
struct CustomerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let customerName: String

    @Query private var allEntries: [LedgerEntry]

    private var customerEntries: [LedgerEntry] {
        allEntries.filter { $0.customer == customerName && $0.quantity > 0 }
    }

    private var totalCustomerUtang: Double {
        customerEntries.filter { !$0.isPaid }.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TindAITheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Customer Header Card
                        HStack(spacing: 16) {
                            SukiAvatar(name: customerName, size: 60)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(customerName)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(TindAITheme.textPrimary)
                                Text("Utang ngayon: \(String(format: "₱%.2f", totalCustomerUtang))")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(TindAITheme.brandRed)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))

                        // Items Breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kasaysayan ng Utang")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)

                            ForEach(customerEntries) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(entry.quantity)x \(entry.item.capitalized)")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Text(entry.formattedDate)
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(TindAITheme.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(entry.formattedTotal)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Button(entry.isPaid ? "Nabayaran" : "Bayaran") {
                                            Haptics.success()
                                            withAnimation {
                                                entry.isPaid.toggle()
                                                entry.paidAt = entry.isPaid ? .now : nil
                                                try? modelContext.save()
                                            }
                                        }
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(entry.isPaid ? .green : TindAITheme.brandRed)
                                    }
                                }
                                .padding(.vertical, 8)
                                Divider()
                            }
                        }
                        .padding()
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .padding()
                }
            }
            .navigationTitle(customerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Isara") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: LedgerEntry.self, inMemory: true)
}
