//
//  CurrencyFormatter.swift
//  ExpenseSplitter
//
//  Single source of truth for turning Doubles into display currency strings
//  (and back), so every screen formats amounts identically.
//

import Foundation

enum CurrencyFormatter {

    /// Uses the device's current locale so the app shows $, €, ₹, etc. correctly.
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    /// Plain decimal formatter used while parsing user input in text fields.
    private static let parsingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Formats a raw amount as a localized currency string, e.g. "$42.50".
    static func string(from amount: Double) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }

    /// Formats a signed balance, used in the Balances screen (" +$12.00 " / " -$8.00 ").
    static func signedString(from amount: Double) -> String {
        let magnitude = abs(amount)
        let formatted = string(from: magnitude)
        if amount > 0.004 {
            return "+\(formatted)"
        } else if amount < -0.004 {
            return "-\(formatted)"
        } else {
            return formatted
        }
    }

    /// Parses user-entered text (e.g. from the Add Expense amount field) into a Double.
    /// Accepts both localized decimal separators and plain "12.34" style input.
    static func amount(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let number = parsingFormatter.number(from: trimmed) {
            return number.doubleValue
        }

        // Fall back to a plain Double parse for simple "12.34" input that the
        // locale-aware formatter might reject (e.g. different decimal separator).
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
