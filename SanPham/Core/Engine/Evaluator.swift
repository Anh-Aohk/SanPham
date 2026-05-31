//
//  Evaluator.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public struct Evaluator {
    
    public static func evaluate(_ node: ASTNode, x: Double, angleMode: AngleMode) -> Double {
        switch node {
        case .number(let value):
            return value
            
        case .variable(let name):
            let lower = name.lowercased()
            if lower == "pi" || lower == "π" {
                return Double.pi
            } else if lower == "e" {
                return Foundation.exp(1.0)
            } else {
                // Any other variable (like x, t, theta) evaluates to the input parameter x
                return x
            }
            
        case .unary(let op, let operand):
            let val = evaluate(operand, x: x, angleMode: angleMode)
            switch op {
            case .plus:
                return val
            case .minus:
                return -val
            default:
                return .nan
            }
            
        case .binary(let op, let left, let right):
            let lVal = evaluate(left, x: x, angleMode: angleMode)
            let rVal = evaluate(right, x: x, angleMode: angleMode)
            switch op {
            case .plus:
                return lVal + rVal
            case .minus:
                return lVal - rVal
            case .multiply:
                return lVal * rVal
            case .divide:
                if rVal == 0 {
                    return .nan
                }
                return lVal / rVal
            case .power:
                // Special case for standard Swift pow: negative base with non-integer exponent returns nan
                return Foundation.pow(lVal, rVal)
            default:
                return .nan
            }
            
        case .function(let name, let args):
            guard let firstNode = args.first else { return .nan }
            let val = evaluate(firstNode, x: x, angleMode: angleMode)
            
            switch name.lowercased() {
            case "sin":
                let rad = angleMode == .radian ? val : (val * .pi / 180.0)
                return Foundation.sin(rad)
            case "cos":
                let rad = angleMode == .radian ? val : (val * .pi / 180.0)
                return Foundation.cos(rad)
            case "tan":
                let rad = angleMode == .radian ? val : (val * .pi / 180.0)
                // For tan, if it is close to odd multiples of pi/2, it should ideally go to infinity/nan, but standard tan will handle it.
                return Foundation.tan(rad)
            case "ln":
                return Foundation.log(val)
            case "log10":
                return Foundation.log10(val)
            case "exp":
                return Foundation.exp(val)
            case "sqrt":
                return Foundation.sqrt(val)
            case "abs":
                return abs(val)
            default:
                return .nan
            }
        }
    }
}
