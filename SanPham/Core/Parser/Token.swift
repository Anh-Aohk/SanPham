//
//  Token.swift
//  SanPham
//
//  Created by Antigravity on 31/05/2026.
//

import Foundation

public enum Token: Equatable {
    case number(Double)
    case variable(String)
    case plus
    case minus
    case multiply
    case divide
    case power
    case leftParenthesis
    case rightParenthesis
    case comma
    case function(String)
}
