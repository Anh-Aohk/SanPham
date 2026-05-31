//
//  AnalysisPanel.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import SwiftUI

public struct AnalysisPanel: View {
    @Bindable var graphVM: GraphViewModel
    @Bindable var analysisVM: AnalysisViewModel
    
    @State private var selectedTab: AnalysisTab = .derivative
    @State private var showQuickPick: Bool = false
    
    enum AnalysisTab: String, CaseIterable {
        case derivative = "Derivative"
        case integral = "Integral"
        case roots = "Roots"
        case evaluate = "f(a)"
    }
    
    public init(graphVM: GraphViewModel, analysisVM: AnalysisViewModel) {
        self.graphVM = graphVM
        self.analysisVM = analysisVM
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Analysis Engine")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Quick pick toggle
                Button(action: { withAnimation { showQuickPick.toggle() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Quick Pick")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Quick Pick Panel (expandable)
            if showQuickPick {
                quickPickPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Function Selector
            if !graphVM.functions.isEmpty {
                functionSelector
            }
            
            // Tab Bar
            tabBar
            
            Divider().background(Color.white.opacity(0.15))
            
            // Tab Content
            ScrollView {
                tabContent
                    .padding()
            }
            
            // Results Display
            if !analysisVM.results.isEmpty {
                Divider().background(Color.white.opacity(0.15))
                resultsSection
            }
        }
        .background(Color(red: 0.1, green: 0.11, blue: 0.15))
    }
    
    // MARK: - Quick Pick Panel
    private var quickPickPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(QuickPickData.categories) { category in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        Text(category.name)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(category.items, id: \.expression) { item in
                                Button(action: {
                                    let isPolar = category.name == "Polar"
                                    graphVM.addFunction(
                                        expression: item.expression,
                                        isPolar: isPolar
                                    )
                                    if isPolar && graphVM.mode != .polar {
                                        graphVM.mode = .polar
                                    }
                                    withAnimation { showQuickPick = false }
                                }) {
                                    VStack(spacing: 2) {
                                        Text(item.label)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(item.expression)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.55))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Function Selector
    private var functionSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(graphVM.functions) { fn in
                    let isSelected = analysisVM.selectedFunctionId == fn.id
                    
                    Button(action: {
                        analysisVM.selectedFunctionId = fn.id
                        analysisVM.clearResults()
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(red: fn.color.red, green: fn.color.green, blue: fn.color.blue))
                                .frame(width: 10, height: 10)
                            
                            Text(fn.expression.isEmpty ? "Empty" : fn.expression)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.blue.opacity(0.35) : Color.white.opacity(0.06))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.blue.opacity(0.6) : Color.clear, lineWidth: 1.5)
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AnalysisTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .blue : .white.opacity(0.5))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        if analysisVM.selectedFunctionId == nil {
            Text("Select a function above to analyze")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            switch selectedTab {
            case .derivative:
                derivativeTab
            case .integral:
                integralTab
            case .roots:
                rootsTab
            case .evaluate:
                evaluateTab
            }
        }
        
        if let error = analysisVM.errorMessage {
            Text(error)
                .font(.caption2)
                .foregroundColor(.red)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    // MARK: - Derivative Tab
    private var derivativeTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter a number for f'(a), or leave empty / type \"x\" for symbolic f'(x)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            
            HStack(spacing: 10) {
                TextField("x or a number", text: $analysisVM.derivativeInput)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Button(action: {
                    guard let fnId = analysisVM.selectedFunctionId,
                          let ast = graphVM.getAST(for: fnId) else { return }
                    analysisVM.computeDerivative(ast: ast, angleMode: graphVM.angleMode)
                }) {
                    Text("Compute")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Integral Tab
    private var integralTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter bounds [a, b] for definite integral, or leave empty for symbolic ∫f(x)dx")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("a")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    TextField("lower", text: $analysisVM.integralBoundA)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .keyboardType(.numbersAndPunctuation)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("b")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    TextField("upper", text: $analysisVM.integralBoundB)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .keyboardType(.numbersAndPunctuation)
                }
                
                Button(action: {
                    guard let fnId = analysisVM.selectedFunctionId,
                          let ast = graphVM.getAST(for: fnId) else { return }
                    analysisVM.computeIntegral(ast: ast, angleMode: graphVM.angleMode)
                }) {
                    Text("Compute")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Roots Tab
    private var rootsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find x where f(x) = 0 within the current viewport range")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            
            Button(action: {
                guard let fnId = analysisVM.selectedFunctionId,
                      let ast = graphVM.getAST(for: fnId) else { return }
                let range = graphVM.viewport.xMin...graphVM.viewport.xMax
                analysisVM.findRoots(ast: ast, in: range, angleMode: graphVM.angleMode)
            }) {
                HStack {
                    Image(systemName: "target")
                    Text("Find Roots in Viewport")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.8))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Evaluate Tab
    private var evaluateTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calculate f(a) at a specific x value")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            
            HStack(spacing: 10) {
                TextField("Enter x value", text: $analysisVM.evaluateAtInput)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    .keyboardType(.numbersAndPunctuation)
                
                Button(action: {
                    guard let fnId = analysisVM.selectedFunctionId,
                          let ast = graphVM.getAST(for: fnId) else { return }
                    analysisVM.evaluateAtPoint(ast: ast, angleMode: graphVM.angleMode)
                }) {
                    Text("Evaluate")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Results")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Button(action: { analysisVM.clearResults() }) {
                    Text("Clear")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(analysisVM.results.enumerated().reversed()), id: \.offset) { _, result in
                        resultCard(result)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 200)
        }
    }
    
    // MARK: - Result Card
    private func resultCard(_ result: AnalysisResult) -> some View {
        HStack {
            switch result {
            case .value(let x, let y):
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("f(\(String(format: "%.4f", x)))")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                    Text("= \(String(format: "%.6f", y))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green).fontWeight(.bold)
                }
                
            case .roots(let roots):
                Image(systemName: "target")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Roots found: \(roots.count)")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                    if roots.isEmpty {
                        Text("No roots in viewport range")
                            .font(.caption2).foregroundColor(.white.opacity(0.4)).italic()
                    } else {
                        Text(roots.map { String(format: "x ≈ %.6f", $0) }.joined(separator: ", "))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.yellow).fontWeight(.bold)
                    }
                }
                
            case .derivativeSymbolic(let expr):
                Image(systemName: "function")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("f'(x) =")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                    Text(expr)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue).fontWeight(.bold)
                }
                
            case .derivativeAtPoint(let x, let result):
                Image(systemName: "function")
                    .foregroundColor(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("f'(\(String(format: "%.4f", x)))")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                    Text("= \(String(format: "%.6f", result))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.cyan).fontWeight(.bold)
                }
                
            case .antiderivative(let expr):
                Image(systemName: "sum")
                    .foregroundColor(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("∫ f(x) dx =")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                    Text(expr)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.purple).fontWeight(.bold)
                }
                
            case .integral(let a, let b, let result):
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("∫[\(String(format: "%.2f", a)), \(String(format: "%.2f", b))] f(x) dx")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                    Text("= \(String(format: "%.6f", result))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.cyan).fontWeight(.bold)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}
