//
//  QuickPickData.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

/// Pure data — no logic. Each entry is (label, expression) for the Quick Pick panel.
public struct QuickPickCategory: Identifiable {
    public let id = UUID()
    public let name: String
    public let icon: String
    public let items: [(label: String, expression: String)]
}

public enum QuickPickData {
    
    public static let categories: [QuickPickCategory] = [
        QuickPickCategory(
            name: "Basic",
            icon: "function",
            items: [
                ("Linear",        "2 * x + 1"),
                ("Quadratic",     "x ^ 2"),
                ("Cubic",         "x ^ 3"),
                ("Parabola",      "x ^ 2 - 4"),
                ("Absolute",      "abs(x)"),
                ("Square Root",   "sqrt(x)"),
                ("Reciprocal",    "1 / x"),
                ("Semicircle",    "sqrt(9 - x ^ 2)")
            ]
        ),
        QuickPickCategory(
            name: "Trigonometry",
            icon: "waveform.path",
            items: [
                ("Sine",          "sin(x)"),
                ("Cosine",        "cos(x)"),
                ("Tangent",       "tan(x)"),
                ("Sin × Cos",     "sin(x) * cos(x)"),
                ("Sin²",          "sin(x) ^ 2"),
                ("Double Angle",  "sin(2 * x)"),
                ("Damped Sine",   "sin(x) / x")
            ]
        ),
        QuickPickCategory(
            name: "Exp / Log",
            icon: "chart.line.uptrend.xyaxis",
            items: [
                ("Exponential",   "exp(x)"),
                ("Decay",         "exp(-x)"),
                ("Natural Log",   "ln(x)"),
                ("Gaussian",      "exp(-(x ^ 2))"),
                ("Logistic",      "1 / (1 + exp(-x))"),
                ("x·ln(x)",       "x * ln(x)")
            ]
        ),
        QuickPickCategory(
            name: "Polar",
            icon: "circle.dashed",
            items: [
                ("Circle",        "3"),
                ("Cardioid",      "1 + cos(x)"),
                ("Rose 4-petal",  "cos(2 * x)"),
                ("Rose 3-petal",  "sin(3 * x)"),
                ("Spiral",        "x"),
                ("Lemniscate",    "sqrt(abs(cos(2 * x)))")
            ]
        )
    ]
}
