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

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedCustomer: String? = nil

    // Compute stats
    private var unpaidEntries: [LedgerEntry] {
        allEntries.filter { !$0.isPaid }
    }

    private var totalUtang: Double {
        unpaidEntries.reduce(0) { $0 + $1.total }
    }

    private var formattedTotalUtang: String {
        String(format: "₱%.2f", totalUtang)
    }

    private var uniqueUnpaidCustomersCount: Int {
        Set(unpaidEntries.map(\.customer)).count
    }

    private var overdueCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return unpaidEntries.filter { $0.dueDate < today }.count
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
            items.first?.relativeTimeString ?? "kanina"
        }
    }

    private var groupedTransactions: [TransactionGroup] {
        let filtered = allEntries.filter { entry in
            if searchText.isEmpty { return true }
            return entry.customer.localizedCaseInsensitiveContains(searchText) ||
                   entry.item.localizedCaseInsensitiveContains(searchText)
        }

        // Group by transactionId
        let grouped = Dictionary(grouping: filtered) { $0.transactionId }
        return grouped.map { id, entries in
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
    }

    var body: some View {
        ZStack {
            TindAITheme.cream
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Header Branding
                    TindAIhanHeader()

                    // 2. Dark Navy Hero Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Kabuuang utang ngayon")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))

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
                                Button {
                                    Haptics.light()
                                    selectedCustomer = group.customer
                                } label: {
                                    HStack(spacing: 14) {
                                        // Customer Avatar
                                        SukiAvatar(name: group.customer, size: 48)

                                        // Customer Name & Items
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(group.customer)
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundStyle(TindAITheme.textPrimary)

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
                                .buttonStyle(.pressable(scale: 0.98))

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
        allEntries.filter { $0.customer == customerName }
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
