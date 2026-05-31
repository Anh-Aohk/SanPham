//
//  NumericsEngine.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public struct NumericsEngine {
    
    /// Finds roots (f(x) = 0) of the expression within a given range using the Bisection method.
    public static func findRoots(
        of ast: ASTNode,
        in range: ClosedRange<Double>,
        steps: Int = 100,
        angleMode: AngleMode
    ) -> [Double] {
        var roots: [Double] = []
        let stepSize = (range.upperBound - range.lowerBound) / Double(steps)
        
        func bisection(left: Double, right: Double) -> Double? {
            var a = left
            var b = right
            var fa = Evaluator.evaluate(ast, x: a, angleMode: angleMode)
            var fb = Evaluator.evaluate(ast, x: b, angleMode: angleMode)
            
            if fa.isNaN || fb.isNaN || fa.isInfinite || fb.isInfinite {
                return nil
            }
            
            // If signs are not opposite, no root (or even number of roots) in this subinterval
            if fa * fb > 0 {
                return nil
            }
            
            for _ in 0..<40 {
                let mid = (a + b) / 2.0
                let fmid = Evaluator.evaluate(ast, x: mid, angleMode: angleMode)
                
                if fmid.isNaN || fmid.isInfinite {
                    return nil
                }
                
                if abs(fmid) < 1e-10 || abs(b - a) < 1e-8 {
                    return mid
                }
                
                if fa * fmid < 0 {
                    b = mid
                    fb = fmid
                } else {
                    a = mid
                    fa = fmid
                }
            }
            return (a + b) / 2.0
        }
        
        // Scan the intervals
        for i in 0..<steps {
            let x1 = range.lowerBound + Double(i) * stepSize
            let x2 = x1 + stepSize
            
            if let root = bisection(left: x1, right: x2) {
                if !roots.contains(where: { abs($0 - root) < 1e-5 }) {
                    roots.append(root)
                }
            }
            
            // Check exact boundary points as roots
            let fx1 = Evaluator.evaluate(ast, x: x1, angleMode: angleMode)
            if abs(fx1) < 1e-10 {
                if !roots.contains(where: { abs($0 - x1) < 1e-5 }) {
                    roots.append(x1)
                }
            }
        }
        
        // Check final boundary point
        let fxEnd = Evaluator.evaluate(ast, x: range.upperBound, angleMode: angleMode)
        if abs(fxEnd) < 1e-10 {
            if !roots.contains(where: { abs($0 - range.upperBound) < 1e-5 }) {
                roots.append(range.upperBound)
            }
        }
        
        return roots.sorted()
    }
    
    /// Computes the definite integral of the expression from a to b using Simpson's Rule.
    public static func integrate(
        _ ast: ASTNode,
        from a: Double,
        to b: Double,
        steps: Int = 1000,
        angleMode: AngleMode
    ) -> Double {
        // Simpson's rule requires an even number of steps
        let n = steps % 2 == 0 ? steps : steps + 1
        let h = (b - a) / Double(n)
        
        var fa = Evaluator.evaluate(ast, x: a, angleMode: angleMode)
        var fb = Evaluator.evaluate(ast, x: b, angleMode: angleMode)
        
        if fa.isNaN || fa.isInfinite { fa = 0.0 }
        if fb.isNaN || fb.isInfinite { fb = 0.0 }
        
        var sum = fa + fb
        
        for i in 1..<n {
            let x = a + Double(i) * h
            var fx = Evaluator.evaluate(ast, x: x, angleMode: angleMode)
            
            if fx.isNaN || fx.isInfinite {
                fx = 0.0 // Treat singular points gracefully
            }
            
            let coef = (i % 2 == 0) ? 2.0 : 4.0
            sum += coef * fx
        }
        
        return (h / 3.0) * sum
    }
}
