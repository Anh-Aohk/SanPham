//
//  CoreEngineTests.swift
//  SanPhamTests
//
//  Created by Antigravity on 31/05/2026.
//

import XCTest

class CoreEngineTests: XCTestCase {
    
    // MARK: - Evaluator Tests
    
    func testEvaluatorArithmetic() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // 2 + 3 * 4 -> 14
        let tokens1 = try lexer.tokenize("2 + 3 * 4")
        let ast1 = try parser.parse(tokens1)
        XCTAssertEqual(Evaluator.evaluate(ast1, x: 0, angleMode: .radian), 14.0)
        
        // (2 + 3) * 4 -> 20
        let tokens2 = try lexer.tokenize("(2 + 3) * 4")
        let ast2 = try parser.parse(tokens2)
        XCTAssertEqual(Evaluator.evaluate(ast2, x: 0, angleMode: .radian), 20.0)
        
        // 2 ^ 3 ^ 2 -> 512 (right-associative: 2 ^ 9)
        let tokens3 = try lexer.tokenize("2 ^ 3 ^ 2")
        let ast3 = try parser.parse(tokens3)
        XCTAssertEqual(Evaluator.evaluate(ast3, x: 0, angleMode: .radian), 512.0)
    }
    
    func testEvaluatorVariablesAndConstants() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // x + 1 at x = 5 -> 6
        let tokens1 = try lexer.tokenize("x + 1")
        let ast1 = try parser.parse(tokens1)
        XCTAssertEqual(Evaluator.evaluate(ast1, x: 5.0, angleMode: .radian), 6.0)
        
        // pi -> 3.14159265...
        let tokens2 = try lexer.tokenize("pi")
        let ast2 = try parser.parse(tokens2)
        XCTAssertEqual(Evaluator.evaluate(ast2, x: 0, angleMode: .radian), Double.pi)
        
        // e -> 2.71828182...
        let tokens3 = try lexer.tokenize("e")
        let ast3 = try parser.parse(tokens3)
        XCTAssertEqual(Evaluator.evaluate(ast3, x: 0, angleMode: .radian), Foundation.exp(1.0))
    }
    
    func testEvaluatorFunctionsAndAngleModes() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // sin(pi/2) in radians -> 1
        let tokens1 = try lexer.tokenize("sin(pi / 2)")
        let ast1 = try parser.parse(tokens1)
        XCTAssertEqual(Evaluator.evaluate(ast1, x: 0, angleMode: .radian), 1.0, accuracy: 1e-10)
        
        // sin(90) in degrees -> 1
        let tokens2 = try lexer.tokenize("sin(90)")
        let ast2 = try parser.parse(tokens2)
        XCTAssertEqual(Evaluator.evaluate(ast2, x: 0, angleMode: .degree), 1.0, accuracy: 1e-10)
        
        // ln(e) -> 1
        let tokens3 = try lexer.tokenize("ln(e)")
        let ast3 = try parser.parse(tokens3)
        XCTAssertEqual(Evaluator.evaluate(ast3, x: 0, angleMode: .radian), 1.0, accuracy: 1e-10)
    }
    
    // MARK: - SymbolicDifferentiator Tests
    
    func testDifferentiatorRules() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // Constant: 5 -> 0
        let tokens1 = try lexer.tokenize("5")
        let ast1 = try parser.parse(tokens1)
        let diff1 = SymbolicDifferentiator.differentiate(ast1)
        XCTAssertEqual(diff1, .number(0))
        
        // Linear: x -> 1
        let tokens2 = try lexer.tokenize("x")
        let ast2 = try parser.parse(tokens2)
        let diff2 = SymbolicDifferentiator.differentiate(ast2)
        XCTAssertEqual(diff2, .number(1))
        
        // Power: x^2 -> 2 * x (simplified from 2 * x ^ 1 * 1)
        let tokens3 = try lexer.tokenize("x ^ 2")
        let ast3 = try parser.parse(tokens3)
        let diff3 = SymbolicDifferentiator.differentiate(ast3)
        let expected3 = ASTNode.binary(op: .multiply, left: .number(2), right: .variable("x"))
        XCTAssertEqual(diff3, expected3)
        
        // Trigonometric: sin(x) -> cos(x)
        let tokens4 = try lexer.tokenize("sin(x)")
        let ast4 = try parser.parse(tokens4)
        let diff4 = SymbolicDifferentiator.differentiate(ast4)
        let expected4 = ASTNode.function(name: "cos", args: [.variable("x")])
        XCTAssertEqual(diff4, expected4)
    }
    
    // MARK: - SymbolicIntegrator Tests
    
    func testIntegratorRules() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // Constant: 5 -> 5 * x
        let tokens1 = try lexer.tokenize("5")
        let ast1 = try parser.parse(tokens1)
        let int1 = try SymbolicIntegrator.integrate(ast1).get()
        let expected1 = ASTNode.binary(op: .multiply, left: .number(5), right: .variable("x"))
        XCTAssertEqual(int1, expected1)
        
        // Power: x^3 -> (x^4) / 4
        let tokens2 = try lexer.tokenize("x ^ 3")
        let ast2 = try parser.parse(tokens2)
        let int2 = try SymbolicIntegrator.integrate(ast2).get()
        let expected2 = ASTNode.binary(
            op: .divide,
            left: .binary(op: .power, left: .variable("x"), right: .number(4)),
            right: .number(4)
        )
        XCTAssertEqual(int2, expected2)
        
        // Trigonometric: cos(x) -> sin(x)
        let tokens3 = try lexer.tokenize("cos(x)")
        let ast3 = try parser.parse(tokens3)
        let int3 = try SymbolicIntegrator.integrate(ast3).get()
        let expected3 = ASTNode.function(name: "sin", args: [.variable("x")])
        XCTAssertEqual(int3, expected3)
        
        // Unsupported: x * sin(x) -> should fail
        let tokens4 = try lexer.tokenize("x * sin(x)")
        let ast4 = try parser.parse(tokens4)
        let result = SymbolicIntegrator.integrate(ast4)
        if case .success = result {
            XCTFail("Should have failed to integrate x * sin(x)")
        }
    }
    
    // MARK: - NumericsEngine Tests
    
    func testNumericsRoots() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // f(x) = x^2 - 4  -> root at x = 2.0 in [0, 3]
        let tokens = try lexer.tokenize("x ^ 2 - 4")
        let ast = try parser.parse(tokens)
        let roots = NumericsEngine.findRoots(of: ast, in: 0.0...3.0, angleMode: .radian)
        
        XCTAssertEqual(roots.count, 1)
        XCTAssertEqual(roots[0], 2.0, accuracy: 1e-5)
    }
    
    func testNumericsIntegration() throws {
        let lexer = Lexer()
        let parser = ExpressionParser()
        
        // Integral of x^2 from 0 to 3 -> 9.0
        let tokens = try lexer.tokenize("x ^ 2")
        let ast = try parser.parse(tokens)
        let area = NumericsEngine.integrate(ast, from: 0.0, to: 3.0, steps: 100, angleMode: .radian)
        
        XCTAssertEqual(area, 9.0, accuracy: 1e-5)
    }
}
