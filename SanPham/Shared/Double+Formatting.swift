//
//  Double+Formatting.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

extension Double {
    /// Format a double value to a specified number of decimal places.
    /// Removes trailing zeros for cleaner display.
    public func formatted(decimalPlaces: Int = 4) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimalPlaces
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// Format specifically for mathematical expressions (no grouping separator)
    public func mathFormatted(decimalPlaces: Int = 6) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimalPlaces
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
