//
//  FunctionModel.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public struct RGBAColor: Codable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public struct FunctionModel: Identifiable, Codable, Hashable {
    public let id: UUID
    public var expression: String
    public var color: RGBAColor
    public var isVisible: Bool
    public var isPolar: Bool

    public init(
        id: UUID = UUID(),
        expression: String,
        color: RGBAColor,
        isVisible: Bool = true,
        isPolar: Bool = false
    ) {
        self.id = id
        self.expression = expression
        self.color = color
        self.isVisible = isVisible
        self.isPolar = isPolar
    }
}
