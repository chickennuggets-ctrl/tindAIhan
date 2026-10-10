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
        case mgaSuki = "Suki"
        case buwan = "Month"
        case taon = "Year"
    }

    enum SukiSortFilter: String, CaseIterable {
        case name = "Names A-Z"
        case highest = "Most Amount"
        case dueDate = "Date Collection"
    }

    private var unpaidEntries: [LedgerEntry] {
        allEntries.filter { !$0.isPaid }
    }

    private var totalNatitira: Double {
        unpaidEntries.reduce(0) { $0 + $1.total }
    }

    private var formattedNatitira: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numStr = formatter.string(from: NSNumber(value: totalNatitira)) ?? String(format: "%.2f", totalNatitira)
        return "₱\(numStr)"
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
                    // Title matching Figma Image 4
                    Text("Core")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(TindAITheme.textPrimary)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    // 1. Top Segmented Tabs (Suki | Month | Year)
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
            .scrollBounceBehavior(.always)
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
                Text("Remaining utang")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))
                Text(formattedNatitira)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
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

                            Text("Collect by \(suki.dueDateStr) · \(suki.itemCount) items")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(suki.formattedTotal)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)

                            if suki.isOverdue {
                                Text("Overdue")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(TindAITheme.brandRed, in: Capsule())
                            } else if suki.isDueToday {
                                Text("Today")
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
            // Month Navigator: < October 2026 >
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

                Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
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

            // 4 Grid Metric Cards matching Image 4
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                // Inutang
                statCard(title: "Inutang", amount: "₱2,140.00", isYellow: false)

                // Paid
                statCard(title: "Paid", amount: "₱856.00", isYellow: false)

                // Remaining (Amber Card)
                statCard(title: "Remaining", amount: "₱1,248.00", isYellow: true)

                // Listed Items
                statCard(title: "Listed Items", amount: "86 pcs", isYellow: false)
            }
            .padding(.horizontal, 20)

            // Filter Chips
            HStack(spacing: 10) {
                Button("Names A-Z") {}
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(TindAITheme.accentYellow, in: Capsule())

                Button("Most Amount") {}
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1))

                Spacer()
            }
            .padding(.horizontal, 20)

            // Monthly Suki List matching Image 4
            VStack(spacing: 0) {
                ForEach(sortedSukiList.prefix(3)) { suki in
                    HStack(spacing: 14) {
                        SukiAvatar(name: suki.name, size: 46)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(suki.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("\(suki.itemCount * 3) items · \(suki.itemsSnippet)")
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
            // Hero Dark Card matching Image 4
            VStack(alignment: .leading, spacing: 14) {
                Text("Yearly Recap 2026")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))

                Text("₱18,460.67")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("total utang")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))

                HStack(spacing: 16) {
                    Text("Paid ")
                        .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                    + Text("₱11,693")
                        .bold()
                        .foregroundStyle(TindAITheme.accentYellow)

                    Text("Remaining ")
                        .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                    + Text("₱6,767.67")
                        .bold()
                        .foregroundStyle(TindAITheme.accentYellow)
                }
                .font(.system(size: 14, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(TindAITheme.darkNavy, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)

            // Monthly Utang Bar Chart matching Image 4
            VStack(alignment: .leading, spacing: 16) {
                Text("Monthly Utang")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(TindAITheme.textPrimary)
                    .padding(.horizontal, 20)

                // Chart Bars (Jan - Oct)
                HStack(alignment: .bottom, spacing: 8) {
                    let months = [
                        ("Jan", 48, false),
                        ("Feb", 62, false),
                        ("Mar", 56, false),
                        ("Apr", 78, false),
                        ("May", 72, false),
                        ("Jun", 92, false),
                        ("Jul", 85, false),
                        ("Aug", 104, false),
                        ("Sep", 96, false),
                        ("Oct", 118, true) // Highlighted current month in red
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

            // Most listed matching Image 4
            VStack(alignment: .leading, spacing: 14) {
                Text("Most listed")
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
            f.dateFormat = "MMMM d"
            return f.string(from: dueDate)
        }

        var formattedTotal: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            let numStr = formatter.string(from: NSNumber(value: total)) ?? String(format: "%.2f", total)
            return "₱\(numStr)"
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
