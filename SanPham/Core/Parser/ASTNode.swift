//
//  ASTNode.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public enum BinaryOp: String, Codable {
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case power = "^"
}

public enum UnaryOp: String, Codable {
    case plus = "+"
    case minus = "-"
}

public indirect enum ASTNode: Equatable {
    case number(Double)
    case variable(String)
    case binary(op: BinaryOp, left: ASTNode, right: ASTNode)
    case unary(op: UnaryOp, operand: ASTNode)
    case function(name: String, args: [ASTNode])
    
    private func precedence() -> Int {
        switch self {
        case .number, .variable, .function:
            return 5
        case .unary:
            return 4
        case .binary(let op, _, _):
            switch op {
            case .power:
                return 3
            case .multiply, .divide:
                return 2
            case .plus, .minus:
                return 1
            }
        }
    }
    
    public func toString() -> String {
        switch self {
        case .number(let val):
            if val.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(val))
            } else {
                return String(val)
            }
        case .variable(let name):
            return name
        case .unary(let op, let operand):
            let opStr = op.rawValue
            let operandStr = operand.toString()
            if operand.precedence() < 4 {
                return "\(opStr)(\(operandStr))"
            } else {
                return "\(opStr)\(operandStr)"
            }
        case .binary(let op, let left, let right):
            let myPrec = self.precedence()
            
            var leftStr = left.toString()
            if left.precedence() < myPrec {
                leftStr = "(\(leftStr))"
            }
            
            var rightStr = right.toString()
            let rightPrec = right.precedence()
            let needsRightParen: Bool
            if rightPrec < myPrec {
                needsRightParen = true
            } else if rightPrec == myPrec {
                switch op {
                case .minus, .divide, .power:
                    needsRightParen = true
                case .plus, .multiply:
                    needsRightParen = false
                }
            } else {
                needsRightParen = false
            }
            
            if needsRightParen {
                rightStr = "(\(rightStr))"
            }
            
            return "\(leftStr) \(op.rawValue) \(rightStr)"
        case .function(let name, let args):
            let argStrings = args.map { $0.toString() }
            return "\(name)(\(argStrings.joined(separator: ", ")))"
        }
    }
}
