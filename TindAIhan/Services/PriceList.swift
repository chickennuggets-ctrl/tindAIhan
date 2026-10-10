//
//  PriceList.swift
//  TindAIhan
//

import Foundation

/// Offline price catalog (PHP) for common sari-sari store goods.
/// Easily customizable; unrecognized items default to `defaultPrice`.
enum PriceList {
    static let defaultPrice: Double = 15.0

    static let prices: [String: Double] = [
        // Staples & Cooking
        "bigas": 55.0,
        "rice": 55.0,
        "itlog": 10.0,
        "egg": 10.0,
        "eggs": 10.0,
        "mantika": 20.0,
        "oil": 20.0,
        "cooking oil": 20.0,
        "asukal": 25.0,
        "sugar": 25.0,
        "asin": 10.0,
        "salt": 10.0,
        "bawang": 5.0,
        "garlic": 5.0,
        "sibuyas": 5.0,
        "onion": 5.0,
        "magic sarap": 7.0,

        // Canned & Instant
        "sardinas": 22.0,
        "sardines": 22.0,
        "corned beef": 38.0,
        "meat loaf": 25.0,
        "tuna": 35.0,
        "noodles": 16.0,
        "lucky me": 16.0,
        "pancit canton": 18.0,
        "canton": 18.0,

        // Beverages & Dairy
        "kape": 14.0,
        "coffee": 14.0,
        "nescafe": 14.0,
        "kopiko": 14.0,
        "milo": 15.0,
        "bear brand": 16.0,
        "gatas": 16.0,
        "milk": 16.0,
        "softdrinks": 20.0,
        "coke": 20.0,
        "sprite": 20.0,
        "royal": 20.0,
        "tubig": 15.0,
        "water": 15.0,
        "mineral": 15.0,
        "c2": 18.0,

        // Snacks & Bread
        "tinapay": 5.0,
        "bread": 5.0,
        "pandesal": 3.0,
        "chichirya": 10.0,
        "chips": 10.0,
        "biskwit": 10.0,
        "biscuit": 10.0,
        "biscuits": 10.0,

        // Personal Care & Household
        "sabon": 25.0,
        "soap": 25.0,
        "safeguard": 25.0,
        "surf": 12.0,
        "tide": 14.0,
        "downy": 10.0,
        "shampoo": 8.0,
        "toothpaste": 12.0,
        "yosi": 10.0,
        "cigarette": 10.0,
        "cigarettes": 10.0
    ]

    /// Lookup unit price by item name (case-insensitive substring match)
    static func price(for item: String) -> Double {
        let key = item.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = prices[key] {
            return exact
        }
        return prices.first(where: { key.contains($0.key) || $0.key.contains(key) })?.value ?? defaultPrice
    }

    /// Formatted currency string in PHP
    static func formattedPrice(for item: String) -> String {
        let amount = price(for: item)
        return String(format: "₱%.2f", amount)
    }

    /// Popular items for quick-pick UI tags
    static var suggestedItems: [String] {
        ["bigas", "itlog", "sardinas", "pancit canton", "kape", "yosi", "coke"]
    }
}
