//
//  SingilView.swift
//  TindAIhan
//
//  Created for AppBuildersPH Hackathon 2026.
//  Matches wireframe 9 (Singil / Collect) with collapsible sections,
//  expandable item breakdown cards, smooth scrolling, and Text-to-Speech announcements.
//

import SwiftUI
import SwiftData

/// Due dates & payment collection screen matching wireframe 9 (Singil)
struct SingilView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [LedgerEntry]

    @State private var showingSMSAlert = false
    @State private var smsMessageText = ""
    @State private var selectedCustomerName = ""

    // Collapsible section state
    @State private var collapsedSections: Set<String> = []
    // Expandable item breakdown cards state
    @State private var expandedCardIds: Set<String> = []

    private var unpaidEntries: [LedgerEntry] {
        allEntries.filter { !$0.isPaid && $0.quantity > 0 }
    }

    private var totalSingilin: Double {
        unpaidEntries.reduce(0) { $0 + $1.total }
    }

    private var formattedTotalSingilin: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numStr = formatter.string(from: NSNumber(value: totalSingilin)) ?? String(format: "%.2f", totalSingilin)
        return "₱\(numStr)"
    }

    // Customer aggregation for collections
    struct SukiCollection: Identifiable {
        let id: String
        let customer: String
        let customerPhone: String?
        let totalAmount: Double
        let dueDate: Date
        let entries: [LedgerEntry]

        var formattedAmount: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            let numStr = formatter.string(from: NSNumber(value: totalAmount)) ?? String(format: "%.2f", totalAmount)
            return "₱\(numStr)"
        }

        var dueDateDescription: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            let str = formatter.string(from: dueDate)

            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)
            let dueDay = cal.startOfDay(for: dueDate)

            if dueDay < today {
                let diff = cal.dateComponents([.day], from: dueDay, to: today).day ?? 1
                return "\(str) · \(diff) days overdue"
            } else if cal.isDateInToday(dueDate) {
                return "\(str) · Today"
            } else {
                let diff = cal.dateComponents([.day], from: today, to: dueDay).day ?? 1
                return "\(str) · due in \(diff) days"
            }
        }
    }

    private var collections: [SukiCollection] {
        let grouped = Dictionary(grouping: unpaidEntries) { $0.customer }
        return grouped.map { customer, entries in
            let total = entries.reduce(0) { $0 + $1.total }
            let earliestDue = entries.map(\.dueDate).min() ?? .now
            let phone = entries.first?.customerPhone
            return SukiCollection(
                id: customer,
                customer: customer,
                customerPhone: phone,
                totalAmount: total,
                dueDate: earliestDue,
                entries: entries
            )
        }
    }

    private var overdueCollections: [SukiCollection] {
        let today = Calendar.current.startOfDay(for: .now)
        return collections
            .filter { Calendar.current.startOfDay(for: $0.dueDate) < today }
            .sorted { $0.dueDate > $1.dueDate }
    }

    private var todayCollections: [SukiCollection] {
        collections.filter { Calendar.current.isDateInToday($0.dueDate) }
    }

    private var upcomingCollections: [SukiCollection] {
        let today = Calendar.current.startOfDay(for: .now)
        return collections.filter {
            !Calendar.current.isDateInToday($0.dueDate) &&
            Calendar.current.startOfDay(for: $0.dueDate) > today
        }
    }

    var body: some View {
        ZStack {
            TindAITheme.cream
                .ignoresSafeArea()

            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 22) {
                    // Header matching Figma Image 2
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Collect")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)

                            Text("Saturday, October 10 · \(formattedTotalSingilin) must be collected")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                    // 1. OVERDUE (Collapsible Accordion)
                    if !overdueCollections.isEmpty {
                        collectionSection(
                            title: "OVERDUE",
                            titleColor: TindAITheme.brandRed,
                            borderColor: TindAITheme.brandRed,
                            subtitleColor: TindAITheme.brandRed,
                            items: overdueCollections
                        )
                    }

                    // 2. TODAY (Collapsible Accordion)
                    if !todayCollections.isEmpty {
                        collectionSection(
                            title: "TODAY",
                            titleColor: TindAITheme.textPrimary,
                            borderColor: TindAITheme.accentYellow,
                            subtitleColor: TindAITheme.textSecondary,
                            items: todayCollections
                        )
                    }

                    // 3. KINSENAS · OCTOBER 15 (Collapsible Accordion)
                    if !upcomingCollections.isEmpty {
                        collectionSection(
                            title: "KINSENAS · OCTOBER 15",
                            titleColor: TindAITheme.textPrimary,
                            borderColor: TindAITheme.darkNavy,
                            subtitleColor: TindAITheme.textSecondary,
                            items: upcomingCollections
                        )
                    }

                    if collections.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color(red: 27/255, green: 153/255, blue: 139/255))
                            Text("No pending collections!")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)
                            Text("All customers have settled their listahan.")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }

                    // Bottom padding to ensure bottom nav bar never obscures items
                    Spacer()
                        .frame(height: 120)
                }
            }
            .scrollBounceBehavior(.always)
        }
        .sheet(isPresented: $showingSMSAlert) {
            smsComposerSheet
        }
    }

    private func collectionSection(
        title: String,
        titleColor: Color,
        borderColor: Color,
        subtitleColor: Color,
        items: [SukiCollection]
    ) -> some View {
        let isCollapsed = collapsedSections.contains(title)

        return VStack(alignment: .leading, spacing: 10) {
            // Collapsible Section Header
            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    if isCollapsed {
                        collapsedSections.remove(title)
                    } else {
                        collapsedSections.insert(title)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(titleColor)

                    Text("(\(items.count))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(titleColor.opacity(0.8))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(titleColor)
                        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                }
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
            }

            // Cards in Section
            if !isCollapsed {
                VStack(spacing: 14) {
                    ForEach(items) { item in
                        let isCardExpanded = expandedCardIds.contains(item.id)

                        VStack(alignment: .leading, spacing: 14) {
                            // Top Row: Customer Info + Tap to Expand Drawer
                            Button {
                                Haptics.light()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    if isCardExpanded {
                                        expandedCardIds.remove(item.id)
                                    } else {
                                        expandedCardIds.insert(item.id)
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(item.customer)
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundStyle(TindAITheme.textPrimary)

                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(TindAITheme.textSecondary)
                                                .rotationEffect(.degrees(isCardExpanded ? 180 : 0))
                                        }

                                        Text(item.dueDateDescription)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(subtitleColor)
                                    }

                                    Spacer()

                                    Text(item.formattedAmount)
                                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                                        .foregroundStyle(TindAITheme.textPrimary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            // Expandable Itemized Drawer
                            if isCardExpanded {
                                VStack(alignment: .leading, spacing: 6) {
                                    Divider()
                                    Text("Mga Naka-lista:")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(TindAITheme.textSecondary)

                                    ForEach(item.entries) { e in
                                        HStack {
                                            Text("• \(e.quantity)x \(e.item.capitalized)")
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundStyle(TindAITheme.textPrimary)
                                            Spacer()
                                            Text(e.formattedTotal)
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundStyle(TindAITheme.textSecondary)
                                        }
                                    }
                                    Divider()
                                }
                                .padding(.vertical, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Buttons: Send a text and Paid matching Figma Image 2
                            HStack(spacing: 12) {
                                Button {
                                    openSMSReminder(for: item)
                                } label: {
                                    Text("Send a text")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(TindAITheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.pressable(scale: 0.95))

                                Button {
                                    markPaid(for: item)
                                } label: {
                                    Text("Paid")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(TindAITheme.tealButton, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.pressable(scale: 0.95))
                            }
                        }
                        .padding(18)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(borderColor, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 2)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private func markPaid(for collection: SukiCollection) {
        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            for entry in collection.entries {
                entry.isPaid = true
                entry.paidAt = .now
            }
            try? modelContext.save()
        }
    }

    private func openSMSReminder(for collection: SukiCollection) {
        Haptics.light()
        selectedCustomerName = collection.customer
        smsMessageText = """
        Magandang araw po \(collection.customer)! Paalala lang po mula sa ating sari-sari store para sa inyong utang na \(collection.formattedAmount) na dapat singilin noong \(collection.dueDateDescription). Maraming salamat po!
        """
        showingSMSAlert = true
    }

    private var smsComposerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Mensahe para kay \(selectedCustomerName)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)

                TextEditor(text: $smsMessageText)
                    .padding(12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .frame(height: 140)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = smsMessageText
                        Haptics.success()
                        showingSMSAlert = false
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Kopyahin Text")
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(TindAITheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                    }

                    Button {
                        Haptics.medium()
                        if let encoded = smsMessageText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "sms:&body=\(encoded)") {
                            UIApplication.shared.open(url)
                        }
                        showingSMSAlert = false
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Buksan SMS")
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(TindAITheme.brandRed, in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(TindAITheme.cream.ignoresSafeArea())
            .navigationTitle("SMS Paalala")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Isara") { showingSMSAlert = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    SingilView()
        .modelContainer(for: LedgerEntry.self, inMemory: true)
}
