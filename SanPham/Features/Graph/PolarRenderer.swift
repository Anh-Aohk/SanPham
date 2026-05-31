//
//  PolarRenderer.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import SwiftUI

public struct PolarRenderer {
    
    public static func render(
        in context: GraphicsContext,
        size: CGSize,
        viewport: ViewPort,
        functions: [FunctionModel],
        viewModel: GraphViewModel
    ) {
        // Draw background
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.08, green: 0.09, blue: 0.13)))
        
        let xSpan = viewport.xMax - viewport.xMin
        let ySpan = viewport.yMax - viewport.yMin
        
        guard xSpan > 0 && ySpan > 0 else { return }
        
        // Calculate dynamic grid spacing based on viewport size
        let maxLimit = max(
            max(abs(viewport.xMin), abs(viewport.xMax)),
            max(abs(viewport.yMin), abs(viewport.yMax))
        )
        let ringStep = calculateGridStep(span: maxLimit)
        
        // 1. Draw Concentric Grid Rings
        drawConcentricRings(in: context, size: size, viewport: viewport, maxRadius: maxLimit * 1.5, ringStep: ringStep)
        
        // 2. Draw Radial Spokes
        drawRadialSpokes(in: context, size: size, viewport: viewport, maxRadius: maxLimit * 1.5)
        
        // 3. Draw Axis Lines (thick X and Y through origin)
        drawAxes(in: context, size: size, viewport: viewport)
        
        // 4. Draw Radial & Ring Labels
        drawLabels(in: context, size: size, viewport: viewport, ringStep: ringStep, maxLimit: maxLimit)
        
        // 5. Render Functions
        drawFunctions(in: context, size: size, functions: functions, viewModel: viewModel)
    }
    
    // MARK: - Grid Spacing Calculation
    private static func calculateGridStep(span: Double) -> Double {
        let rawStep = span / 5.0
        let logStep = log10(rawStep)
        let powerOf10 = pow(10.0, floor(logStep))
        let ratio = rawStep / powerOf10
        
        if ratio < 1.5 {
            return powerOf10
        } else if ratio < 3.0 {
            return 2.0 * powerOf10
        } else if ratio < 7.0 {
            return 5.0 * powerOf10
        } else {
            return 10.0 * powerOf10
        }
    }
    
    // MARK: - Rings Drawing
    private static func drawConcentricRings(
        in context: GraphicsContext,
        size: CGSize,
        viewport: ViewPort,
        maxRadius: Double,
        ringStep: Double
    ) {
        var r = ringStep
        while r <= maxRadius {
            // Draw ring circle
            let center = viewport.toCanvas(0, 0, size: size)
            
            // Width/height on canvas for mathematical radius r
            // Convert (-r, r) and (r, -r) to find the canvas bounding box
            let topLeft = viewport.toCanvas(-r, r, size: size)
            let bottomRight = viewport.toCanvas(r, -r, size: size)
            
            let rect = CGRect(
                x: topLeft.x,
                y: topLeft.y,
                width: bottomRight.x - topLeft.x,
                height: bottomRight.y - topLeft.y
            )
            
            var path = Path()
            path.addEllipse(in: rect)
            
            context.stroke(
                path,
                with: .color(Color.white.opacity(0.12)),
                style: StrokeStyle(lineWidth: 1.0)
            )
            
            r += ringStep
        }
    }
    
    // MARK: - Radial Spokes Drawing
    private static func drawRadialSpokes(
        in context: GraphicsContext,
        size: CGSize,
        viewport: ViewPort,
        maxRadius: Double
    ) {
        // Spokes every 30 degrees (pi / 6 radians)
        for i in 0..<12 {
            let angle = Double(i) * Double.pi / 6.0
            
            // Skip 0, 90, 180, 270 as they lie exactly on the primary axes
            if i % 3 == 0 { continue }
            
            let startPoint = viewport.toCanvas(0, 0, size: size)
            let endX = maxRadius * Foundation.cos(angle)
            let endY = maxRadius * Foundation.sin(angle)
            let endPoint = viewport.toCanvas(endX, endY, size: size)
            
            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
            context.stroke(
                path,
                with: .color(Color.white.opacity(0.08)),
                style: StrokeStyle(lineWidth: 1.0, dash: [4, 4])
            )
        }
    }
    
    // MARK: - Main Axes Drawing
    private static func drawAxes(in context: GraphicsContext, size: CGSize, viewport: ViewPort) {
        var axesPath = Path()
        
        // Y-axis (vertical line through origin)
        if viewport.xMin <= 0 && viewport.xMax >= 0 {
            let start = viewport.toCanvas(0.0, viewport.yMax, size: size)
            let end = viewport.toCanvas(0.0, viewport.yMin, size: size)
            axesPath.move(to: start)
            axesPath.addLine(to: end)
        }
        
        // X-axis (horizontal line through origin)
        if viewport.yMin <= 0 && viewport.yMax >= 0 {
            let start = viewport.toCanvas(viewport.xMin, 0.0, size: size)
            let end = viewport.toCanvas(viewport.xMax, 0.0, size: size)
            axesPath.move(to: start)
            axesPath.addLine(to: end)
        }
        
        context.stroke(
            axesPath,
            with: .color(Color.white.opacity(0.35)),
            style: StrokeStyle(lineWidth: 1.5)
        )
    }
    
    // MARK: - Labels Drawing
    private static func drawLabels(
        in context: GraphicsContext,
        size: CGSize,
        viewport: ViewPort,
        ringStep: Double,
        maxLimit: Double
    ) {
        let labelColor = Color.white.opacity(0.6)
        let font = Font.system(size: 9, weight: .medium, design: .monospaced)
        
        // 1. Draw Ring radius values along the positive X-axis
        let origin = viewport.toCanvas(0, 0, size: size)
        var r = ringStep
        while r <= maxLimit {
            let pos = viewport.toCanvas(r, 0, size: size)
            // Only draw label if it is comfortably inside the screen boundaries
            if pos.x < size.width - 20 && pos.x > 20 {
                let labelText = formatLabelValue(r)
                var resolvedText = context.resolve(Text(labelText).font(font).foregroundColor(labelColor))
                let textSize = resolvedText.measure(in: size)
                
                context.draw(
                    resolvedText,
                    at: CGPoint(x: pos.x, y: origin.y + textSize.height / 2.0 + 3)
                )
            }
            r += ringStep
        }
        
        // 2. Draw Spoke Angle Labels around the outer edge or a fixed distance from origin
        let labelRadius = min(size.width, size.height) * 0.43
        let angles: [(Double, String)] = [
            (0, "0°"),
            (Double.pi / 6.0, "30° (π/6)"),
            (Double.pi / 3.0, "60° (π/3)"),
            (Double.pi / 2.0, "90° (π/2)"),
            (2.0 * Double.pi / 3.0, "120° (2π/3)"),
            (5.0 * Double.pi / 6.0, "150° (5π/6)"),
            (Double.pi, "180° (π)"),
            (7.0 * Double.pi / 6.0, "210° (7π/6)"),
            (4.0 * Double.pi / 3.0, "240° (4π/3)"),
            (3.0 * Double.pi / 2.0, "270° (3π/2)"),
            (5.0 * Double.pi / 3.0, "300° (5π/3)"),
            (11.0 * Double.pi / 6.0, "330° (11π/6)")
        ]
        
        for (angle, label) in angles {
            // Draw angle labels relative to canvas origin
            let dx = labelRadius * Foundation.cos(angle)
            let dy = -labelRadius * Foundation.sin(angle) // negative because canvas Y runs down
            
            let drawPos = CGPoint(x: origin.x + dx, y: origin.y + dy)
            
            // Only draw inside screen bounds
            if drawPos.x > 15 && drawPos.x < size.width - 15 && drawPos.y > 15 && drawPos.y < size.height - 15 {
                var resolvedText = context.resolve(Text(label).font(font).foregroundColor(labelColor.opacity(0.75)))
                context.draw(resolvedText, at: drawPos)
            }
        }
    }
    
    private static func formatLabelValue(_ val: Double) -> String {
        let absVal = abs(val)
        if absVal >= 1e6 || (absVal > 0 && absVal < 1e-3) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .scientific
            formatter.maximumFractionDigits = 1
            return formatter.string(from: NSNumber(value: val)) ?? "\(val)"
        }
        let rounded = round(val * 1000.0) / 1000.0
        return rounded == floor(rounded) ? String(format: "%.0f", rounded) : "\(rounded)"
    }
    
    // MARK: - Functions Drawing
    private static func drawFunctions(
        in context: GraphicsContext,
        size: CGSize,
        functions: [FunctionModel],
        viewModel: GraphViewModel
    ) {
        for function in functions {
            let paths = viewModel.generatePaths(for: function, size: size)
            let color = Color(
                red: function.color.red,
                green: function.color.green,
                blue: function.color.blue,
                opacity: function.color.alpha
            )
            
            for points in paths {
                guard points.count > 1 else { continue }
                
                var path = Path()
                path.move(to: points[0])
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
                
                var glowContext = context
                glowContext.addFilter(.shadow(color: color.opacity(0.35), radius: 3, x: 0, y: 0))
                glowContext.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}
