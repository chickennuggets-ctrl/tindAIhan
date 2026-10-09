//
//  BuodView.swift
//  TindAIhan
//

import SwiftUI
import SwiftData

/// Summary & analytics screen matching wireframes 6, 7, and 8 (Buod)
struct BuodView: View {
    @Query private var allEntries: [LedgerEntry]

    @State private var selectedTab: BuodTab = .mgaSuki
    @State private var selectedFilter: SukiSortFilter = .name
    @State private var selectedMonth = Date.now

    enum BuodTab: String, CaseIterable {
        case mgaSuki = "Mga Suki"
        case buwan = "Buwan"
        case taon = "Taon"
    }

    enum SukiSortFilter: String, CaseIterable {
        case name = "Pangalan A–Z"
        case highest = "Pinakamalaki"
        case dueDate = "Petsa ng singil"
    }

    private var unpaidEntries: [LedgerEntry] {
        allEntries.filter { !$0.isPaid }
    }

    private var totalNatitira: Double {
        unpaidEntries.reduce(0) { $0 + $1.total }
    }

    private var totalInutang: Double {
        allEntries.reduce(0) { $0 + $1.total }
    }

    private var totalNabayaran: Double {
        allEntries.filter(\.isPaid).reduce(0) { $0 + $1.total }
    }

