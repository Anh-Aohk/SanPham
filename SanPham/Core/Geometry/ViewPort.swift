//
//  ViewPort.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation
import CoreGraphics

public struct ViewPort: Codable, Hashable {
    public var xMin: Double
    public var xMax: Double
    public var yMin: Double
    public var yMax: Double
    
    public init(xMin: Double = -10.0, xMax: Double = 10.0, yMin: Double = -6.0, yMax: Double = 6.0) {
        self.xMin = xMin
        self.xMax = xMax
        self.yMin = yMin
        self.yMax = yMax
    }
    
    /// Converts mathematical coordinates to pixel coordinates on the canvas.
    /// - Parameters:
    ///   - mathX: The x coordinate in mathematical space.
    ///   - mathY: The y coordinate in mathematical space.
    ///   - size: The size of the canvas in points.
    /// - Returns: The CGPoint on the canvas.
    public func toCanvas(_ mathX: Double, _ mathY: Double, size: CGSize) -> CGPoint {
        let px = (mathX - xMin) / (xMax - xMin) * Double(size.width)
        let py = (1.0 - (mathY - yMin) / (yMax - yMin)) * Double(size.height)
        return CGPoint(x: CGFloat(px), y: CGFloat(py))
    }
    
    /// Converts canvas pixel coordinates back to mathematical coordinates.
    /// - Parameters:
    ///   - canvasPoint: The point on the canvas.
    ///   - size: The size of the canvas in points.
    /// - Returns: A tuple of (x, y) in mathematical space.
    public func toMath(_ canvasPoint: CGPoint, size: CGSize) -> (x: Double, y: Double) {
        let mx = xMin + (Double(canvasPoint.x) / Double(size.width)) * (xMax - xMin)
        let my = yMin + (1.0 - Double(canvasPoint.y) / Double(size.height)) * (yMax - yMin)
        return (mx, my)
    }
}
