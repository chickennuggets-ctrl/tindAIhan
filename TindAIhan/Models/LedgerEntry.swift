//
//  LedgerEntry.swift
//  TindAIhan
//

import Foundation
import SwiftData

/// One item entry in the sari-sari store listahan, persisted on-device via SwiftData.
@Model
final class LedgerEntry {
    var id: UUID = UUID()
    var transactionId: UUID = UUID()
    var customer: String = ""
    var customerPhone: String? = nil
    var item: String = ""
    var quantity: Int = 1
    var unitPrice: Double = 0.0
    var createdAt: Date = Date.now
    var dueDate: Date = Date.now
    var isPaid: Bool = false
    var paidAt: Date? = nil
    var notes: String? = nil

    var total: Double {
        Double(quantity) * unitPrice
    }

    var formattedTotal: String {
        String(format: "₱%.2f", total)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tl_PH")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var relativeTimeString: String {
        let now = Date.now
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: createdAt, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "kahapon" : "\(days) araw"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) oras ang nakalipas"
        } else if let minutes = components.minute, minutes > 5 {
            return "\(minutes) minuto ang nakalipas"
        } else {
            return "kanina"
        }
    }

    var dueStatusDescription: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) {
            return "Ngayon"
        } else if dueDate < calendar.startOfDay(for: Date.now) {
            let days = calendar.dateComponents([.day], from: dueDate, to: Date.now).day ?? 1
            return "\(days) araw na lampas"
        } else {
            let days = calendar.dateComponents([.day], from: Date.now, to: dueDate).day ?? 1
            return "\(days) na araw"
        }
    }

    init(
        id: UUID = UUID(),
        transactionId: UUID = UUID(),
        customer: String,
        customerPhone: String? = nil,
        item: String,
        quantity: Int,
        unitPrice: Double,
        createdAt: Date = .now,
        dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
        isPaid: Bool = false,
        paidAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.transactionId = transactionId
        self.customer = customer
        self.customerPhone = customerPhone
        self.item = item
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.paidAt = paidAt
        self.notes = notes
    }
}

/// Structured transaction extracted by the LLM or natural language parser.
struct ParsedUtang: Codable, Identifiable {
    var id: UUID = UUID()

    struct Line: Codable, Identifiable {
        var id: String { "\(item)-\(qty)-\(unitPrice)" }
        var item: String
        var qty: Int
        var unitPrice: Double

        init(item: String, qty: Int, unitPrice: Double = 0.0) {
            self.item = item
            self.qty = qty
            self.unitPrice = unitPrice > 0 ? unitPrice : PriceList.price(for: item)
        }

        var total: Double {
            Double(qty) * unitPrice
        }
    }

    var name: String
    var items: [Line]
    var dueDate: Date

    init(name: String, items: [Line], dueDate: Date = Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now) {
        self.name = name
        self.items = items
        self.dueDate = dueDate
    }

    var kabuuan: Double {
        items.reduce(0) { $0 + $1.total }
    }

    var formattedKabuuan: String {
        String(format: "₱%.2f", kabuuan)
    }
}

