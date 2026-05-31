//
//  ControlPanelView.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import SwiftUI

public struct ControlPanelView: View {
    @Bindable var viewModel: GraphViewModel
    
    // UI Local State for calculations
    @State private var showingCalculationsForId: UUID? = nil
    @State private var integrationStart: String = "0"
    @State private var integrationEnd: String = "1"
    @State private var integrationResult: Double? = nil
    
    public init(viewModel: GraphViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Settings Section
            settingsHeader
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Function List Section
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.functions) { function in
                        functionCard(for: function)
                    }
                    
                    // Add Function Button
                    Button(action: {
                        viewModel.addFunction()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Expression")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.75))
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.top, 6)
                }
                .padding()
            }
        }
        .background(Color(red: 0.12, green: 0.13, blue: 0.18))
    }
    
    // MARK: - Header
    private var settingsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("GraphCalc Engine")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                
                // Reset Viewport Button
                Button(action: {
                    viewModel.resetViewportForMode()
                }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.bottom, 4)
            
            // Mode Selectors
            HStack(spacing: 12) {
                // Graph Mode: Cartesian vs Polar
                Picker("Graph Mode", selection: $viewModel.mode) {
                    Text("Cartesian").tag(GraphMode.cartesian)
                    Text("Polar").tag(GraphMode.polar)
                }
                .pickerStyle(.segmented)
                .colorMultiply(.white)
                
                // Angle Mode: Radian vs Degree
                Picker("Angle Mode", selection: $viewModel.angleMode) {
                    Text("Rad").tag(AngleMode.radian)
                    Text("Deg").tag(AngleMode.degree)
                }
                .pickerStyle(.segmented)
                .colorMultiply(.white)
            }
            
            // Viewport Bounds Info
            HStack(spacing: 10) {
                viewportField(label: "xMin", value: $viewModel.viewport.xMin)
                viewportField(label: "xMax", value: $viewModel.viewport.xMax)
                viewportField(label: "yMin", value: $viewModel.viewport.yMin)
                viewportField(label: "yMax", value: $viewModel.viewport.yMax)
            }
            .font(.caption)
            .padding(.top, 4)
        }
        .padding()
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
    }
    
    private func viewportField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 9, weight: .bold))
            TextField(label, value: value, format: .number.precision(.fractionLength(2)))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .padding(6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
                .multilineTextAlignment(.center)
                .keyboardType(.numbersAndPunctuation)
        }
    }
    
    // MARK: - Function Card View
    private func functionCard(for function: FunctionModel) -> some View {
        let isSelectedForCalc = showingCalculationsForId == function.id
        
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Color Picker Circle
                Menu {
                    ForEach(GraphViewModel.presetColors, id: \.self) { color in
                        Button(action: {
                            if let idx = viewModel.functions.firstIndex(where: { $0.id == function.id }) {
                                viewModel.functions[idx].color = color
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(red: color.red, green: color.green, blue: color.blue))
                                    .frame(width: 16, height: 16)
                                Text(colorName(for: color))
                            }
                        }
                    }
                } label: {
                    Circle()
                        .fill(Color(red: function.color.red, green: function.color.green, blue: function.color.blue))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }
                
                // Equation Text Field
                let textBinding = Binding<String>(
                    get: { function.expression },
                    set: { viewModel.updateFunctionExpression(id: function.id, newExpression: $0) }
                )
                
                TextField(
                    function.isPolar ? "r = f(θ)" : "y = f(x)",
                    text: textBinding
                )
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .padding(10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                
                // Visibility eye icon
                Button(action: {
                    viewModel.toggleFunctionVisibility(id: function.id)
                }) {
                    Image(systemName: function.isVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(function.isVisible ? .blue : .white.opacity(0.3))
                }
                
                // Delete button
                Button(action: {
                    withAnimation {
                        viewModel.removeFunction(id: function.id)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding(10)
            
            // Error Message (if any)
            if let errorMsg = viewModel.functionErrors[function.id] {
                Text(errorMsg)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            
            // Expandable Math Engine Calculations Toolbar
            if viewModel.functionErrors[function.id] == nil && !function.expression.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack {
                    // Polar/Cartesian Toggle
                    Button(action: {
                        viewModel.toggleFunctionPolar(id: function.id)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: function.isPolar ? "p.circle.fill" : "c.circle.fill")
                            Text(function.isPolar ? "Polar" : "Cartesian")
                        }
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    // Engine Analysis Button
                    Button(action: {
                        withAnimation {
                            if isSelectedForCalc {
                                showingCalculationsForId = nil
                            } else {
                                showingCalculationsForId = function.id
                                integrationResult = nil
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "function")
                            Text(isSelectedForCalc ? "Hide Calculus" : "Analyze Engine")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            
            // Expanded Analysis Panel
            if isSelectedForCalc, let ast = viewModel.getAST(for: function.id) {
                analysisPanel(for: function, ast: ast)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelectedForCalc ? Color.blue.opacity(0.4) : Color.white.opacity(0.05), lineWidth: 1.5)
        )
    }
    
    // MARK: - Analysis Sub-panel
    private func analysisPanel(for function: FunctionModel, ast: ASTNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Symbolic Derivative
            VStack(alignment: .leading, spacing: 4) {
                Text("SYMBOLIC DERIVATIVE f'(x)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                
                let derivAst = SymbolicDifferentiator.differentiate(ast)
                let derivString = derivAst.toString()
                
                HStack {
                    Text(derivString)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    
                    // Plot derivative button
                    Button(action: {
                        viewModel.addFunction(expression: derivString, color: RGBAColor(red: 0.2, green: 0.8, blue: 0.4))
                    }) {
                        Text("+ Plot")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
            }
            
            // 2. Symbolic Indefinite Integral
            VStack(alignment: .leading, spacing: 4) {
                Text("SYMBOLIC INDEFINITE INTEGRAL ∫ f(x) dx")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                
                switch SymbolicIntegrator.integrate(ast) {
                case .success(let intAst):
                    let intString = intAst.toString()
                    HStack {
                        Text("\(intString) + C")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.purple)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        
                        // Plot integral button
                        Button(action: {
                            viewModel.addFunction(expression: intString, color: RGBAColor(red: 0.6, green: 0.3, blue: 0.9))
                        }) {
                            Text("+ Plot")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.purple)
                                .cornerRadius(4)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(6)
                case .failure(let error):
                    Text("Symbolic integration failed: \(error.localizedDescription)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .italic()
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            // 3. Roots in viewport
            VStack(alignment: .leading, spacing: 4) {
                Text("ROOTS IN VIEWPORT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                
                let range = viewModel.viewport.xMin...viewModel.viewport.xMax
                let roots = NumericsEngine.findRoots(of: ast, in: range, angleMode: viewModel.angleMode)
                
                if roots.isEmpty {
                    Text("No roots found in x ∈ [\(String(format: "%.1f", viewModel.viewport.xMin)), \(String(format: "%.1f", viewModel.viewport.xMax))]")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                } else {
                    HStack(spacing: 8) {
                        ForEach(roots, id: \.self) { root in
                            Text(String(format: "x ≈ %.4f", root))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // 4. Numerical Definite Integral
            VStack(alignment: .leading, spacing: 6) {
                Text("NUMERICAL DEFINITE INTEGRAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                
                HStack(spacing: 8) {
                    Text("From")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    TextField("a", text: $integrationStart)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(6)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numbersAndPunctuation)
                    
                    Text("To")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    TextField("b", text: $integrationEnd)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(6)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numbersAndPunctuation)
                    
                    Button(action: {
                        guard let start = Double(integrationStart), let end = Double(integrationEnd) else { return }
                        integrationResult = NumericsEngine.integrate(
                            ast,
                            from: start,
                            to: end,
                            steps: 1000,
                            angleMode: viewModel.angleMode
                        )
                    }) {
                        Text("Calculate")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                }
                
                if let result = integrationResult {
                    HStack {
                        Text("Area =")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(format: "%.6f", result))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.cyan)
                            .fontWeight(.bold)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.15))
    }
    
    // MARK: - Color Names
    private func colorName(for color: RGBAColor) -> String {
        if color.red > 0.8 && color.green < 0.3 { return "Red" }
        if color.blue > 0.7 && color.red < 0.3 { return "Blue" }
        if color.green > 0.6 && color.red < 0.3 { return "Green" }
        if color.red > 0.5 && color.blue > 0.7 { return "Purple" }
        if color.red > 0.8 && color.green > 0.4 && color.blue < 0.2 { return "Orange" }
        return "Custom"
    }
}
