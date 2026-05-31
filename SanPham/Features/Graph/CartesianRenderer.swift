//
//  CartesianRenderer.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import SwiftUI

public struct CartesianRenderer {
    
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
        
        // Calculate dynamic grid spacing
        let xStep = calculateGridStep(span: xSpan)
        let yStep = calculateGridStep(span: ySpan)
        
        // 1. Draw Grid Lines
        drawGridLines(in: context, size: size, viewport: viewport, xStep: xStep, yStep: yStep)
        
        // 2. Draw Main Axes
        drawAxes(in: context, size: size, viewport: viewport)
        
        // 3. Draw Axis Labels
        drawLabels(in: context, size: size, viewport: viewport, xStep: xStep, yStep: yStep)
        
        // 4. Render Functions
        drawFunctions(in: context, size: size, functions: functions, viewModel: viewModel)
    }
    
    // MARK: - Grid Spacing Calculation
    private static func calculateGridStep(span: Double) -> Double {
        let rawStep = span / 8.0
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
    
    // MARK: - Grid Drawing
    private static func drawGridLines(
        in context: GraphicsContext,
        size: CGSize,
        viewport: ViewPort,
        xStep: Double,
        yStep: Double
    ) {
        // Draw X grid lines (vertical lines)
        let firstX = ceil(viewport.xMin / xStep) * xStep
        let lastX = floor(viewport.xMax / xStep) * xStep
        
        var xValue = firstX
        while xValue <= lastX + (xStep / 10.0) {
            // Skip axis line itself to draw it later thicker
            if abs(xValue) > 1e-9 {
                let startPoint = viewport.toCanvas(xValue, viewport.yMax, size: size)
                let endPoint = viewport.toCanvas(xValue, viewport.yMin, size: size)
                
                var path = Path()
                path.move(to: startPoint)
                path.addLine(to: endPoint)
                
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(0.12)),
                    style: StrokeStyle(lineWidth: 1.0)
                )
            }
            xValue += xStep
        }
        
        // Draw Y grid lines (horizontal lines)
        let firstY = ceil(viewport.yMin / yStep) * yStep
        let lastY = floor(viewport.yMax / yStep) * yStep
        
        var yValue = firstY
        while yValue <= lastY + (yStep / 10.0) {
            if abs(yValue) > 1e-9 {
                let startPoint = viewport.toCanvas(viewport.xMin, yValue, size: size)
                let endPoint = viewport.toCanvas(viewport.xMax, yValue, size: size)
                
                var path = Path()
                path.move(to: startPoint)
                path.addLine(to: endPoint)
                
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(0.12)),
                    style: StrokeStyle(lineWidth: 1.0)
                )
            }
            yValue += yStep
        }
    }
    
    // MARK: - Axes Drawing
    private static func drawAxes(in context: GraphicsContext, size: CGSize, viewport: ViewPort) {
        var axesPath = Path()
        
        // Y-axis (where x = 0)
        if viewport.xMin <= 0 && viewport.xMax >= 0 {
            let start = viewport.toCanvas(0.0, viewport.yMax, size: size)
            let end = viewport.toCanvas(0.0, viewport.yMin, size: size)
            axesPath.move(to: start)
            axesPath.addLine(to: end)
        }
        
        // X-axis (where y = 0)
        if viewport.yMin <= 0 && viewport.yMax >= 0 {
            let start = viewport.toCanvas(viewport.xMin, 0.0, size: size)
            let end = viewport.toCanvas(viewport.xMax, 0.0, size: size)
            axesPath.move(to: start)
            axesPath.addLine(to: end)
        }
        
        context.stroke(
            axesPath,
            with: .color(Color.white.opacity(0.45)),
            style: StrokeStyle(lineWidth: 2.0)
        )
    }
    
    // MARK: - Labels Drawing
    private static func drawLabels(
        in context: GraphicsContext,
        size: CGSize,
        viewport: ViewPort,
        xStep: Double,
        yStep: Double
    ) {
        let labelColor = Color.white.opacity(0.65)
        let font = Font.system(size: 10, weight: .medium, design: .monospaced)
        
        // Determine label position for X axis (along y=0, clamped to edges if y=0 is offscreen)
        let canvasOrigin = viewport.toCanvas(0, 0, size: size)
        let xAxisY = min(max(canvasOrigin.y, 15), size.height - 15)
        
        // Draw X labels
        let firstX = ceil(viewport.xMin / xStep) * xStep
        let lastX = floor(viewport.xMax / xStep) * xStep
        
        var xValue = firstX
        while xValue <= lastX + (xStep / 10.0) {
            // Avoid drawing "0" twice or right on the intersection in an ugly way
            if abs(xValue) > 1e-9 {
                let canvasPos = viewport.toCanvas(xValue, 0, size: size)
                let labelText = formatLabelValue(xValue)
                
                var resolvedText = context.resolve(Text(labelText).font(font).foregroundColor(labelColor))
                let textSize = resolvedText.measure(in: size)
                
                context.draw(
                    resolvedText,
                    at: CGPoint(x: canvasPos.x, y: xAxisY + textSize.height / 2.0 + 2)
                )
            }
            xValue += xStep
        }
        
        // Determine label position for Y axis (along x=0, clamped to edges if x=0 is offscreen)
        let yAxisX = min(max(canvasOrigin.x, 25), size.width - 25)
        
        // Draw Y labels
        let firstY = ceil(viewport.yMin / yStep) * yStep
        let lastY = floor(viewport.yMax / yStep) * yStep
        
        var yValue = firstY
        while yValue <= lastY + (yStep / 10.0) {
            if abs(yValue) > 1e-9 {
                let canvasPos = viewport.toCanvas(0, yValue, size: size)
                let labelText = formatLabelValue(yValue)
                
                var resolvedText = context.resolve(Text(labelText).font(font).foregroundColor(labelColor))
                let textSize = resolvedText.measure(in: size)
                
                // Offset left or right depending on side of screen to avoid getting cut off
                let drawX = yAxisX - textSize.width / 2.0 - 6
                context.draw(
                    resolvedText,
                    at: CGPoint(x: drawX, y: canvasPos.y)
                )
            }
            yValue += yStep
        }
        
        // Draw origin "0"
        if viewport.xMin < 0 && viewport.xMax > 0 && viewport.yMin < 0 && viewport.yMax > 0 {
            var resolvedText = context.resolve(Text("0").font(font).foregroundColor(labelColor))
            context.draw(
                resolvedText,
                at: CGPoint(x: canvasOrigin.x - 8, y: canvasOrigin.y + 8)
            )
        }
    }
    
    private static func formatLabelValue(_ val: Double) -> String {
        let absVal = abs(val)
        if absVal >= 1e6 || (absVal > 0 && absVal < 1e-3) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .scientific
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: val)) ?? "\(val)"
        }
        
        // Round to avoid floating point display errors (e.g. 0.30000000000000004)
        let precision = 100000.0
        let rounded = round(val * precision) / precision
        
        if rounded == floor(rounded) {
            return String(format: "%.0f", rounded)
        } else {
            return "\(rounded)"
        }
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
                
                // Stroking with a nice glow/shadow
                var glowContext = context
                glowContext.addFilter(.shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 0))
                glowContext.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}
