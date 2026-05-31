//
//  SymbolicIntegrator.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public enum IntegrationError: Error, LocalizedError {
    case unsupportedExpression(String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedExpression(let expr):
            return "Cannot integrate symbolically: \(expr)"
        }
    }
}

public struct SymbolicIntegrator {
    
    public static func integrate(_ node: ASTNode, respectTo variable: String = "x") -> Result<ASTNode, IntegrationError> {
        do {
            let rawIntegral = try int(node, respectTo: variable)
            let simplified = simplifyFully(rawIntegral)
            return .success(simplified)
        } catch {
            return .failure(.unsupportedExpression(node.toString()))
        }
    }
    
    // MARK: - Core integration recursive logic
    private static func int(_ node: ASTNode, respectTo variable: String) throws -> ASTNode {
        // Rule 1: Node is independent of variable -> constant integration: c * x
        if !containsVariable(node, variable: variable) {
            return .binary(op: .multiply, left: node, right: .variable(variable))
        }
        
        switch node {
        case .variable(let name):
            // Since containsVariable is true and it's a variable node, it must be the variable of integration
            if name.lowercased() == variable.lowercased() {
                // Integral of x is (x^2) / 2
                let powerNode = ASTNode.binary(op: .power, left: node, right: .number(2))
                return .binary(op: .divide, left: powerNode, right: .number(2))
            }
            throw IntegrationError.unsupportedExpression(node.toString())
            
        case .unary(let op, let operand):
            let intOperand = try int(operand, respectTo: variable)
            switch op {
            case .plus:
                return .unary(op: .plus, operand: intOperand)
            case .minus:
                return .unary(op: .minus, operand: intOperand)
            default:
                throw IntegrationError.unsupportedExpression(node.toString())
            }
            
        case .binary(let op, let left, let right):
            switch op {
            case .plus:
                let lInt = try int(left, respectTo: variable)
                let rInt = try int(right, respectTo: variable)
                return .binary(op: .plus, left: lInt, right: rInt)
                
            case .minus:
                let lInt = try int(left, respectTo: variable)
                let rInt = try int(right, respectTo: variable)
                return .binary(op: .minus, left: lInt, right: rInt)
                
            case .multiply:
                // Constant coefficient rule: c * f(x) -> c * F(x)
                if !containsVariable(left, variable: variable) {
                    let rInt = try int(right, respectTo: variable)
                    return .binary(op: .multiply, left: left, right: rInt)
                } else if !containsVariable(right, variable: variable) {
                    let lInt = try int(left, respectTo: variable)
                    return .binary(op: .multiply, left: lInt, right: right)
                }
                throw IntegrationError.unsupportedExpression(node.toString())
                
            case .divide:
                // Division by constant: f(x) / c -> F(x) / c
                if !containsVariable(right, variable: variable) {
                    let lInt = try int(left, respectTo: variable)
                    return .binary(op: .divide, left: lInt, right: right)
                }
                // Integral of c / x -> c * ln(abs(x))
                if !containsVariable(left, variable: variable) && isVariableX(right, variable: variable) {
                    let absNode = ASTNode.function(name: "abs", args: [right])
                    let lnAbs = ASTNode.function(name: "ln", args: [absNode])
                    return .binary(op: .multiply, left: left, right: lnAbs)
                }
                throw IntegrationError.unsupportedExpression(node.toString())
                
            case .power:
                // Integral of x^n -> (x^(n+1)) / (n+1) for n != -1
                if isVariableX(left, variable: variable) && !containsVariable(right, variable: variable) {
                    let n = Evaluator.evaluate(right, x: 0, angleMode: .radian)
                    if n == -1 {
                        // 1/x -> ln(abs(x))
                        let absNode = ASTNode.function(name: "abs", args: [left])
                        return .function(name: "ln", args: [absNode])
                    } else {
                        let newExponent = n + 1
                        let numerator = ASTNode.binary(op: .power, left: left, right: .number(newExponent))
                        return .binary(op: .divide, left: numerator, right: .number(newExponent))
                    }
                }
                // Integral of a^x -> a^x / ln(a)
                if !containsVariable(left, variable: variable) && isVariableX(right, variable: variable) {
                    let baseVal = Evaluator.evaluate(left, x: 0, angleMode: .radian)
                    if baseVal > 0 && baseVal != 1 {
                        let lnBase = ASTNode.function(name: "ln", args: [left])
                        return .binary(op: .divide, left: node, right: lnBase)
                    }
                }
                throw IntegrationError.unsupportedExpression(node.toString())
                
            default:
                throw IntegrationError.unsupportedExpression(node.toString())
            }
            
        case .function(let name, let args):
            guard args.count == 1, let arg = args.first else {
                throw IntegrationError.unsupportedExpression(node.toString())
            }
            
            // We only support trigonometric/exponential functions where the argument is exactly x
            if isVariableX(arg, variable: variable) {
                switch name.lowercased() {
                case "sin":
                    // Integral of sin(x) -> -cos(x)
                    let cosNode = ASTNode.function(name: "cos", args: [arg])
                    return .unary(op: .minus, operand: cosNode)
                case "cos":
                    // Integral of cos(x) -> sin(x)
                    return .function(name: "sin", args: [arg])
                case "exp":
                    // Integral of e^x -> e^x
                    return node
                default:
                    throw IntegrationError.unsupportedExpression(node.toString())
                }
            }
            throw IntegrationError.unsupportedExpression(node.toString())
            
        default:
            throw IntegrationError.unsupportedExpression(node.toString())
        }
    }
    
    // MARK: - Helper Methods
    
    private static func containsVariable(_ node: ASTNode, variable: String) -> Bool {
        switch node {
        case .number(_):
            return false
        case .variable(let name):
            return name.lowercased() == variable.lowercased()
        case .unary(_, let operand):
            return containsVariable(operand, variable: variable)
        case .binary(_, let left, let right):
            return containsVariable(left, variable: variable) || containsVariable(right, variable: variable)
        case .function(_, let args):
            return args.contains { containsVariable($0, variable: variable) }
        }
    }
    
    private static func isVariableX(_ node: ASTNode, variable: String) -> Bool {
        if case .variable(let name) = node, name.lowercased() == variable.lowercased() {
            return true
        }
        return false
    }
    
    private static func simplifyFully(_ node: ASTNode) -> ASTNode {
        var current = node
        var prevString = ""
        for _ in 0..<15 {
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
            let sArgs = args.map { simplify( $0) }
            return .function(name: name, args: sArgs)
            
        default:
            return node
        }
    }
}
