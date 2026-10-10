//
//  SukiDirectoryView.swift
//  TindAIhan
//

import SwiftUI
import SwiftData

/// Customer directory tab (Suki)
struct SukiDirectoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [LedgerEntry]

    @State private var searchText = ""
    @State private var isAddingNewSuki = false
    @State private var newSukiName = ""
    @State private var newSukiPhone = ""
    @State private var selectedSuki: String? = nil

    struct SukiProfile: Identifiable {
        let id: String
        let name: String
        let phone: String?
        let activeUtang: Double
        let totalTransactions: Int
    }

    private var sukiProfiles: [SukiProfile] {
        let grouped = Dictionary(grouping: allEntries) { $0.customer }
        var list = grouped.map { name, entries in
            let active = entries.filter { !$0.isPaid }.reduce(0) { $0 + $1.total }
            let phone = entries.first?.customerPhone
            return SukiProfile(
                id: name,
                name: name,
                phone: phone,
                activeUtang: active,
                totalTransactions: entries.count
            )
        }

        // Add default sample suki if empty
        if list.isEmpty {
            list = [
                SukiProfile(id: "Aling Nena", name: "Aling Nena", phone: "09171234567", activeUtang: 420.0, totalTransactions: 12),
                SukiProfile(id: "Mang Jose", name: "Mang Jose", phone: "09189876543", activeUtang: 310.0, totalTransactions: 8),
                SukiProfile(id: "Pedro", name: "Pedro", phone: "09205551234", activeUtang: 275.0, totalTransactions: 15),
                SukiProfile(id: "Tita Baby", name: "Tita Baby", phone: "09081112233", activeUtang: 279.0, totalTransactions: 6)
            ]
        }

        if !searchText.isEmpty {
            return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return list.sorted { $0.name < $1.name }
    }

    var body: some View {
        ZStack {
            TindAITheme.cream
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mga Suki")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)
                            Text("\(sukiProfiles.count) nakatalang customer")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(TindAITheme.textSecondary)
                        }

                        Spacer()

                        Button {
                            Haptics.light()
                            isAddingNewSuki = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(TindAITheme.brandRed)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                    // Search Field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(TindAITheme.textSecondary)
                        TextField("Maghanap ng suki…", text: $searchText)
                            .font(.system(size: 15, design: .rounded))
                    }
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    // Suki List
                    VStack(spacing: 0) {
                        ForEach(Array(sukiProfiles.enumerated()), id: \.element.id) { index, suki in
                            Button {
                                Haptics.light()
                                selectedSuki = suki.name
                            } label: {
                                HStack(spacing: 14) {
                                    SukiAvatar(name: suki.name, size: 48)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(suki.name)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundStyle(TindAITheme.textPrimary)

                                        Text(suki.phone ?? "Walang phone number")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(TindAITheme.textSecondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text(String(format: "₱%.2f", suki.activeUtang))
                                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                                            .foregroundStyle(suki.activeUtang > 0 ? TindAITheme.brandRed : Color.gray)

                                        Text(suki.activeUtang > 0 ? "May utang" : "Walang utang")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(suki.activeUtang > 0 ? TindAITheme.brandRed : Color.green)
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 18)
                            }
                            .buttonStyle(.pressable(scale: 0.98))

                            if index < sukiProfiles.count - 1 {
                                Divider().padding(.leading, 78)
                            }
                        }
                    }
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 100)
                }
            }
            .scrollBounceBehavior(.always)
        }
        .sheet(item: Binding(
            get: { selectedSuki.map { CustomerDetailSheetItem(name: $0) } },
            set: { selectedSuki = $0?.name }
        )) { item in
            CustomerDetailView(customerName: item.name)
        }
        .sheet(isPresented: $isAddingNewSuki) {
            newSukiSheet
        }
    }

    private var newSukiSheet: some View {
        NavigationStack {
            Form {
                Section("Impormasyon ng Suki") {
                    TextField("Pangalan (Hal. Nanay Tess)", text: $newSukiName)
                    TextField("Cellphone Number (Hal. 09171234567)", text: $newSukiPhone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Bagong Suki")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kanselahin") { isAddingNewSuki = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("I-save") {
                        if !newSukiName.isEmpty {
                            // Seed an initial contact entry
                            let entry = LedgerEntry(
                                customer: newSukiName,
                                customerPhone: newSukiPhone.isEmpty ? nil : newSukiPhone,
                                item: "listahan setup",
                                quantity: 0,
                                unitPrice: 0,
                                isPaid: true
                            )
                            modelContext.insert(entry)
                            try? modelContext.save()
                            newSukiName = ""
                            newSukiPhone = ""
                            isAddingNewSuki = false
                        }
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    SukiDirectoryView()
        .modelContainer(for: LedgerEntry.self, inMemory: true)
}
