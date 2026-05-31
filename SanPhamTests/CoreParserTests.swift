//
//  CoreParserTests.swift
//  SanPhamTests
//
//  Created by Antigravity on 31/05/2026.
//

import XCTest
// Since we are compiling directly or using standard test targets, we import the classes.
// In a standard test target, we would use @testable import SanPham.

class CoreParserTests: XCTestCase {
    
    // MARK: - Lexer Tests
    
    func testLexerHappyPath() throws {
        let lexer = Lexer()
        let tokens = try lexer.tokenize("sin(x) + 2.5 * x^2")
        
        let expected: [Token] = [
            .function("sin"),
            .leftParenthesis,
            .variable("x"),
            .rightParenthesis,
            .plus,
            .number(2.5),
            .multiply,
            .variable("x"),
            .power,
            .number(2)
        ]
        
        XCTAssertEqual(tokens, expected)
    }
    
    func testLexerEdgeCases() throws {
        let lexer = Lexer()
        
        // Decimals starting with dot
        let tokens1 = try lexer.tokenize(".5")
        XCTAssertEqual(tokens1, [.number(0.5)])
        
        // Whitespaces
        let tokens2 = try lexer.tokenize("  x   +   y  ")
        XCTAssertEqual(tokens2, [.variable("x"), .plus, .variable("y")])
    }
    
    func testLexerErrors() {
        let lexer = Lexer()
        
        XCTAssertThrowsError(try lexer.tokenize("x @ y")) { error in
            if let lexerError = error as? LexerError {
                switch lexerError {
                case .invalidCharacter(let char):
                    XCTAssertEqual(char, "@")
                default:
                    XCTFail("Unexpected error type")
                }
            } else {
                XCTFail("Unexpected error type")
            }
        }
        
        XCTAssertThrowsError(try lexer.tokenize("1.2.3")) { error in
            if let lexerError = error as? LexerError {
                switch lexerError {
                case .invalidNumber(let str):
                    XCTAssertEqual(str, "1.2.")
                default:
                    XCTFail("Unexpected error type")
                }
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    // MARK: - Parser Tests
    
    func testParserPrecedence() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // x + y * z  =>  x + (y * z)
        let tokens1 = try lexer.tokenize("x + y * z")
        let ast1 = try parser.parse(tokens1)
        let expected1 = ASTNode.binary(
            op: .plus,
            left: .variable("x"),
            right: .binary(op: .multiply, left: .variable("y"), right: .variable("z"))
        )
        XCTAssertEqual(ast1, expected1)
        
        // x * y + z  =>  (x * y) + z
        let tokens2 = try lexer.tokenize("x * y + z")
        let ast2 = try parser.parse(tokens2)
        let expected2 = ASTNode.binary(
            op: .plus,
            left: .binary(op: .multiply, left: .variable("x"), right: .variable("y")),
            right: .variable("z")
        )
        XCTAssertEqual(ast2, expected2)
        
        // x ^ y ^ z  =>  x ^ (y ^ z) (right-associative)
        let tokens3 = try lexer.tokenize("x ^ y ^ z")
        let ast3 = try parser.parse(tokens3)
        let expected3 = ASTNode.binary(
            op: .power,
            left: .variable("x"),
            right: .binary(op: .power, left: .variable("y"), right: .variable("z"))
        )
        XCTAssertEqual(ast3, expected3)
    }
    
    func testParserUnary() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        let tokens = try lexer.tokenize("-x + 2")
        let ast = try parser.parse(tokens)
        let expected = ASTNode.binary(
            op: .plus,
            left: .unary(op: .minus, operand: .variable("x")),
            right: .number(2)
        )
        XCTAssertEqual(ast, expected)
    }
    
    func testParserFunctions() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        let tokens = try lexer.tokenize("sin(x)")
        let ast = try parser.parse(tokens)
        let expected = ASTNode.function(name: "sin", args: [.variable("x")])
        XCTAssertEqual(ast, expected)
    }
    
    // MARK: - AST toString() Tests
    
    func testASTToString() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        let exprs = [
            "2 * x",
            "x ^ 2",
            "(x + 1) * 3",
            "x - (y - z)",
            "x - y - z",
            "sin(x) + 2"
        ]
        
        for expr in exprs {
            let tokens = try lexer.tokenize(expr)
            let ast = try parser.parse(tokens)
            let formatted = ast.toString()
            
            // Re-parse the formatted string to ensure it builds the exact same AST
            let tokensRe = try lexer.tokenize(formatted)
            let astRe = try parser.parse(tokensRe)
            XCTAssertEqual(ast, astRe, "Failed for expression: \(expr) -> formatted: \(formatted)")
        }
    }
}
