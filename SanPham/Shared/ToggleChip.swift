//
//  ToggleChip.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import SwiftUI

/// A reusable chip-style toggle button component.
public struct ToggleChip: View {
    let label: String
    let icon: String?
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void
    
    public init(
        label: String,
        icon: String? = nil,
        isActive: Bool,
        activeColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.isActive = isActive
        self.activeColor = activeColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .bold : .medium))
            }
            .foregroundColor(isActive ? .white : .white.opacity(0.55))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isActive ? activeColor.opacity(0.6) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? activeColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}
