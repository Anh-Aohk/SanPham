//
//  GraphViewModel.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation
import Observation
import CoreGraphics

@Observable
public final class GraphViewModel {
    // MARK: - State Properties
    public var functions: [FunctionModel] = []
    public var viewport: ViewPort = ViewPort()
    public var mode: GraphMode = .cartesian {
        didSet {
            if mode != oldValue {
                resetViewportForMode()
            }
        }
    }
    public var angleMode: AngleMode = .radian
    
    // Cache for parsed ASTs to avoid re-parsing during rendering cycles
    private var astCache: [UUID: ASTNode] = [:]
    
    // Tracks parse errors for functions
    public var functionErrors: [UUID: String] = [:]
    
    // Preset colors for easy picking
    public static let presetColors: [RGBAColor] = [
        RGBAColor(red: 0.9, green: 0.2, blue: 0.2), // Red
        RGBAColor(red: 0.2, green: 0.4, blue: 0.8), // Blue
        RGBAColor(red: 0.2, green: 0.7, blue: 0.3), // Green
        RGBAColor(red: 0.6, green: 0.2, blue: 0.8), // Purple
        RGBAColor(red: 0.9, green: 0.5, blue: 0.1)  // Orange
    ]
    
    // MARK: - Initialization
    public init() {
        // Populate with a default function so the app is immediately alive
        addFunction(expression: "x^2", color: Self.presetColors[0])
    }
    
    // MARK: - Function Management
    public func addFunction(expression: String = "", color: RGBAColor? = nil, isPolar: Bool = false) {
        let selectedColor = color ?? Self.presetColors[functions.count % Self.presetColors.count]
        let newFunction = FunctionModel(
            expression: expression,
            color: selectedColor,
            isVisible: true,
            isPolar: isPolar
        )
        functions.append(newFunction)
        parseAndCache(newFunction)
    }
    
    public func removeFunction(at index: Int) {
        let function = functions[index]
        astCache.removeValue(forKey: function.id)
        functionErrors.removeValue(forKey: function.id)
        functions.remove(at: index)
    }
    
    public func removeFunction(id: UUID) {
        if let index = functions.firstIndex(where: { $0.id == id }) {
            removeFunction(at: index)
        }
    }
    
    public func updateFunctionExpression(id: UUID, newExpression: String) {
        guard let index = functions.firstIndex(where: { $0.id == id }) else { return }
        functions[index].expression = newExpression
        parseAndCache(functions[index])
    }
    
    public func toggleFunctionVisibility(id: UUID) {
        guard let index = functions.firstIndex(where: { $0.id == id }) else { return }
        functions[index].isVisible.toggle()
    }
    
    public func toggleFunctionPolar(id: UUID) {
        guard let index = functions.firstIndex(where: { $0.id == id }) else { return }
        functions[index].isPolar.toggle()
        parseAndCache(functions[index])
    }
    
    public var lastCanvasSize: CGSize = .zero
    
    public func updateCanvasSize(_ size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        if lastCanvasSize != size {
            lastCanvasSize = size
            adjustViewportAspectRatio()
        }
    }
    
    public func adjustViewportAspectRatio() {
        guard lastCanvasSize.width > 0 && lastCanvasSize.height > 0 else { return }
        viewport = viewport.adjustedToAspectRatio(for: lastCanvasSize)
    }
    
    // MARK: - ViewPort Actions
    public func resetViewportForMode() {
        switch mode {
        case .cartesian:
            viewport = ViewPort(xMin: -10, xMax: 10, yMin: -6, yMax: 6)
        case .polar:
            // Polar viewport benefits from a square/symmetrical viewport
            viewport = ViewPort(xMin: -8, xMax: 8, yMin: -8, yMax: 8)
        }
        adjustViewportAspectRatio()
    }
    
    public func zoom(scale: Double, center: CGPoint, size: CGSize) {
        updateCanvasSize(size)
        let (mathX, mathY) = viewport.toMath(center, size: size)
        
        let xHalfSpan = (viewport.xMax - viewport.xMin) / 2.0 * scale
        let yHalfSpan = (viewport.yMax - viewport.yMin) / 2.0 * scale
        
        viewport.xMin = mathX - xHalfSpan
        viewport.xMax = mathX + xHalfSpan
        viewport.yMin = mathY - yHalfSpan
        viewport.yMax = mathY + yHalfSpan
    }
    
