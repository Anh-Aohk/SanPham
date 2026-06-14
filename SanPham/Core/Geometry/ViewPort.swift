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
    
    /// Returns a new ViewPort adjusted to match the aspect ratio of the canvas size
    /// by expanding the smaller dimension around its center.
    public func adjustedToAspectRatio(for size: CGSize) -> ViewPort {
        guard size.width > 0 && size.height > 0 else { return self }
        
        let cx = (xMin + xMax) / 2.0
        let cy = (yMin + yMax) / 2.0
        
        let currentXSpan = xMax - xMin
        let currentYSpan = yMax - yMin
        
        let canvasAspectRatio = Double(size.width) / Double(size.height)
        
        var newXMin = xMin
        var newXMax = xMax
        var newYMin = yMin
        var newYMax = yMax
        
        if currentXSpan / Double(size.width) > currentYSpan / Double(size.height) {
            // X-span is relatively larger (scale along Y would be larger, meaning squashed vertically).
            // Expand Y-span to match the scale along X.
            let newYSpan = currentXSpan / canvasAspectRatio
            newYMin = cy - newYSpan / 2.0
            newYMax = cy + newYSpan / 2.0
        } else {
            // Y-span is relatively larger (scale along X would be larger, meaning squashed horizontally).
            // Expand X-span to match the scale along Y.
            let newXSpan = currentYSpan * canvasAspectRatio
            newXMin = cx - newXSpan / 2.0
            newXMax = cx + newXSpan / 2.0
        }
        
        return ViewPort(xMin: newXMin, xMax: newXMax, yMin: newYMin, yMax: newYMax)
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