    var body: some View {
        ZStack {
            TindAITheme.cream
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Buod")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(TindAITheme.textPrimary)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    // 1. Top Segmented Tabs (Mga Suki | Buwan | Taon)
                    HStack(spacing: 0) {
                        ForEach(BuodTab.allCases, id: \.self) { tab in
                            Button {
                                Haptics.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab.rawValue)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(selectedTab == tab ? .white : TindAITheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        selectedTab == tab ? TindAITheme.darkNavy : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                            }
                        }
                    }
                    .padding(5)
                    .background(Color(red: 238/255, green: 232/255, blue: 216/255), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // Tab Content
                    switch selectedTab {
                    case .mgaSuki:
                        mgaSukiTabContent
                    case .buwan:
                        buwanTabContent
                    case .taon:
                        taonTabContent
                    }

                    Spacer()
                        .frame(height: 100)
                }
            }
        }
    }

    // MARK: - Screen 6: Mga Suki Tab Content
    private var mgaSukiTabContent: some View {
        VStack(spacing: 16) {
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SukiSortFilter.allCases, id: \.self) { filter in
                        Button {
                            Haptics.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(
                                    selectedFilter == filter ? TindAITheme.accentYellow : Color.white,
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(selectedFilter == filter ? 0 : 0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Dark Navy Summary Card
            VStack(alignment: .leading, spacing: 6) {
                Text("Natitirang utang")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))
                Text(String(format: "₱%.2f", totalNatitira))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(TindAITheme.darkNavy, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)

            // Suki List
            VStack(spacing: 0) {
                ForEach(sortedSukiList) { suki in
                    HStack(spacing: 14) {
                        SukiAvatar(name: suki.name, size: 46)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(suki.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)

                            Text("Singil \(suki.dueDateStr) · \(suki.itemCount) item")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "₱%.2f", suki.total))
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)

                            if suki.isOverdue {
                                Text("Lampas na")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(TindAITheme.brandRed, in: Capsule())
                            } else if suki.isDueToday {
                                Text("Ngayon")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(TindAITheme.textPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(TindAITheme.accentYellow, in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.leading, 74)
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Screen 7: Buwan Tab Content
    private var buwanTabContent: some View {
        VStack(spacing: 18) {
            // Month Navigator: < Oktubre 2026 >
            HStack {
                Button {
                    Haptics.light()
                    changeMonth(by: -1)
                } label: {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 42, height: 42)
                        .overlay(Image(systemName: "chevron.left").bold().foregroundStyle(TindAITheme.textPrimary))
                }

                Spacer()

                Text("Oktubre 2026")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)

                Spacer()

                Button {
                    Haptics.light()
                    changeMonth(by: 1)
                } label: {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 42, height: 42)
                        .overlay(Image(systemName: "chevron.right").bold().foregroundStyle(TindAITheme.textPrimary))
                }
            }
            .padding(.horizontal, 24)

            // 4 Grid Metric Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                // Inutang
                statCard(title: "Inutang", amount: String(format: "₱%.2f", max(2140, totalInutang)), isYellow: false)

                // Nabayaran
                statCard(title: "Nabayaran", amount: String(format: "₱%.2f", max(856, totalNabayaran)), isYellow: false)

                // Natitira (Amber Card)
                statCard(title: "Natitira", amount: String(format: "₱%.2f", max(1284, totalNatitira)), isYellow: true)

                // Item na nailista
                statCard(title: "Item na nailista", amount: "\(allEntries.count > 0 ? allEntries.count * 12 : 86) pcs", isYellow: false)
            }
            .padding(.horizontal, 20)

            // Filter Chips
            HStack(spacing: 10) {
                Button("Pangalan A–Z") {}
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(TindAITheme.accentYellow, in: Capsule())

                Button("Pinakamalaki") {}
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1))

                Spacer()
            }
            .padding(.horizontal, 20)

            // Monthly Suki List
            VStack(spacing: 0) {
                ForEach(sortedSukiList.prefix(4)) { suki in
                    HStack(spacing: 14) {
                        SukiAvatar(name: suki.name, size: 46)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(suki.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("\(suki.itemCount * 2) item · \(suki.itemsSnippet)")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }

                        Spacer()

                        Text(String(format: "₱%.2f", suki.total))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    Divider().padding(.leading, 74)
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)
        }
    }

    private func statCard(title: String, amount: String, isYellow: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isYellow ? TindAITheme.textPrimary.opacity(0.8) : TindAITheme.textSecondary)

            Text(amount)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(TindAITheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            isYellow ? TindAITheme.accentYellow : Color.white,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 2)
    }

    // MARK: - Screen 8: Taon Tab Content
    private var taonTabContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Hero Dark Card
            VStack(alignment: .leading, spacing: 14) {
                Text("Taunang recap 2026")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))

                Text("₱18,460.00")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("kabuuang inutang")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))

                HStack(spacing: 16) {
                    Text("Nabayaran ")
                        .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                    + Text("₱17,176")
                        .bold()
                        .foregroundStyle(TindAITheme.accentYellow)

                    Text("Natitira ")
                        .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                    + Text("₱1,284")
                        .bold()
                        .foregroundStyle(TindAITheme.accentYellow)
                }
                .font(.system(size: 14, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(TindAITheme.darkNavy, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)

            // Utang kada buwan Bar Chart
            VStack(alignment: .leading, spacing: 16) {
                Text("Utang kada buwan")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                    .padding(.horizontal, 20)

                // Chart Bars (Ene - Okt)
                HStack(alignment: .bottom, spacing: 8) {
                    let months = [
                        ("Ene", 48, false),
                        ("Peb", 62, false),
                        ("Mar", 56, false),
                        ("Abr", 78, false),
                        ("May", 72, false),
                        ("Hun", 92, false),
                        ("Hul", 85, false),
                        ("Ago", 104, false),
                        ("Set", 96, false),
                        ("Okt", 118, true) // Highlighted current month in red
                    ]

                    ForEach(months, id: \.0) { m, height, isRed in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isRed ? TindAITheme.brandRed : TindAITheme.accentYellow)
                                .frame(height: CGFloat(height))

                            Text(m)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }
                    }
                }
                .frame(height: 140, alignment: .bottom)
                .padding(.horizontal, 20)
            }

            // Pinakamaraming nailista
            VStack(alignment: .leading, spacing: 14) {
                Text("Pinakamaraming nailista")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)

                VStack(spacing: 0) {
                    topItemRow(name: "Itlog", stat: "214 pcs")
                    Divider()
                    topItemRow(name: "Sardinas", stat: "168 pcs")
                    Divider()
                    topItemRow(name: "Bigas", stat: "96 kg")
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 20)
        }
    }

    private func topItemRow(name: String, stat: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(TindAITheme.textPrimary)

            Spacer()

            Text(stat)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(TindAITheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func changeMonth(by delta: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: delta, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    // Helper Model for aggregated suki list
    struct SukiSummaryItem: Identifiable {
        let id: String
        let name: String
        let total: Double
        let itemCount: Int
        let dueDate: Date
        let isOverdue: Bool
        let isDueToday: Bool
        let itemsSnippet: String

        var dueDateStr: String {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: dueDate)
        }
    }

    private var sortedSukiList: [SukiSummaryItem] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        let grouped = Dictionary(grouping: unpaidEntries) { $0.customer }
        var list: [SukiSummaryItem] = grouped.map { name, entries in
            let total = entries.reduce(0) { $0 + $1.total }
            let earliestDue = entries.map(\.dueDate).min() ?? .now
            let isOver = cal.startOfDay(for: earliestDue) < today
            let isToday = cal.isDateInToday(earliestDue)
            let snippet = entries.map(\.item).joined(separator: ", ")

            return SukiSummaryItem(
                id: name,
                name: name,
                total: total,
                itemCount: entries.count,
                dueDate: earliestDue,
                isOverdue: isOver,
                isDueToday: isToday,
                itemsSnippet: snippet
            )
        }

        switch selectedFilter {
        case .name:
            list.sort { $0.name < $1.name }
        case .highest:
            list.sort { $0.total > $1.total }
        case .dueDate:
            list.sort { $0.dueDate < $1.dueDate }
        }

        return list
    }
}

#Preview {
    BuodView()
        .modelContainer(for: LedgerEntry.self, inMemory: true)
}
