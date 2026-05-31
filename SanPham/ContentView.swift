//
//  ContentView.swift
//  SanPham
//
//  Created by Phạm Anh Khoa on 24/05/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var graphVM = GraphViewModel()
    @State private var analysisVM = AnalysisViewModel()
    @State private var showAnalysisPanel: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            if isLandscape {
                // Side-by-side split layout for Mac/iPad/Landscape
                HStack(spacing: 0) {
                    // Left panel: Control + optional Analysis
                    VStack(spacing: 0) {
                        ControlPanelView(viewModel: graphVM)
                        
                        if showAnalysisPanel {
                            Divider().background(Color.white.opacity(0.15))
                            AnalysisPanel(graphVM: graphVM, analysisVM: analysisVM)
                                .frame(maxHeight: geometry.size.height * 0.5)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(width: 360)
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                    
                    // Right: Graph canvas
                    GraphView(viewModel: graphVM)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .topTrailing) {
                            analysisToggleButton
                                .padding(.top, 8)
                                .padding(.trailing, 60)
                        }
                }
                .ignoresSafeArea()
            } else {
                // Portrait iPhone: top graph, bottom panel
                VStack(spacing: 0) {
                    // Top: Graph Canvas
                    GraphView(viewModel: graphVM)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .topTrailing) {
                            analysisToggleButton
                                .padding(.top, 8)
                                .padding(.trailing, 60)
                        }
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                    
                    // Bottom panel — toggle between Control and Analysis
                    if showAnalysisPanel {
                        AnalysisPanel(graphVM: graphVM, analysisVM: analysisVM)
                            .frame(height: geometry.size.height * 0.45)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        ControlPanelView(viewModel: graphVM)
                            .frame(height: geometry.size.height * 0.45)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .ignoresSafeArea(edges: .horizontal)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Analysis Toggle Button
    private var analysisToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showAnalysisPanel.toggle()
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: showAnalysisPanel ? "chart.xyaxis.line" : "function")
                    .font(.system(size: 13, weight: .bold))
                Text(showAnalysisPanel ? "Graph" : "Analyze")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    ContentView()
}
