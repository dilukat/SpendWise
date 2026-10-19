//
//  ReceiptDetailsExtractor.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-19.
//


import Foundation

struct ExtractedReceiptDetails {
    let merchant: String?
    let amount: Double?
    let date: Date?
}

struct ReceiptDetailsExtractor {

    static func extract(from lines: [String]) -> ExtractedReceiptDetails {
        let merchant = extractMerchant(from: lines)
        let amount = extractAmount(from: lines)
        let date = extractDate(from: lines)

        return ExtractedReceiptDetails(
            merchant: merchant,
            amount: amount,
            date: date
        )
    }

    // MARK: - Merchant

    private static func extractMerchant(from lines: [String]) -> String? {
        let ignoredWords = [
            "receipt", "invoice", "tax invoice",
            "cash receipt", "customer copy"
        ]

        for line in lines.prefix(6) {
            let candidate = line.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !candidate.isEmpty else { continue }

            let normalized = candidate.lowercased()

            if ignoredWords.contains(where: {
                normalized == $0 || normalized.hasPrefix($0 + " ")
            }) {
                continue
            }

            if candidate.rangeOfCharacter(
                from: .letters
            ) != nil {
                return candidate
            }
        }

        return nil
    }

    // MARK: - Amount

    
    private static func extractAmount(from lines: [String]) -> Double? {

        // First, look for amounts on lines that identify a payable total.
        let preferredKeywords = [
            "grand total",
            "total payable",
            "net payable",
            "amount due",
            "net amount",
            "total"
        ]

        for keyword in preferredKeywords {
            for line in lines.reversed() {
                let normalized = line.lowercased()

                guard normalized.contains(keyword) else { continue }

                if let amount = lastAmount(in: line) {
                    return amount
                }
            }
        }

        // Fallback: receipts may print the final amount on its own line,
        // such as "Rs. 255.00", without a total-related keyword.
        for line in lines.reversed() {
            let normalized = line.lowercased()

            let hasCurrencyMarker =
                normalized.contains("rs.") ||
                normalized.contains("rs ") ||
                normalized.contains("lkr")

            guard hasCurrencyMarker else { continue }

            if let amount = lastAmount(in: line) {
                return amount
            }
        }

        return nil
    }


    private static func lastAmount(in text: String) -> Double? {
        // Supports common formats such as:
        // 1250.00, 1,250.00, Rs. 1250.00
        let pattern = #"(?<!\d)\d[\d,]*(?:\.\d{1,2})?(?!\d)"#

        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: text) else {
                continue
            }

            let rawValue = String(text[matchRange])
                .replacingOccurrences(of: ",", with: "")

            if let amount = Double(rawValue), amount > 0 {
                return amount
            }
        }

        return nil
    }

    // MARK: - Date

    private static func extractDate(from lines: [String]) -> Date? {
        let formats = [
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "yyyy-MM-dd",
            "dd/MM/yy",
            "dd-MM-yy",
            "MM/dd/yyyy",
            "dd MMM yyyy",
            "dd MMMM yyyy"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.isLenient = false

        for line in lines {
            for format in formats {
                formatter.dateFormat = format

                if let date = formatter.date(from: line) {
                    return date
                }
            }
        }

        return nil
    }
}