    public func pan(translation: CGSize, size: CGSize) {
        updateCanvasSize(size)
        let xSpan = viewport.xMax - viewport.xMin
        let ySpan = viewport.yMax - viewport.yMin
        
        let dx = (Double(translation.width) / Double(size.width)) * xSpan
        let dy = (Double(translation.height) / Double(size.height)) * ySpan
        
        viewport.xMin -= dx
        viewport.xMax -= dx
        viewport.yMin += dy
        viewport.yMax += dy
    }
    
    // MARK: - Parser Integration & Point Generation
    private func parseAndCache(_ function: FunctionModel) {
        let cleaned = function.expression.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            astCache.removeValue(forKey: function.id)
            functionErrors.removeValue(forKey: function.id)
            return
        }
        
        do {
            let lexer = Lexer()
            let parser = ExpressionParser()
            let tokens = try lexer.tokenize(cleaned)
            let ast = try parser.parse(tokens)
            astCache[function.id] = ast
            functionErrors.removeValue(forKey: function.id)
        } catch {
            astCache.removeValue(forKey: function.id)
            functionErrors[function.id] = error.localizedDescription
        }
    }
    
    public func getAST(for id: UUID) -> ASTNode? {
        return astCache[id]
    }
    
    /// Generates point paths for drawing Cartesian and Polar functions.
    /// Returns an array of continuous segment arrays of CGPoints (separated by non-finite gaps)
    public func generatePaths(for function: FunctionModel, size: CGSize) -> [[CGPoint]] {
        guard function.isVisible, let ast = astCache[function.id] else { return [] }
        
        if function.isPolar {
            return generatePolarPaths(ast: ast, size: size)
        } else {
            return generateCartesianPaths(ast: ast, size: size)
        }
    }
    
    private func generateCartesianPaths(ast: ASTNode, size: CGSize) -> [[CGPoint]] {
        var paths: [[CGPoint]] = []
        var currentSegment: [CGPoint] = []
        
        let widthPoints = Int(size.width)
        let stepCount = max(200, min(1000, widthPoints)) // Use screen width as resolution baseline
        
        let xMin = viewport.xMin
        let xMax = viewport.xMax
        let xSpan = xMax - xMin
        
        for i in 0...stepCount {
            let t = Double(i) / Double(stepCount)
            let x = xMin + t * xSpan
            
            let y = Evaluator.evaluate(ast, x: x, angleMode: angleMode)
            
            if y.isFinite && !y.isNaN {
                let canvasPoint = viewport.toCanvas(x, y, size: size)
                currentSegment.append(canvasPoint)
            } else {
                if !currentSegment.isEmpty {
                    paths.append(currentSegment)
                    currentSegment = []
                }
            }
        }
        
        if !currentSegment.isEmpty {
            paths.append(currentSegment)
        }
        
        return paths
    }
    
    private func generatePolarPaths(ast: ASTNode, size: CGSize) -> [[CGPoint]] {
        var paths: [[CGPoint]] = []
        var currentSegment: [CGPoint] = []
        
        // 1500 steps as specified by Sprint 5 roadmap
        let stepCount = 1500
        let maxTheta = 2.0 * Double.pi
        
        for i in 0...stepCount {
            let theta = (Double(i) / Double(stepCount)) * maxTheta
            
            // Evaluates r = f(theta) where theta is passed as the 'x' variable context
            let r = Evaluator.evaluate(ast, x: theta, angleMode: angleMode)
            
            if r.isFinite && !r.isNaN {
                let x = r * Foundation.cos(theta)
                let y = r * Foundation.sin(theta)
                let canvasPoint = viewport.toCanvas(x, y, size: size)
                currentSegment.append(canvasPoint)
            } else {
                if !currentSegment.isEmpty {
                    paths.append(currentSegment)
                    currentSegment = []
                }
            }
        }
        
        if !currentSegment.isEmpty {
            paths.append(currentSegment)
        }
        
        return paths
    }
}
