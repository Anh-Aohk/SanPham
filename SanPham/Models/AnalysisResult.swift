//
//  AnalysisResult.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public enum AnalysisResult {
    case value(x: Double, y: Double)
    case roots([Double])
    case derivativeSymbolic(expression: String)
    case derivativeAtPoint(x: Double, result: Double)
    case antiderivative(expression: String)
    case integral(a: Double, b: Double, result: Double)
}
