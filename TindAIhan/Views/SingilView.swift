//
//  SingilView.swift
//  TindAIhan
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

    private var unpaidEntries: [LedgerEntry] {
        allEntries.filter { !$0.isPaid }
    }

    private var totalSingilin: Double {
        unpaidEntries.reduce(0) { $0 + $1.total }
    }

    private var todaySubtitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tl_PH")
        formatter.dateFormat = "EEEE, MMM d"
        let datePart = formatter.string(from: .now).capitalized
        return "\(datePart) · \(String(format: "₱%.2f", totalSingilin)) ang dapat singilin"
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
            String(format: "₱%.2f", totalAmount)
        }

        var dueDateDescription: String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tl_PH")
            formatter.dateFormat = "MMM d"
            let str = formatter.string(from: dueDate)

            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)
            let dueDay = cal.startOfDay(for: dueDate)

            if dueDay < today {
                let diff = cal.dateComponents([.day], from: dueDay, to: today).day ?? 1
                return "\(str) · \(diff) araw na lampas"
            } else if cal.isDateInToday(dueDate) {
                return "\(str) · Ngayon"
            } else {
                let diff = cal.dateComponents([.day], from: today, to: dueDay).day ?? 1
                return "\(str) · \(diff) na araw"
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
        return collections.filter { Calendar.current.startOfDay(for: $0.dueDate) < today }
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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Singil")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(TindAITheme.textPrimary)

                        Text(todaySubtitle)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(TindAITheme.textSecondary)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                    // 1. LAMPAS NA (Overdue)
                    if !overdueCollections.isEmpty {
                        collectionSection(
                            title: "LAMPAS NA",
                            titleColor: TindAITheme.brandRed,
                            borderColor: TindAITheme.brandRed,
                            items: overdueCollections
                        )
                    }

                    // 2. NGAYON (Due Today)
                    if !todayCollections.isEmpty {
                        collectionSection(
                            title: "NGAYON",
                            titleColor: TindAITheme.accentYellowDark,
                            borderColor: TindAITheme.accentYellow,
                            items: todayCollections
                        )
                    }

                    // 3. KINSENAS / DARATING (Upcoming)
                    if !upcomingCollections.isEmpty {
                        collectionSection(
                            title: "KINSENAS · DARATING",
                            titleColor: TindAITheme.textSecondary,
                            borderColor: Color.gray.opacity(0.2),
                            items: upcomingCollections
                        )
                    }

                    if collections.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color(red: 16/255, green: 185/255, blue: 129/255))
                            Text("Walang dapat singilin!")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)
                            Text("Lahat ng suki ay bayad na o wala pang utang.")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }

                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .sheet(isPresented: $showingSMSAlert) {
            smsComposerSheet
        }
    }

    private func collectionSection(
        title: String,
        titleColor: Color,
        borderColor: Color,
        items: [SukiCollection]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(titleColor)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.customer)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(TindAITheme.textPrimary)

                                Text(item.dueDateDescription)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(titleColor)
                            }

                            Spacer()

                            Text(item.formattedAmount)
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)
                        }

                        // Buttons: I-text and Bayad na
                        HStack(spacing: 12) {
                            Button {
                                openSMSReminder(for: item)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 13))
                                    Text("I-text")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(TindAITheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.pressable(scale: 0.95))

                            Button {
                                markPaid(for: item)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Bayad na")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
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
                    .font(.system(size: 15, design: .rounded))
                    .padding(10)
                    .background(Color(red: 241/255, green: 245/255, blue: 249/255), in: RoundedRectangle(cornerRadius: 12))
                    .frame(height: 140)

                Button {
                    Haptics.success()
                    #if os(iOS)
                    UIPasteboard.general.string = smsMessageText
                    #endif
                    showingSMSAlert = false
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Kopyahin ang Mensahe")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(TindAITheme.brandRed, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.pressable(scale: 0.95))

                Spacer()
            }
            .padding(20)
            .navigationTitle("I-text ang Suki")
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
