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
        let kinsenas = calendar.date(byAdding: .day, value: 6, to: now) ?? now
        let pastDue = calendar.date(byAdding: .day, value: -4, to: now) ?? now
        let today = now

        let t1 = UUID()
        let t2 = UUID()
        let t3 = UUID()
        let t4 = UUID()

        return [
            // Aling Nena (₱74 total for this transaction, ₱420 total overall)
            LedgerEntry(
                transactionId: t1,
                customer: "Aling Nena",
                customerPhone: "09171234567",
                item: "sardinas",
                quantity: 2,
                unitPrice: 22.0,
                createdAt: calendar.date(byAdding: .minute, value: -30, to: now) ?? now,
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
                createdAt: calendar.date(byAdding: .minute, value: -30, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),
            // Mang Jose (₱110, 2kg bigas)
            LedgerEntry(
                transactionId: t2,
                customer: "Mang Jose",
                customerPhone: "09189876543",
                item: "bigas (kg)",
                quantity: 2,
                unitPrice: 55.0,
                createdAt: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
                dueDate: kinsenas,
                isPaid: false
            ),
            // Pedro (₱75, 1 bigas 2 itlog - Due Today)
            LedgerEntry(
                transactionId: t3,
                customer: "Pedro",
                customerPhone: "09205551234",
                item: "bigas (kg)",
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
            // Tita Baby (₱279 total, 5 Lucky Me - Overdue)
            LedgerEntry(
                transactionId: t4,
                customer: "Tita Baby",
                customerPhone: "09081112233",
                item: "lucky me noodles",
                quantity: 5,
                unitPrice: 15.0,
                createdAt: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                dueDate: pastDue,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t4,
                customer: "Tita Baby",
                customerPhone: "09081112233",
                item: "asukal (kg)",
                quantity: 2,
                unitPrice: 50.0,
                createdAt: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                dueDate: pastDue,
                isPaid: false
            ),
            LedgerEntry(
                transactionId: t4,
                customer: "Tita Baby",
                customerPhone: "09081112233",
                item: "mantika (bote)",
                quantity: 2,
                unitPrice: 52.0,
                createdAt: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                dueDate: pastDue,
                isPaid: false
            )
        ]
    }
}
