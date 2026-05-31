//
//  SymbolicDifferentiator.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public struct SymbolicDifferentiator {
    
    public static func differentiate(_ node: ASTNode, respectTo variable: String = "x") -> ASTNode {
        let rawDerivative = diff(node, respectTo: variable)
        return simplifyFully(rawDerivative)
    }
    
    // MARK: - Core differentiation recursive logic
    private static func diff(_ node: ASTNode, respectTo variable: String) -> ASTNode {
        switch node {
        case .number(_):
            return .number(0)
            
        case .variable(let name):
            return name.lowercased() == variable.lowercased() ? .number(1) : .number(0)
            
        case .unary(let op, let operand):
            let dOperand = diff(operand, respectTo: variable)
            switch op {
            case .plus:
                return .unary(op: .plus, operand: dOperand)
            case .minus:
                return .unary(op: .minus, operand: dOperand)
            default:
                return .number(0)
            }
            
        case .binary(let op, let left, let right):
            let dLeft = diff(left, respectTo: variable)
            let dRight = diff(right, respectTo: variable)
            
            switch op {
            case .plus:
                return .binary(op: .plus, left: dLeft, right: dRight)
                
            case .minus:
                return .binary(op: .minus, left: dLeft, right: dRight)
                
            case .multiply:
                // (u * v)' = u' * v + u * v'
                let leftTerm = ASTNode.binary(op: .multiply, left: dLeft, right: right)
                let rightTerm = ASTNode.binary(op: .multiply, left: left, right: dRight)
                return .binary(op: .plus, left: leftTerm, right: rightTerm)
                
            case .divide:
                // (u / v)' = (u' * v - u * v') / v^2
                let numeratorLeft = ASTNode.binary(op: .multiply, left: dLeft, right: right)
                let numeratorRight = ASTNode.binary(op: .multiply, left: left, right: dRight)
                let numerator = ASTNode.binary(op: .minus, left: numeratorLeft, right: numeratorRight)
                let denominator = ASTNode.binary(op: .power, left: right, right: .number(2))
                return .binary(op: .divide, left: numerator, right: denominator)
                
            case .power:
                // General rule: (u^v)' = u^v * (v' * ln(u) + v * u' / u)
                // We optimize if either base or exponent is constant (derivative is 0)
                let isLeftConstant = isZero(dLeft)
                let isRightConstant = isZero(dRight)
                
                if isLeftConstant && isRightConstant {
                    return .number(0)
                } else if isRightConstant {
                    // Power Rule: (u^n)' = n * u^(n-1) * u'
                    let exponentMinusOne = ASTNode.binary(op: .minus, left: right, right: .number(1))
                    let newPower = ASTNode.binary(op: .power, left: left, right: exponentMinusOne)
                    let term = ASTNode.binary(op: .multiply, left: right, right: newPower)
                    return .binary(op: .multiply, left: term, right: dLeft)
                } else if isLeftConstant {
                    // Exponential Rule: (a^v)' = a^v * ln(a) * v'
                    let lnBase = ASTNode.function(name: "ln", args: [left])
                    let term1 = ASTNode.binary(op: .multiply, left: node, right: lnBase)
                    return .binary(op: .multiply, left: term1, right: dRight)
                } else {
                    // General case
                    let lnBase = ASTNode.function(name: "ln", args: [left])
                    let term1 = ASTNode.binary(op: .multiply, left: dRight, right: lnBase)
                    let term2 = ASTNode.binary(op: .multiply, left: right, right: dLeft)
                    let term2Divided = ASTNode.binary(op: .divide, left: term2, right: left)
                    let sum = ASTNode.binary(op: .plus, left: term1, right: term2Divided)
                    return .binary(op: .multiply, left: node, right: sum)
                }
                
            default:
                return .number(0)
            }
            
        case .function(let name, let args):
            guard let arg = args.first else { return .number(0) }
            let dArg = diff(arg, respectTo: variable)
            
            switch name.lowercased() {
            case "sin":
                // sin(u)' = cos(u) * u'
                let cosTerm = ASTNode.function(name: "cos", args: [arg])
                return .binary(op: .multiply, left: cosTerm, right: dArg)
                
            case "cos":
                // cos(u)' = -sin(u) * u'
                let sinTerm = ASTNode.function(name: "sin", args: [arg])
                let negSin = ASTNode.unary(op: .minus, operand: sinTerm)
                return .binary(op: .multiply, left: negSin, right: dArg)
                
            case "tan":
                // tan(u)' = (1 / cos(u)^2) * u'
                let cosTerm = ASTNode.function(name: "cos", args: [arg])
                let cosSquared = ASTNode.binary(op: .power, left: cosTerm, right: .number(2))
                let secSquared = ASTNode.binary(op: .divide, left: .number(1), right: cosSquared)
                return .binary(op: .multiply, left: secSquared, right: dArg)
                
            case "ln":
                // ln(u)' = (1 / u) * u'
                let inverse = ASTNode.binary(op: .divide, left: .number(1), right: arg)
                return .binary(op: .multiply, left: inverse, right: dArg)
                
            case "log10":
                // log10(u)' = (1 / (u * ln(10))) * u'
                let ln10 = ASTNode.function(name: "ln", args: [.number(10)])
                let denom = ASTNode.binary(op: .multiply, left: arg, right: ln10)
                let factor = ASTNode.binary(op: .divide, left: .number(1), right: denom)
                return .binary(op: .multiply, left: factor, right: dArg)
                
            case "exp":
                // exp(u)' = exp(u) * u'
                return .binary(op: .multiply, left: node, right: dArg)
                
            case "sqrt":
                // sqrt(u)' = (1 / (2 * sqrt(u))) * u'
                let twoSqrt = ASTNode.binary(op: .multiply, left: .number(2), right: node)
                let factor = ASTNode.binary(op: .divide, left: .number(1), right: twoSqrt)
                return .binary(op: .multiply, left: factor, right: dArg)
                
            case "abs":
                // abs(u)' = (u / abs(u)) * u'
                let factor = ASTNode.binary(op: .divide, left: arg, right: node)
                return .binary(op: .multiply, left: factor, right: dArg)
                
            default:
                return .number(0)
            }
        }
    }
    
    // MARK: - Simplification Helpers
    
    private static func isZero(_ node: ASTNode) -> Bool {
        if case .number(let val) = simplifyFully(node), val == 0 {
            return true
        }
        return false
    }
    
    private static func simplifyFully(_ node: ASTNode) -> ASTNode {
        var current = node
        var prevString = ""
        for _ in 0..<15 { // limit loop to prevent cyclic infinite recursion
            let curString = current.toString()
            if curString == prevString {
                break
            }
            prevString = curString
            current = simplify(current)
        }
        return current
    }
    
    private static func simplify(_ node: ASTNode) -> ASTNode {
        switch node {
        case .unary(let op, let operand):
            let sOperand = simplify(operand)
            switch (op, sOperand) {
            case (.plus, let val):
                return val
            case (.minus, .number(let val)):
                return .number(-val)
            case (.minus, .unary(.minus, let val)):
                return val
            default:
                return .unary(op: op, operand: sOperand)
            }
            
        case .binary(let op, let left, let right):
            let sLeft = simplify(left)
            let sRight = simplify(right)
            
            // Constant folding
            if case .number(let lVal) = sLeft, case .number(let rVal) = sRight {
                switch op {
                case .plus: return .number(lVal + rVal)
                case .minus: return .number(lVal - rVal)
                case .multiply: return .number(lVal * rVal)
                case .divide: return rVal == 0 ? .binary(op: op, left: sLeft, right: sRight) : .number(lVal / rVal)
                case .power: return .number(Foundation.pow(lVal, rVal))
                default: break
                }
            }
            
            switch op {
            case .plus:
                if case .number(0) = sLeft { return sRight }
                if case .number(0) = sRight { return sLeft }
            case .minus:
                if case .number(0) = sRight { return sLeft }
                if case .number(0) = sLeft { return .unary(op: .minus, operand: sRight) }
            case .multiply:
                if case .number(0) = sLeft { return .number(0) }
                if case .number(0) = sRight { return .number(0) }
                if case .number(1) = sLeft { return sRight }
                if case .number(1) = sRight { return sLeft }
            case .divide:
                if case .number(0) = sLeft { return .number(0) }
                if case .number(1) = sRight { return sLeft }
            case .power:
                if case .number(0) = sRight { return .number(1) }
                if case .number(1) = sRight { return sLeft }
                if case .number(0) = sLeft { return .number(0) }
                if case .number(1) = sLeft { return .number(1) }
            default:
                break
            }
            
            return .binary(op: op, left: sLeft, right: sRight)
            
        case .function(let name, let args):
            let sArgs = args.map { simplify($0) }
            return .function(name: name, args: sArgs)
            
        default:
            return node
        }
    }
}