// MARK: - Sample Seed Data matching Figma Design
extension LedgerEntry {
    @MainActor
    static var previewSamples: [LedgerEntry] {
        let calendar = Calendar.current
        let now = Date.now
        let kinsenas = calendar.date(byAdding: .day, value: 5, to: now) ?? now
        let pastDue = calendar.date(byAdding: .day, value: -4, to: now) ?? now
        let pastDueLong = calendar.date(byAdding: .day, value: -8, to: now) ?? now
        let today = now

        let t1 = UUID()
        let t1_older = UUID()
        let t2 = UUID()
        let t2_older = UUID()
        let t3 = UUID()
        let t3_older = UUID()
        let t4 = UUID()
        let t4_older = UUID()
        let t5 = UUID()
        let t6 = UUID()
        let t7 = UUID()

        return [
            // 1. Aling Nena: Recent ₱74.00 (2 sardinas, 3 itlog · 6:07 pm)
            LedgerEntry(
                transactionId: t1,
                customer: "Aling Nena",
                customerPhone: "09171234567",
                item: "sardinas",
                quantity: 2,
                unitPrice: 22.0,
                createdAt: calendar.date(byAdding: .minute, value: -40, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t1,
                customer: "Aling Nena",
                customerPhone: "09171234567",
                item: "itlog",
                quantity: 3,
                unitPrice: 10.0,
                createdAt: calendar.date(byAdding: .minute, value: -40, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),
            // Aling Nena: Older entries bringing her total to ₱420.00
            LedgerEntry(
                transactionId: t1_older,
                customer: "Aling Nena",
                customerPhone: "09171234567",
                item: "bigas (kg)",
                quantity: 4,
                unitPrice: 55.0,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t1_older,
                customer: "Aling Nena",
                customerPhone: "09171234567",
                item: "mantika",
                quantity: 2,
                unitPrice: 63.0,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),

            // 2. Mang Jose: Recent ₱110.00 (2 kg bigas · 4 :57 pm)
            LedgerEntry(
                transactionId: t2,
                customer: "Mang Jose",
                customerPhone: "09189876543",
                item: "kg bigas",
                quantity: 2,
                unitPrice: 55.0,
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),
            // Mang Jose: Older entries bringing his total to ₱310.00
            LedgerEntry(
                transactionId: t2_older,
                customer: "Mang Jose",
                customerPhone: "09189876543",
                item: "sardinas",
                quantity: 5,
                unitPrice: 22.0,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t2_older,
                customer: "Mang Jose",
                customerPhone: "09189876543",
                item: "asukal",
                quantity: 2,
                unitPrice: 45.0,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),

            // 3. Pedro: Recent ₱75.00 (1 kg bigas, 2 itlog · October 9)
            LedgerEntry(
                transactionId: t3,
                customer: "Pedro",
                customerPhone: "09205551234",
                item: "kg bigas",
                quantity: 1,
                unitPrice: 55.0,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                dueDate: today,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t3,
                customer: "Pedro",
                customerPhone: "09205551234",
                item: "itlog",
                quantity: 2,
                unitPrice: 10.0,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                dueDate: today,
                isPaid: false
            ),
            // Pedro: Older entries bringing his total to ₱275.00
            LedgerEntry(
                transactionId: t3_older,
                customer: "Pedro",
                customerPhone: "09205551234",
                item: "lucky me noodles",
                quantity: 10,
                unitPrice: 15.0,
                createdAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                dueDate: today,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t3_older,
                customer: "Pedro",
                customerPhone: "09205551234",
                item: "kape",
                quantity: 5,
                unitPrice: 10.0,
                createdAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                dueDate: today,
                isPaid: false
            ),

            // 4. Tita Baby: Recent ₱75.00 (5 Lucky Me · October 6)
            LedgerEntry(
                transactionId: t4,
                customer: "Tita Baby",
                customerPhone: "09081112233",
                item: "Lucky Me",
                quantity: 5,
                unitPrice: 15.0,
                createdAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                dueDate: pastDue,
                isPaid: false
            ),
            // Tita Baby: Older entries bringing her total to ₱279.00
            LedgerEntry(
                transactionId: t4_older,
                customer: "Tita Baby",
                customerPhone: "09081112233",
                item: "mantika",
                quantity: 2,
                unitPrice: 52.0,
                createdAt: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
                dueDate: pastDueLong,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t4_older,
                customer: "Tita Baby",
                customerPhone: "09081112233",
                item: "asukal",
                quantity: 2,
                unitPrice: 50.0,
                createdAt: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
                dueDate: pastDueLong,
                isPaid: false
            ),

            // 5. Kuya Jobert (Overdue ₱1,840.67)
            LedgerEntry(
                transactionId: t5,
                customer: "Kuya Jobert",
                customerPhone: "09178889900",
                item: "bigas (kaban)",
                quantity: 1,
                unitPrice: 1840.67,
                createdAt: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
                dueDate: pastDueLong,
                isPaid: false
            ),

            // 6. Ate Marites (Overdue ₱2,123.00)
            LedgerEntry(
                transactionId: t6,
                customer: "Ate Marites",
                customerPhone: "09223334455",
                item: "groceries assorted",
                quantity: 1,
                unitPrice: 2123.0,
                createdAt: calendar.date(byAdding: .day, value: -9, to: now) ?? now,
                dueDate: pastDueLong,
                isPaid: false
            ),

            // 7. Nanay Tess (₱1,520.00, upcoming)
            LedgerEntry(
                transactionId: t7,
                customer: "Nanay Tess",
                customerPhone: "09194445566",
                item: "bigas at de lata",
                quantity: 1,
                unitPrice: 1520.0,
                createdAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                dueDate: calendar.date(byAdding: .day, value: 10, to: now) ?? now,
                isPaid: false
            )
        ]
    }
}
