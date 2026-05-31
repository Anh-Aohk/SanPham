//
//  AnalysisViewModel.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation
import Observation

@Observable
public final class AnalysisViewModel {
    
    // MARK: - State
    
    /// The function currently being analyzed
    public var selectedFunctionId: UUID? = nil
    
    /// Derivative tab input: "x" or empty → symbolic; a number → numeric at point
    public var derivativeInput: String = ""
    
    /// Integral tab bounds: if both present → definite integral; otherwise → antiderivative
    public var integralBoundA: String = ""
    public var integralBoundB: String = ""
    
    /// Evaluate at point input
    public var evaluateAtInput: String = ""
    
    /// Latest analysis results
    public var results: [AnalysisResult] = []
    
    /// Error message if analysis fails
    public var errorMessage: String? = nil
    
    // MARK: - Routing Logic
    
    /// Evaluate f(a): parse input as Double → compute f(a)
    public func evaluateAtPoint(ast: ASTNode, angleMode: AngleMode) {
        guard let a = Double(evaluateAtInput) else {
            errorMessage = "Please enter a valid number for x"
            return
        }
        errorMessage = nil
        let y = Evaluator.evaluate(ast, x: a, angleMode: angleMode)
        results.append(.value(x: a, y: y))
    }
    
    /// Derivative: dual-mode routing
    /// - Input is a number → evaluate f'(a) numerically
    /// - Input is "x", empty, or non-numeric → return symbolic f'(x)
    public func computeDerivative(ast: ASTNode, angleMode: AngleMode) {
        errorMessage = nil
        let trimmed = derivativeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let a = Double(trimmed) {
            // Numeric: evaluate f'(a) using the symbolic derivative
            let diffAst = SymbolicDifferentiator.differentiate(ast)
            let value = Evaluator.evaluate(diffAst, x: a, angleMode: angleMode)
            results.append(.derivativeAtPoint(x: a, result: value))
        } else {
            // Symbolic: return f'(x) as expression string
            let diffAst = SymbolicDifferentiator.differentiate(ast)
            results.append(.derivativeSymbolic(expression: diffAst.toString()))
        }
    }
    
    /// Integral: dual-mode routing
    /// - Both bounds present → definite integral via Simpson's rule
    /// - Either bound empty → symbolic antiderivative F(x) + C
    public func computeIntegral(ast: ASTNode, angleMode: AngleMode) {
        errorMessage = nil
        let trimA = integralBoundA.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimB = integralBoundB.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let a = Double(trimA), let b = Double(trimB) {
            // Definite integral: Simpson's rule
            let area = NumericsEngine.integrate(ast, from: a, to: b, steps: 1000, angleMode: angleMode)
            results.append(.integral(a: a, b: b, result: area))
        } else {
            // Symbolic antiderivative
            switch SymbolicIntegrator.integrate(ast) {
            case .success(let intAst):
                results.append(.antiderivative(expression: intAst.toString() + " + C"))
            case .failure(let error):
                errorMessage = "Symbolic integration failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Find roots of f(x) = 0 in the given viewport range
    public func findRoots(ast: ASTNode, in range: ClosedRange<Double>, angleMode: AngleMode) {
        errorMessage = nil
        let roots = NumericsEngine.findRoots(of: ast, in: range, angleMode: angleMode)
        results.append(.roots(roots))
    }
    
    /// Clear all results
    public func clearResults() {
        results.removeAll()
        errorMessage = nil
    }
}
