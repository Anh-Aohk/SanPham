//
//  main.swift
//  scratch
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation
import CoreGraphics

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
    if actual != expected {
        print("❌ Assertion Failed at \(file):\(line): \(actual) != \(expected). \(message)")
        exit(1)
    }
}

func assertEqualDouble(_ actual: Double, _ expected: Double, accuracy: Double, _ message: String = "", file: String = #file, line: Int = #line) {
    if abs(actual - expected) > accuracy {
        print("❌ Assertion Failed at \(file):\(line): \(actual) != \(expected) (accuracy: \(accuracy)). \(message)")
        exit(1)
    }
}

func assertThrowsError<T>(_ block: () throws -> T, file: String = #file, line: Int = #line, onError: (Error) -> Void) {
    do {
        _ = try block()
        print("❌ Assertion Failed at \(file):\(line): Expected error was not thrown")
        exit(1)
    } catch {
        onError(error)
    }
}

func runTests() {
    print("🚀 Starting Parser & Lexer unit tests...")
    
    let lexer = Lexer()
    let parser = ExpressionParser()
    
    // Test 1: Lexer Happy Path
    do {
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
        assertEqual(tokens, expected, "Lexer happy path mismatch")
        print("✅ Lexer Happy Path passed")
    } catch {
        print("❌ Lexer Happy Path failed with error: \(error)")
        exit(1)
    }
    
    // Test 2: Lexer Edge Cases
    do {
        let tokens1 = try lexer.tokenize(".5")
        assertEqual(tokens1, [.number(0.5)], "Decimal dot prefix mismatch")
        
        let tokens2 = try lexer.tokenize("  x   +   y  ")
        assertEqual(tokens2, [.variable("x"), .plus, .variable("y")], "Spaces mismatch")
        print("✅ Lexer Edge Cases passed")
    } catch {
        print("❌ Lexer Edge Cases failed with error: \(error)")
        exit(1)
    }
    
    // Test 3: Lexer Errors
    assertThrowsError({ try lexer.tokenize("x @ y") }) { error in
        if case LexerError.invalidCharacter(let char) = error {
            assertEqual(char, "@")
        } else {
            print("❌ Lexer expected invalidCharacter, got: \(error)")
            exit(1)
        }
    }
    assertThrowsError({ try lexer.tokenize("1.2.3") }) { error in
        if case LexerError.invalidNumber(let str) = error {
            assertEqual(str, "1.2.")
        } else {
            print("❌ Lexer expected invalidNumber, got: \(error)")
            exit(1)
        }
    }
    print("✅ Lexer Error Cases passed")
    
    // Test 4: Parser Precedence
    do {
        // x + y * z  =>  x + (y * z)
        let tokens1 = try lexer.tokenize("x + y * z")
        let ast1 = try parser.parse(tokens1)
        let expected1 = ASTNode.binary(
            op: .plus,
            left: .variable("x"),
            right: .binary(op: .multiply, left: .variable("y"), right: .variable("z"))
        )
        assertEqual(ast1, expected1)
        
        // x * y + z  =>  (x * y) + z
        let tokens2 = try lexer.tokenize("x * y + z")
        let ast2 = try parser.parse(tokens2)
        let expected2 = ASTNode.binary(
            op: .plus,
            left: .binary(op: .multiply, left: .variable("x"), right: .variable("y")),
            right: .variable("z")
        )
        assertEqual(ast2, expected2)
        
        // x ^ y ^ z  =>  x ^ (y ^ z) (right-associative)
        let tokens3 = try lexer.tokenize("x ^ y ^ z")
        let ast3 = try parser.parse(tokens3)
        let expected3 = ASTNode.binary(
            op: .power,
            left: .variable("x"),
            right: .binary(op: .power, left: .variable("y"), right: .variable("z"))
        )
        assertEqual(ast3, expected3)
        print("✅ Parser Precedence passed")
    } catch {
        print("❌ Parser Precedence failed with error: \(error)")
        exit(1)
    }
    
    // Test 5: Parser Unary & Functions
    do {
        let tokens = try lexer.tokenize("-x + 2")
        let ast = try parser.parse(tokens)
        let expected = ASTNode.binary(
            op: .plus,
            left: .unary(op: .minus, operand: .variable("x")),
            right: .number(2)
        )
        assertEqual(ast, expected)
        
        let tokens2 = try lexer.tokenize("sin(x)")
        let ast2 = try parser.parse(tokens2)
        let expected2 = ASTNode.function(name: "sin", args: [.variable("x")])
        assertEqual(ast2, expected2)
        print("✅ Parser Unary & Functions passed")
    } catch {
        print("❌ Parser Unary & Functions failed with error: \(error)")
        exit(1)
    }
    
    // Test 6: AST toString() formatting
    do {
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
            
            let tokensRe = try lexer.tokenize(formatted)
            let astRe = try parser.parse(tokensRe)
            assertEqual(ast, astRe, "AST mismatch after string formatting for: \(expr)")
        }
        print("✅ AST toString() formatting passed")
    } catch {
        print("❌ AST toString() failed with error: \(error)")
        exit(1)
    }
    
    print("\n🚀 Starting Evaluator unit tests...")
    
    // Test 7: Evaluator Arithmetic & Angle Modes
    do {
        let tokens1 = try lexer.tokenize("2 + 3 * 4")
        let ast1 = try parser.parse(tokens1)
        assertEqualDouble(Evaluator.evaluate(ast1, x: 0, angleMode: .radian), 14.0, accuracy: 1e-10)
        
        let tokens2 = try lexer.tokenize("2 ^ 3 ^ 2")
        let ast2 = try parser.parse(tokens2)
        assertEqualDouble(Evaluator.evaluate(ast2, x: 0, angleMode: .radian), 512.0, accuracy: 1e-10)
        
        let tokens3 = try lexer.tokenize("sin(pi / 2)")
        let ast3 = try parser.parse(tokens3)
        assertEqualDouble(Evaluator.evaluate(ast3, x: 0, angleMode: .radian), 1.0, accuracy: 1e-10)
        
        let tokens4 = try lexer.tokenize("sin(90)")
        let ast4 = try parser.parse(tokens4)
        assertEqualDouble(Evaluator.evaluate(ast4, x: 0, angleMode: .degree), 1.0, accuracy: 1e-10)
        print("✅ Evaluator Arithmetic & Angle Modes passed")
    } catch {
        print("❌ Evaluator Arithmetic failed with error: \(error)")
        exit(1)
    }
    
    print("\n🚀 Starting SymbolicDifferentiator unit tests...")
    
    // Test 8: Symbolic Differentiator
    do {
        // constant -> 0
        let tokens1 = try lexer.tokenize("5")
        let ast1 = try parser.parse(tokens1)
        let diff1 = SymbolicDifferentiator.differentiate(ast1)
        assertEqual(diff1, .number(0))
        
        // x -> 1
        let tokens2 = try lexer.tokenize("x")
        let ast2 = try parser.parse(tokens2)
        let diff2 = SymbolicDifferentiator.differentiate(ast2)
        assertEqual(diff2, .number(1))
        
        // x^2 -> 2 * x
        let tokens3 = try lexer.tokenize("x ^ 2")
        let ast3 = try parser.parse(tokens3)
        let diff3 = SymbolicDifferentiator.differentiate(ast3)
        let expected3 = ASTNode.binary(op: .multiply, left: .number(2), right: .variable("x"))
        assertEqual(diff3, expected3)
        
        // sin(x) -> cos(x)
        let tokens4 = try lexer.tokenize("sin(x)")
        let ast4 = try parser.parse(tokens4)
        let diff4 = SymbolicDifferentiator.differentiate(ast4)
        let expected4 = ASTNode.function(name: "cos", args: [.variable("x")])
        assertEqual(diff4, expected4)
        print("✅ SymbolicDifferentiator passed")
    } catch {
        print("❌ SymbolicDifferentiator failed with error: \(error)")
        exit(1)
    }
    
    print("\n🚀 Starting SymbolicIntegrator unit tests...")
    
    // Test 9: Symbolic Integrator
    do {
        // 5 -> 5 * x
        let tokens1 = try lexer.tokenize("5")
        let ast1 = try parser.parse(tokens1)
        let int1 = try SymbolicIntegrator.integrate(ast1).get()
        let expected1 = ASTNode.binary(op: .multiply, left: .number(5), right: .variable("x"))
        assertEqual(int1, expected1)
        
        // x^3 -> (x^4) / 4
        let tokens2 = try lexer.tokenize("x ^ 3")
        let ast2 = try parser.parse(tokens2)
        let int2 = try SymbolicIntegrator.integrate(ast2).get()
        let expected2 = ASTNode.binary(
            op: .divide,
            left: .binary(op: .power, left: .variable("x"), right: .number(4)),
            right: .number(4)
        )
        assertEqual(int2, expected2)
        
        // cos(x) -> sin(x)
        let tokens3 = try lexer.tokenize("cos(x)")
        let ast3 = try parser.parse(tokens3)
        let int3 = try SymbolicIntegrator.integrate(ast3).get()
        let expected3 = ASTNode.function(name: "sin", args: [.variable("x")])
        assertEqual(int3, expected3)
        print("✅ SymbolicIntegrator passed")
    } catch {
        print("❌ SymbolicIntegrator failed with error: \(error)")
        exit(1)
    }
    
    print("\n🚀 Starting NumericsEngine unit tests...")
    
    // Test 10: Numerics Engine
    do {
        // Roots of x^2 - 4 in [0, 3] -> 2.0
        let tokens1 = try lexer.tokenize("x ^ 2 - 4")
        let ast1 = try parser.parse(tokens1)
        let roots = NumericsEngine.findRoots(of: ast1, in: 0.0...3.0, angleMode: .radian)
        assertEqual(roots.count, 1)
        assertEqualDouble(roots[0], 2.0, accuracy: 1e-5)
        
        // Integral of x^2 from 0 to 3 -> 9.0
        let tokens2 = try lexer.tokenize("x ^ 2")
        let ast2 = try parser.parse(tokens2)
        let area = NumericsEngine.integrate(ast2, from: 0.0, to: 3.0, steps: 100, angleMode: .radian)
        assertEqualDouble(area, 9.0, accuracy: 1e-5)
        print("✅ NumericsEngine passed")
    } catch {
        print("❌ NumericsEngine failed with error: \(error)")
        exit(1)
    }
    
    print("\n🚀 Starting ViewPort unit tests...")
    
    // Test 11: ViewPort conversion
    do {
        let viewport = ViewPort(xMin: -10, xMax: 10, yMin: -6, yMax: 6)
        let size = CGSize(width: 200, height: 120)
        
        // Mathematical (0, 0) should convert to canvas (100, 60)
        let canvasCenter = viewport.toCanvas(0, 0, size: size)
        assertEqualDouble(Double(canvasCenter.x), 100.0, accuracy: 1e-10)
        assertEqualDouble(Double(canvasCenter.y), 60.0, accuracy: 1e-10)
        
        // Canvas (100, 60) should convert back to mathematical (0, 0)
        let mathCenter = viewport.toMath(canvasCenter, size: size)
        assertEqualDouble(mathCenter.x, 0.0, accuracy: 1e-10)
        assertEqualDouble(mathCenter.y, 0.0, accuracy: 1e-10)
        
        print("✅ ViewPort passed")
    }
    
    print("\n🎉 ALL CORE AND ENGINE TESTS PASSED SUCCESSFULLY! 🎉")
}

runTests()
