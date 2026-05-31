//
//  ExpressionParser.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public enum ParserError: Error, LocalizedError {
    case unexpectedToken(Token)
    case missingOperand
    case mismatchedParentheses
    case emptyExpression
    case invalidFunctionArguments(String)
    
    public var errorDescription: String? {
        switch self {
        case .unexpectedToken(let token):
            return "Unexpected token: '\(token)'"
        case .missingOperand:
            return "Missing operand in expression"
        case .mismatchedParentheses:
            return "Mismatched parentheses"
        case .emptyExpression:
            return "Expression is empty"
        case .invalidFunctionArguments(let msg):
            return "Invalid arguments for function: \(msg)"
        }
    }
}

public struct ExpressionParser {
    public init() {}
    
    public func parse(_ tokens: [Token]) throws -> ASTNode {
        var index = 0
        
        func peek() -> Token? {
            guard index < tokens.count else { return nil }
            return tokens[index]
        }
        
        func consume() -> Token? {
            guard index < tokens.count else { return nil }
            let t = tokens[index]
            index += 1
            return t
        }
        
        func parseExpression() throws -> ASTNode {
            return try parseAddition()
        }
        
        func parseAddition() throws -> ASTNode {
            var node = try parseMultiplication()
            while let token = peek() {
                if token == .plus {
                    _ = consume()
                    let right = try parseMultiplication()
                    node = .binary(op: .plus, left: node, right: right)
                } else if token == .minus {
                    _ = consume()
                    let right = try parseMultiplication()
                    node = .binary(op: .minus, left: node, right: right)
                } else {
                    break
                }
            }
            return node
        }
        
        func parseMultiplication() throws -> ASTNode {
            var node = try parseUnary()
            while let token = peek() {
                if token == .multiply {
                    _ = consume()
                    let right = try parseUnary()
                    node = .binary(op: .multiply, left: node, right: right)
                } else if token == .divide {
                    _ = consume()
                    let right = try parseUnary()
                    node = .binary(op: .divide, left: node, right: right)
                } else {
                    break
                }
            }
            return node
        }
        
        func parseUnary() throws -> ASTNode {
            if let token = peek() {
                if token == .plus {
                    _ = consume()
                    let operand = try parseUnary()
                    return .unary(op: .plus, operand: operand)
                } else if token == .minus {
                    _ = consume()
                    let operand = try parseUnary()
                    return .unary(op: .minus, operand: operand)
                }
            }
            return try parsePower()
        }
        
        func parsePower() throws -> ASTNode {
            var node = try parsePrimary()
            if let token = peek(), token == .power {
                _ = consume()
                let rightPower = try parsePower()
                node = .binary(op: .power, left: node, right: rightPower)
            }
            return node
        }
        
        func parsePrimary() throws -> ASTNode {
            guard let token = consume() else {
                throw ParserError.missingOperand
            }
            
            switch token {
            case .number(let val):
                return .number(val)
            case .variable(let name):
                return .variable(name)
            case .function(let name):
                guard let next = peek(), next == .leftParenthesis else {
                    throw ParserError.unexpectedToken(token)
                }
                _ = consume() // consume '('
                
                var args: [ASTNode] = []
                if peek() != .rightParenthesis {
                    args.append(try parseExpression())
                    while let next = peek(), next == .comma {
                        _ = consume() // consume ','
                        args.append(try parseExpression())
                    }
                }
                
                guard let closing = consume(), closing == .rightParenthesis else {
                    throw ParserError.mismatchedParentheses
                }
                
                return .function(name: name, args: args)
                
            case .leftParenthesis:
                let expr = try parseExpression()
                guard let closing = consume(), closing == .rightParenthesis else {
                    throw ParserError.mismatchedParentheses
                }
                return expr
                
            default:
                throw ParserError.unexpectedToken(token)
            }
        }
        
        if tokens.isEmpty {
            throw ParserError.emptyExpression
        }
        
        let root = try parseExpression()
        
        if index < tokens.count {
            throw ParserError.unexpectedToken(tokens[index])
        }
        
        return root
    }
}
