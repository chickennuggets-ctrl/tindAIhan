//
//  ConfirmEntryView.swift
//  TindAIhan
//

import SwiftUI
import SwiftData

/// Confirmation screen matching wireframe 3 (Confirm Parsed Entry)
struct ConfirmEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var parsed: ParsedUtang
    var onSaveComplete: () -> Void
    var onRerecord: () -> Void

    @State private var customerName: String = ""
    @State private var items: [ParsedUtang.Line] = []
    @State private var dueDate: Date = Date.now
    @State private var isEditingCustomer = false
    @State private var isPickingDueDate = false
    @State private var isAddingItem = false
    @State private var newItemName = ""
    @State private var newItemQty = 1

    private var totalAmount: Double {
        items.reduce(0) { $0 + (Double($1.qty) * $1.unitPrice) }
    }

    private var formattedTotal: String {
        String(format: "₱%.2f", totalAmount)
    }

    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let dateStr = formatter.string(from: dueDate)

        let calendar = Calendar.current
        let day = calendar.component(.day, from: dueDate)
        let cutoff = day <= 15 ? "Kinsenas" : "Katapusan"
        return "\(dateStr) · \(cutoff)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TindAITheme.cream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Title Header matching Figma Image 3 with Speaker button
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Is this correct?")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundStyle(TindAITheme.textPrimary)
                            }

                            Spacer()

                            Button {
                                Haptics.light()
                                TextToSpeechService.shared.speakUtangSummary(
                                    customer: customerName,
                                    total: totalAmount,
                                    items: items
                                )
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundStyle(TindAITheme.brandRed)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white, in: Circle())
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                            }
                        }
                        .padding(.top, 10)

                        // 1. Suki Card
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Suki")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(TindAITheme.textSecondary)

                                    Text(customerName.isEmpty ? "Customer Name" : customerName)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(TindAITheme.textPrimary)
                                }

                                Spacer()

                                Button("Change") {
                                    Haptics.light()
                                    isEditingCustomer = true
                                }
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(TindAITheme.brandRed)
                            }
                        }
                        .padding(18)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)

                        // 2. Items List Card with Interactive Steppers
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.item.capitalized)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundStyle(TindAITheme.textPrimary)

                                        Text(String(format: "₱%.2f each", item.unitPrice))
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(TindAITheme.textSecondary)
                                    }

                                    Spacer()

                                    // Stepper (- [count] +)
                                    HStack(spacing: 12) {
                                        Button {
                                            decrementItem(at: index)
                                        } label: {
                                            Circle()
                                                .stroke(Color.gray.opacity(0.35), lineWidth: 1.5)
                                                .frame(width: 38, height: 38)
                                                .overlay(
                                                    Image(systemName: "minus")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundStyle(TindAITheme.textPrimary)
                                                )
                                        }
                                        .buttonStyle(.pressable(scale: 0.9))

                                        Text("\(item.qty)")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(TindAITheme.textPrimary)
                                            .frame(minWidth: 20)
                                            .contentTransition(.numericText())

                                        Button {
                                            incrementItem(at: index)
                                        } label: {
                                            Circle()
                                                .fill(TindAITheme.darkNavy)
                                                .frame(width: 38, height: 38)
                                                .overlay(
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundStyle(.white)
                                                )
                                        }
                                        .buttonStyle(.pressable(scale: 0.9))
                                    }
                                }
                                .padding(.vertical, 14)

                                if index < items.count - 1 {
                                    Divider()
                                }
                            }

                            Divider()
                                .padding(.vertical, 4)

                            // Add Item Button
                            Button {
                                Haptics.light()
                                isAddingItem = true
                            } label: {
                                HStack {
                                    Text("+ Add more items")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(TindAITheme.brandRed)
                                    Spacer()
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding(18)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)

                        // 3. Due Date Card (Collection Date)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Collection Date")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(TindAITheme.textSecondary)

                                Text(formattedDueDate)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(TindAITheme.textPrimary)
                            }

                            Spacer()

                            Button("Change") {
                                Haptics.light()
                                isPickingDueDate = true
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(TindAITheme.brandRed)
                        }
                        .padding(18)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)

                        // 4. Hero Total Card (Total)
                        HStack {
                            Text("Total")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)

                            Spacer()

                            Text(formattedTotal)
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(TindAITheme.textPrimary)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                        .background(TindAITheme.accentYellow, in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: TindAITheme.accentYellow.opacity(0.3), radius: 10, y: 4)

                        // Bottom Action Buttons matching Figma Image 3
                        VStack(spacing: 14) {
                            Button {
                                saveToLedger()
                            } label: {
                                Text("Save list")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(TindAITheme.brandRed, in: RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: TindAITheme.brandRed.opacity(0.35), radius: 10, y: 4)
                            }
                            .buttonStyle(.pressable(scale: 0.96))

                            Button {
                                Haptics.light()
                                dismiss()
                                onRerecord()
                            } label: {
                                Text("Record again")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(TindAITheme.textPrimary)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.pressable(scale: 0.96))
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kanselahin") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(TindAITheme.textSecondary)
                }
            }
            .sheet(isPresented: $isEditingCustomer) {
                editCustomerSheet
            }
            .sheet(isPresented: $isPickingDueDate) {
                editDueDateSheet
            }
            .sheet(isPresented: $isAddingItem) {
                addItemSheet
            }
            .onAppear {
                self.customerName = parsed.name
                self.items = parsed.items
                self.dueDate = parsed.dueDate

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    TextToSpeechService.shared.speakUtangSummary(
                        customer: customerName,
                        total: totalAmount,
                        items: items
                    )
                }
            }
        }
    }

    private func incrementItem(at index: Int) {
        Haptics.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            items[index].qty += 1
        }
    }

    private func decrementItem(at index: Int) {
        Haptics.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if items[index].qty > 1 {
                items[index].qty -= 1
            } else {
                items.remove(at: index)
            }
        }
    }

    private func saveToLedger() {
        Haptics.success()
        let txId = UUID()
        let now = Date.now

        for item in items {
            let entry = LedgerEntry(
                transactionId: txId,
                customer: customerName,
                item: item.item,
                quantity: item.qty,
                unitPrice: item.unitPrice,
                createdAt: now,
                dueDate: dueDate,
                isPaid: false
            )
            modelContext.insert(entry)
        }

        try? modelContext.save()
        TextToSpeechService.shared.speak("Nailista na po sa listahan para kay \(customerName)!")
        dismiss()
        onSaveComplete()
    }

    // MARK: - Modals
    private var editCustomerSheet: some View {
        NavigationStack {
            Form {
                Section("Pangalan ng Suki") {
                    TextField("Hal. Aling Nena", text: $customerName)
                }
                Section("Mabilisang Pili") {
                    ForEach(["Aling Nena", "Mang Jose", "Pedro", "Tita Baby", "Kuya Jobert"], id: \.self) { name in
                        Button(name) {
                            customerName = name
                            isEditingCustomer = false
                        }
                        .foregroundStyle(TindAITheme.textPrimary)
                    }
                }
            }
            .navigationTitle("Palitan ang Suki")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tapos") { isEditingCustomer = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var editDueDateSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Petsa ng Singil", selection: $dueDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .tint(TindAITheme.brandRed)
                    .padding()

                HStack(spacing: 12) {
                    Button("Kinsenas") {
                        let cal = Calendar.current
                        if let date = cal.date(bySetting: .day, value: 15, of: Date.now) {
                            dueDate = date
                        }
                        isPickingDueDate = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(TindAITheme.accentYellow, in: Capsule())
                    .foregroundStyle(TindAITheme.textPrimary)

                    Button("Katapusan") {
                        let cal = Calendar.current
                        if let range = cal.range(of: .day, in: .month, for: Date.now),
                           let date = cal.date(bySetting: .day, value: range.count, of: Date.now) {
                            dueDate = date
                        }
                        isPickingDueDate = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(TindAITheme.cardNavy, in: Capsule())
                    .foregroundStyle(.white)
                }
                Spacer()
            }
            .navigationTitle("Petsa ng Singil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tapos") { isPickingDueDate = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Hal. Kape, Sabon, Tinapay", text: $newItemName)
                    Stepper("Dami: \(newItemQty)", value: $newItemQty, in: 1...99)
                }
                Section("Mga Mungkahi") {
                    ForEach(PriceList.suggestedItems, id: \.self) { item in
                        Button("\(item.capitalized) (\(PriceList.formattedPrice(for: item)))") {
                            newItemName = item
                        }
                        .foregroundStyle(TindAITheme.textPrimary)
                    }
                }
            }
            .navigationTitle("Magdagdag ng Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kanselahin") { isAddingItem = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Idagdag") {
                        if !newItemName.isEmpty {
                            items.append(ParsedUtang.Line(item: newItemName.lowercased(), qty: newItemQty))
                            newItemName = ""
                            newItemQty = 1
                            isAddingItem = false
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
    let sample = ParsedUtang(
        name: "Aling Nena",
        items: [
            ParsedUtang.Line(item: "sardinas", qty: 2, unitPrice: 22.0),
            ParsedUtang.Line(item: "itlog", qty: 3, unitPrice: 10.0)
        ]
    )
    ConfirmEntryView(parsed: sample, onSaveComplete: {}, onRerecord: {})
}
