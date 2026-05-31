//
//  Lexer.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public enum LexerError: Error, LocalizedError {
    case invalidCharacter(Character)
    case invalidNumber(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCharacter(let char):
            return "Invalid character in expression: '\(char)'"
        case .invalidNumber(let str):
            return "Invalid number format: '\(str)'"
        }
    }
}

public struct Lexer {
    private static let functions: Set<String> = [
        "sin", "cos", "tan", "ln", "log10", "exp", "sqrt", "abs"
    ]
    
    public init() {}
    
    public func tokenize(_ input: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(input)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if char.isWhitespace {
                i += 1
                continue
            }
            
            switch char {
            case "+":
                tokens.append(.plus)
                i += 1
                continue
            case "-":
                tokens.append(.minus)
                i += 1
                continue
            case "*":
                tokens.append(.multiply)
                i += 1
                continue
            case "/":
                tokens.append(.divide)
                i += 1
                continue
            case "^":
                tokens.append(.power)
                i += 1
                continue
            case "(":
                tokens.append(.leftParenthesis)
                i += 1
                continue
            case ")":
                tokens.append(.rightParenthesis)
                i += 1
                continue
            case ",":
                tokens.append(.comma)
                i += 1
                continue
            default:
                break
            }
            
            if char.isNumber || char == "." {
                var numStr = ""
                var hasDecimalSeparator = false
                
                while i < chars.count {
                    let c = chars[i]
                    if c.isNumber {
                        numStr.append(c)
                        i += 1
                    } else if c == "." {
                        if hasDecimalSeparator {
                            throw LexerError.invalidNumber(numStr + ".")
                        }
                        hasDecimalSeparator = true
                        numStr.append(c)
                        i += 1
                    } else {
                        break
                    }
                }
                
                guard let val = Double(numStr) else {
                    throw LexerError.invalidNumber(numStr)
                }
                tokens.append(.number(val))
                continue
            }
            
            if char.isLetter {
                var identStr = ""
                while i < chars.count && (chars[i].isLetter || chars[i].isNumber) {
                    identStr.append(chars[i])
                    i += 1
                }
                
                if Self.functions.contains(identStr) {
                    tokens.append(.function(identStr))
                } else {
                    tokens.append(.variable(identStr))
                }
                continue
            }
            
            throw LexerError.invalidCharacter(char)
        }
        
        return tokens
    }
}
