//
//  GraphView.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import SwiftUI

public struct GraphView: View {
    // MARK: - Dependencies
    @Bindable var viewModel: GraphViewModel
    
    // MARK: - Gesture States
    @State private var dragStartViewport: ViewPort? = nil
    @State private var zoomStartViewport: ViewPort? = nil
    
    public init(viewModel: GraphViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            Canvas { context, canvasSize in
                switch viewModel.mode {
                case .cartesian:
                    CartesianRenderer.render(
                        in: context,
                        size: canvasSize,
                        viewport: viewModel.viewport,
                        functions: viewModel.functions,
                        viewModel: viewModel
                    )
                case .polar:
                    PolarRenderer.render(
                        in: context,
                        size: canvasSize,
                        viewport: viewModel.viewport,
                        functions: viewModel.functions,
                        viewModel: viewModel
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStartViewport == nil {
                            dragStartViewport = viewModel.viewport
                        }
                        guard let startViewport = dragStartViewport else { return }
                        
                        let xSpan = startViewport.xMax - startViewport.xMin
                        let ySpan = startViewport.yMax - startViewport.yMin
                        
                        let dx = (Double(value.translation.width) / Double(size.width)) * xSpan
                        let dy = (Double(value.translation.height) / Double(size.height)) * ySpan
                        
                        viewModel.viewport.xMin = startViewport.xMin - dx
                        viewModel.viewport.xMax = startViewport.xMax - dx
                        viewModel.viewport.yMin = startViewport.yMin + dy
                        viewModel.viewport.yMax = startViewport.yMax + dy
                    }
                    .onEnded { _ in
                        dragStartViewport = nil
                    }
                    .simultaneously(
                        with: MagnifyGesture()
                            .onChanged { value in
                                if zoomStartViewport == nil {
                                    zoomStartViewport = viewModel.viewport
                                }
                                guard let startViewport = zoomStartViewport else { return }
                                
                                let scale = 1.0 / value.magnification
                                // Center point of the gesture in canvas coordinates
                                let center = value.startLocation
                                let (mathX, mathY) = startViewport.toMath(center, size: size)
                                
                                let xHalfSpan = (startViewport.xMax - startViewport.xMin) / 2.0 * scale
                                let yHalfSpan = (startViewport.yMax - startViewport.yMin) / 2.0 * scale
                                
                                viewModel.viewport.xMin = mathX - xHalfSpan
                                viewModel.viewport.xMax = mathX + xHalfSpan
                                viewModel.viewport.yMin = mathY - yHalfSpan
                                viewModel.viewport.yMax = mathY + yHalfSpan
                            }
                            .onEnded { _ in
                                zoomStartViewport = nil
                            }
                    )
            )
            .overlay(alignment: .bottomTrailing) {
                // Quick Viewport navigation tools (Home, Zoom In, Zoom Out)
                VStack(spacing: 8) {
                    Button(action: { viewModel.resetViewportForMode() }) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        viewModel.zoom(scale: 0.7, center: CGPoint(x: size.width / 2.0, y: size.height / 2.0), size: size)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        viewModel.zoom(scale: 1.4, center: CGPoint(x: size.width / 2.0, y: size.height / 2.0), size: size)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .opacity(0.85)
                )
                .padding(12)
            }
        }
    }
}
