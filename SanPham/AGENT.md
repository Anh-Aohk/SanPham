# AGENT.md — GraphCalc iOS

Tài liệu này áp dụng cho **mọi AI agent** (Claude, Gemini, Cursor, Copilot, v.v.)
làm việc trên project GraphCalc iOS.

> **Đọc toàn bộ file này trước khi thực hiện bất kỳ thay đổi nào.**
> Mọi quy tắc ở đây đều có lý do — không được bỏ qua vì "trông có vẻ không cần thiết".

---

## 1. Snapshot project

| Thông tin | Giá trị |
|---|---|
| Platform | iOS 17+ |
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| State management | `@Observable` — không dùng `ObservableObject` / `@Published` |
| Parser | `Expression` (Nick Lockwood, SPM) |
| Toán số học | `swift-numerics` (Apple, SPM) |
| Góc mặc định | **Radian** — Degree là opt-in |
| Mục tiêu | Cá nhân / học tập, không publish App Store |
| Ngôn ngữ code | Tiếng Anh (tên biến, comment, doc comment) |

Tài liệu đầy đủ: xem `README.md`.

---

## 2. Cấu trúc file — bắt buộc tuân thủ

```
GraphCalc/
├── App/
│   ├── GraphCalcApp.swift
│   └── ContentView.swift
│
├── Models/                               ← Data types thuần Swift, không logic
│   ├── FunctionModel.swift               # struct — Identifiable, Codable
│   ├── AngleMode.swift                   # enum: .radian, .degree
│   ├── GraphMode.swift                   # enum: .cartesian, .polar
│   └── AnalysisResult.swift              # enum với associated values
│
├── Core/                                 ← KHÔNG import SwiftUI, testable độc lập
│   ├── Parser/
│   │   ├── Lexer.swift                   # String → [Token]
│   │   ├── Token.swift                   # enum Token
│   │   ├── ASTNode.swift                 # indirect enum — cây biểu thức
│   │   └── ExpressionParser.swift        # [Token] → ASTNode
│   ├── Engine/
│   │   ├── Evaluator.swift               # ASTNode + x + AngleMode → Double
│   │   ├── SymbolicDifferentiator.swift  # ASTNode → ASTNode (f′)
│   │   ├── SymbolicIntegrator.swift      # ASTNode → ASTNode (F(x)+C) — basic rules only
│   │   └── NumericsEngine.swift          # bisection, Simpson's rule
│   └── Geometry/
│       └── ViewPort.swift                # toCanvas(_:size:) — tọa độ → pixel
│
├── Features/                             ← Feature-based, không layer-based
│   ├── Graph/
│   │   ├── GraphViewModel.swift          # @Observable — nguồn sự thật duy nhất
│   │   ├── GraphView.swift               # SwiftUI Canvas + gesture handler
│   │   ├── CartesianRenderer.swift       # vẽ lưới vuông + đường cong
│   │   └── PolarRenderer.swift           # vẽ lưới cực + đường cong polar
│   ├── Analysis/
│   │   ├── AnalysisViewModel.swift       # routing logic: symbolic vs numeric
│   │   ├── AnalysisPanel.swift           # tab Derivative / Integral + quick-pick
│   │   └── QuickPickData.swift           # pure data, không có logic
│   └── Input/
│       └── InputPanel.swift              # TextField, list hàm, toggles
│
└── Shared/
    ├── Color+Codable.swift               # extension Color: Codable (RGBA)
    ├── Double+Formatting.swift           # .formatted(decimalPlaces:)
    └── ToggleChip.swift                  # component dùng chung
```

**Không được di chuyển, đổi tên, hay tái cấu trúc thư mục** mà không hỏi trước.

---

## 3. Quy tắc cứng (Hard Rules)

Vi phạm bất kỳ quy tắc nào dưới đây là **lỗi nghiêm trọng**, phải sửa trước khi tiếp tục.

---

### R1 — `Core/` và `Models/` không được import SwiftUI

```swift
// ✅ Core/Engine/NumericsEngine.swift
import Foundation
import Numerics

// ❌ Nghiêm cấm trong Core/ và Models/
import SwiftUI
```

**Lý do:** `Core/` phải build và test được bằng XCTest thuần, không cần simulator.
Đây là safety net quan trọng nhất của project.

---

### R2 — Dùng `@Observable`, không dùng `ObservableObject`

```swift
// ✅ Đúng — iOS 17+ macro
@Observable
class GraphViewModel {
    var functions: [FunctionModel] = []
}

// ❌ Sai — pattern cũ iOS 13
class GraphViewModel: ObservableObject {
    @Published var functions: [FunctionModel] = []
}
```

---

### R3 — Không tự thay đổi public interface sau khi đã approve

Interface được approve ở Bước A (xem mục 6) là contract cố định.
Implement phải khớp chính xác: tên hàm, tên parameter, kiểu trả về.
Không được thêm overload, đổi tên, hay thêm parameter tùy tiện.

---

### R4 — `FunctionModel` là struct, Identifiable, Codable

```swift
struct FunctionModel: Identifiable, Codable {
    let id: UUID
    var expression: String      // "sin(x)", "1 + cos(t)"
    var color: Color            // yêu cầu Color+Codable.swift
    var isVisible: Bool = true
    var isPolar: Bool = false
}
```

Không được thêm property mới vào struct này mà không hỏi trước.

---

### R5 — AngleMode phải được truyền vào hàm, không hardcode

```swift
// ✅ Đúng — nhận mode từ caller
func evaluateTrig(_ value: Double, mode: AngleMode) -> Double {
    Foundation.sin(mode == .degree ? value * .pi / 180 : value)
}

// ❌ Sai — hardcode radian
func evaluateTrig(_ value: Double) -> Double {
    Foundation.sin(value)
}
```

Mặc định là `.radian`. Toggle Degree chỉ ảnh hưởng đến hàm trig, không ảnh hưởng
đến giá trị x hay θ.

---

### R6 — `r` âm trong polar là hợp lệ, không được clamp hay bỏ qua

```swift
// ✅ Đúng — r âm vẫn convert bình thường
let x = r * cos(theta)
let y = r * sin(theta)

// ❌ Sai — mất nhánh của đồ thị
guard r >= 0 else { continue }
```

**Lý do:** `r = cos(2θ)` có đoạn `r < 0` tạo ra các cánh hoa về phía ngược.
Clamp sẽ làm mất hoàn toàn những nhánh đó.

---

### R7 — Handle NaN và Inf trong mọi renderer

```swift
// ✅ Đúng — nhấc bút khi gặp điểm lỗi
guard mathX.isFinite && mathY.isFinite else {
    penDown = false
    continue
}

// ❌ Sai — crash hoặc vẽ đường thẳng lạ xuyên màn hình
path.addLine(to: viewport.toCanvas(mathX, mathY, size: size))
```

---

### R8 — `ViewPort.toCanvas` — không được sửa công thức `py`

```swift
func toCanvas(_ mathX: Double, _ mathY: Double, size: CGSize) -> CGPoint {
    let px = (mathX - xMin) / (xMax - xMin) * size.width
    let py = (1 - (mathY - yMin) / (yMax - yMin)) * size.height
    //        ^^^^ dấu lật này là cố ý — y Canvas tăng xuống dưới
    return CGPoint(x: px, y: py)
}
```

Đây là hàm nhạy cảm nhất trong project. Sai một dấu là toàn bộ đồ thị lệch
hoặc lật ngược. Verify bằng assert trước khi dùng (xem mục 8).

---

### R9 — Routing logic đạo hàm và nguyên hàm phải nằm trong `AnalysisViewModel`, không phải `Core/`

```swift
// ✅ Đúng — routing trong AnalysisViewModel (Features layer)
func computeDerivative(of expression: String, input: String) -> AnalysisResult {
    if let a = Double(input) {
        // Numeric: tính f′(a) bằng cách differentiate rồi evaluate
        let derivAST = SymbolicDifferentiator.differentiate(ast)
        let result = Evaluator.evaluate(derivAST, x: a, angleMode: angleMode)
        return .derivativeAtPoint(x: a, result: result)
    } else {
        // Symbolic: input là "x" hoặc rỗng
        let derivAST = SymbolicDifferentiator.differentiate(ast)
        return .derivativeSymbolic(expression: derivAST.toString())
    }
}

func computeIntegral(of expression: String, a: String, b: String) -> AnalysisResult {
    if let aVal = Double(a), let bVal = Double(b) {
        // Definite integral
        let result = NumericsEngine.integrate(expression, from: aVal, to: bVal, angleMode: angleMode)
        return .integral(a: aVal, b: bVal, result: result)
    } else {
        // Antiderivative
        let antideriv = SymbolicIntegrator.integrate(ast)
        return .antiderivative(expression: antideriv.toString() + " + C")
    }
}

// ❌ Sai — routing trong Core/ làm mất tính testable độc lập
```

---

### R10 — `SymbolicIntegrator` chỉ hỗ trợ các rule cơ bản, trả lỗi rõ ràng khi không handle được

```swift
// ✅ Đúng — trả về Result type, không bịa kết quả
func integrate(_ node: ASTNode) -> Result<ASTNode, IntegrationError>

enum IntegrationError: Error {
    case unsupportedExpression(String)  // "Cannot integrate sin(x^2) symbolically"
}

// ❌ Sai — trả về kết quả sai khi gặp hàm phức tạp
func integrate(_ node: ASTNode) -> ASTNode  // bịa ra sin(x^2) → ? 
```

**Các rule được hỗ trợ (và chỉ những rule này):**

| Input | Output |
|---|---|
| `k` (hằng số) | `k*x` |
| `x` | `x^2/2` |
| `x^n` (n ≠ -1) | `x^(n+1)/(n+1)` |
| `1/x` hoặc `x^(-1)` | `ln(abs(x))` |
| `sin(x)` | `-cos(x)` |
| `cos(x)` | `sin(x)` |
| `e^x` | `e^x` |
| `k * f(x)` | `k * ∫f(x)dx` (constant multiple) |
| `f(x) + g(x)` | `∫f(x)dx + ∫g(x)dx` (sum rule) |
| `f(x) - g(x)` | `∫f(x)dx - ∫g(x)dx` (difference rule) |

Mọi hàm khác → trả về `.unsupportedExpression`. UI sẽ hiển thị thông báo rõ ràng.

---

### R11 — `QuickPickData` là pure data, không có logic hay SwiftUI dependency

```swift
// ✅ Đúng — struct đơn giản, testable
struct QuickPickItem {
    let label: String        // "sin(x)"
    let expression: String   // "sin(x)" — điền vào input field
    let category: QuickPickCategory
}

enum QuickPickCategory: String, CaseIterable {
    case basic   = "Cơ bản"
    case trig    = "Lượng giác"
    case expLog  = "Mũ / Log"
    case polar   = "Polar"
}

// Danh sách mẫu — không thay đổi mà không hỏi trước
let quickPickItems: [QuickPickItem] = [
    // Basic
    .init(label: "x",       expression: "x",       category: .basic),
    .init(label: "x²",      expression: "x^2",     category: .basic),
    .init(label: "x³",      expression: "x^3",     category: .basic),
    .init(label: "1/x",     expression: "1/x",     category: .basic),
    .init(label: "√x",      expression: "sqrt(x)", category: .basic),
    .init(label: "|x|",     expression: "abs(x)",  category: .basic),
    // Trig
    .init(label: "sin(x)",  expression: "sin(x)",  category: .trig),
    .init(label: "cos(x)",  expression: "cos(x)",  category: .trig),
    .init(label: "tan(x)",  expression: "tan(x)",  category: .trig),
    .init(label: "sin²(x)", expression: "sin(x)^2", category: .trig),
    .init(label: "cos²(x)", expression: "cos(x)^2", category: .trig),
    // Exp/Log
    .init(label: "eˣ",      expression: "e^x",     category: .expLog),
    .init(label: "ln(x)",   expression: "ln(x)",   category: .expLog),
    .init(label: "log(x)",  expression: "log10(x)", category: .expLog),
    .init(label: "2ˣ",      expression: "2^x",     category: .expLog),
    // Polar
    .init(label: "1+cos(t)", expression: "1+cos(t)", category: .polar),
    .init(label: "sin(2t)", expression: "sin(2*t)", category: .polar),
    .init(label: "cos(3t)", expression: "cos(3*t)", category: .polar),
    .init(label: "t",       expression: "t",        category: .polar),
]

// ❌ Sai — import SwiftUI trong QuickPickData
import SwiftUI
```

---

## 4. Data models — snapshot đầy đủ

### ASTNode

```swift
indirect enum ASTNode {
    case number(Double)
    case variable(String)
    case binary(op: BinaryOp, left: ASTNode, right: ASTNode)
    case unary(op: UnaryOp, operand: ASTNode)
    case function(name: String, args: [ASTNode])
}
```

`indirect` bắt buộc — enum chứa chính nó (cây đệ quy).

### AnalysisResult

```swift
enum AnalysisResult {
    case value(x: Double, y: Double)              // f(a) tại điểm
    case roots([Double])                           // f(x) = 0
    case derivativeSymbolic(expression: String)   // f′(x) dạng biểu thức
    case derivativeAtPoint(x: Double, result: Double) // f′(a) giá trị số
    case antiderivative(expression: String)        // F(x) + C dạng biểu thức
    case integral(a: Double, b: Double, result: Double) // ∫[a,b] giá trị số
}
```

Khi render: dùng `switch` exhaustive, không dùng `if case`.

### GraphViewModel

```swift
@Observable
class GraphViewModel {
    var functions: [FunctionModel] = []
    var viewport: ViewPort = ViewPort()
    var mode: GraphMode = .cartesian
    var angleMode: AngleMode = .radian
}
```

### ViewPort (mặc định)

```swift
struct ViewPort {
    var xMin: Double = -10
    var xMax: Double = 10
    var yMin: Double = -6
    var yMax: Double = 6
}
```

Khi toggle sang Polar: reset về `(-4, 4, -4, 4)` bằng `withAnimation`.

---

## 5. Thứ tự implementation — không được đảo

AI agent chỉ implement chính xác khi dependency đã tồn tại.
Nhảy cóc khiến agent tự bịa interface → compile error hàng loạt.

```
Bước 1 ── Models/
          FunctionModel → AngleMode → GraphMode → AnalysisResult (6 cases)

Bước 2 ── Core/Parser/
          Token → Lexer → ASTNode → ExpressionParser
          ★ Viết XCTest ngay sau bước này

Bước 3 ── Core/Engine/
          Evaluator → SymbolicDifferentiator → SymbolicIntegrator → NumericsEngine
          ★ Viết XCTest ngay sau bước này

Bước 4 ── Core/Geometry/
          ViewPort
          ★ Verify toCanvas() với assert cụ thể

Bước 5 ── Features/Graph/
          GraphViewModel → CartesianRenderer → PolarRenderer → GraphView

Bước 6 ── Features/Analysis/
          QuickPickData → AnalysisViewModel → AnalysisPanel

Bước 7 ── Features/Input/
          InputPanel

Bước 8 ── App/
          ContentView → GraphCalcApp
```

---

## 6. Quy trình làm việc — 3 bước bắt buộc

### Bước A — Output interface trước, không implement ngay

Với mỗi file mới, agent phải output **chỉ public interface** (không có body),
chờ confirm rồi mới implement.

```swift
// Ví dụ output Bước A cho NumericsEngine.swift
struct NumericsEngine {
    func findRoots(
        of expression: String,
        in range: ClosedRange<Double>,
        steps: Int = 500,
        angleMode: AngleMode
    ) -> [Double]

    func integrate(
        _ expression: String,
        from a: Double,
        to b: Double,
        steps: Int = 1000,
        angleMode: AngleMode
    ) -> Double
}
```

**Lý do:** Nếu làm một lần, agent hay "sáng tạo" signature lúc implement,
phá vỡ compatibility với các file đã gọi nó.

### Bước B — Implement với context đầy đủ

Khi implement, bắt buộc có trong context:
- Nội dung thực tế của các file dependency (paste, không mô tả bằng lời)
- Interface đã approve từ Bước A
- Ràng buộc liên quan (Core/ hay Features/, AngleMode cần truyền vào, v.v.)

### Bước C — Viết XCTest ngay (bắt buộc với Core/)

Sau mỗi file trong `Core/`, viết `XCTestCase` tương ứng ngay lập tức.
Test phải cover: happy path, edge case, invalid input.
Không để dồn test lại cuối sprint.

---

## 7. Prompt template chuẩn

Copy template này khi giao task cho agent:

```
## Task
Implement [tên file] trong [thư mục]

## Bước A — Output interface trước
Liệt kê public interface (chỉ signature, không body). Chờ confirm.

## Dependencies (paste nội dung thực tế, không mô tả bằng lời)
[nội dung FunctionModel.swift]
[nội dung ASTNode.swift]
[các file khác mà file này dùng đến]

## Interface đã approve (sau khi Bước A được confirm)
[paste signature từ Bước A]

## Ràng buộc
- [ ] Không import SwiftUI (nếu là Core/ hoặc Models/)
- [ ] Không thay đổi signature đã approve
- [ ] AngleMode phải được truyền vào, không hardcode
- [ ] Handle NaN/Inf nếu là renderer
- [ ] r âm không bị clamp hay bỏ qua (nếu là PolarRenderer)

## Không làm
- Không tự thêm property vào FunctionModel hay GraphViewModel
- Không dùng @StateObject, @Published, ObservableObject
- Không hardcode màu sắc hay magic number
- Không thêm dependency SPM mới
- Không tái cấu trúc thư mục
```

---

## 8. Điểm dễ hallucinate — review bắt buộc

AI agent giỏi viết boilerplate nhưng hay sai ở các phần sau.
**Phải verify thủ công trước khi tiếp tục.**

### SymbolicDifferentiator — verify chain rule và product rule

| Input | Expected |
|---|---|
| `x^2` | `2*x` |
| `sin(x)` | `cos(x)` |
| `sin(x^2)` | `cos(x^2) * 2*x` |
| `x * sin(x)` | `sin(x) + x*cos(x)` |
| `ln(cos(x))` | `-sin(x) / cos(x)` |
| `5` | `0` |

Nếu bất kỳ case nào sai → sửa trước, không tiếp tục.

### SymbolicIntegrator — verify các rule cơ bản

| Input | Expected |
|---|---|
| `5` | `5*x` |
| `x` | `x^2/2` |
| `x^3` | `x^4/4` |
| `1/x` | `ln(abs(x))` |
| `sin(x)` | `-cos(x)` |
| `cos(x)` | `sin(x)` |
| `e^x` | `e^x` |
| `3*sin(x)` | `-3*cos(x)` |
| `sin(x) + x^2` | `-cos(x) + x^3/3` |
| `sin(x^2)` | `.unsupportedExpression` — không bịa kết quả |

Nếu case cuối trả về kết quả thay vì lỗi → đây là hallucination, phải sửa.

### ViewPort.toCanvas — verify bằng assert cụ thể

```swift
let vp = ViewPort(xMin: -10, xMax: 10, yMin: -6, yMax: 6)
let size = CGSize(width: 400, height: 300)

// Gốc tọa độ → trung tâm canvas
assert(vp.toCanvas(0, 0, size: size) == CGPoint(x: 200, y: 150))

// Góc trên trái toán học → góc trên trái canvas
assert(vp.toCanvas(-10, 6, size: size) == CGPoint(x: 0, y: 0))

// Góc dưới phải toán học → góc dưới phải canvas
assert(vp.toCanvas(10, -6, size: size) == CGPoint(x: 400, y: 300))
```

### NumericsEngine.findRoots — bisection đúng cách

- Quét qua các khoảng đổi dấu trước, bisect từng khoảng sau
- Dừng sau **50 vòng lặp** hoặc khi `|f(mid)| < 1e-10`
- Trả về **nhiều nghiệm** nếu có nhiều khoảng đổi dấu
- Không dùng Newton-Raphson — không hỏi thì không tự thay đổi thuật toán

### PolarRenderer — lấy mẫu đủ điểm

- Lấy mẫu θ từ `0` đến `2π`, tối thiểu **1500 bước**
- `r` âm → vẫn convert, không bỏ qua
- Gặp NaN/Inf → nhấc bút, tiếp tục điểm kế

---

## 9. Những quyết định agent KHÔNG được tự thực hiện

Các thay đổi sau phải hỏi và chờ confirm trước:

- Thêm/xóa property trong `FunctionModel`, `GraphViewModel`, `ViewPort`
- Thay đổi thuật toán (bisection → Newton, Simpson → Gauss, v.v.)
- Thêm dependency SPM mới
- Thêm case mới vào `GraphMode`, `AngleMode`, `AnalysisResult`
- Thay đổi viewport mặc định
- Tái cấu trúc thư mục hoặc đổi tên file
- Thêm tính năng nằm ngoài sprint hiện tại

---

## 10. Điểm mạnh và giới hạn của AI trong project này

Hiểu rõ điều này giúp phân chia task hợp lý:

| AI làm tốt | AI dễ sai — cần review kỹ |
|---|---|
| Boilerplate SwiftUI, extension | Coordinate math trong Canvas |
| Implement thuật toán đã có tên | Chain rule lồng nhau, product rule |
| Refactor khi có code gốc | `SymbolicIntegrator` — hay bịa kết quả sai |
| Viết XCTest cho pure function | Gesture conflict (zoom vs pan) |
| Format, helper, Codable extension | Giữ consistency qua nhiều file |
| `QuickPickData` — pure data | Routing logic derivative/integral |

**Không nên giao cho agent tự quyết:**
`ViewPort.toCanvas`, `SymbolicDifferentiator` chain rule phức tạp,
`SymbolicIntegrator` boundary cases, routing logic trong `AnalysisViewModel`,
gesture UX — những thứ này cần verify bằng mắt hoặc test thực tế.

---

## 11. Checklist trước khi hoàn thành một file

```
[ ] File nằm đúng thư mục theo cấu trúc quy định
[ ] Không import SwiftUI (nếu là Core/ hoặc Models/)
[ ] Dùng @Observable, không dùng ObservableObject / @Published
[ ] Signature khớp chính xác interface đã approve (Bước A)
[ ] Không có force unwrap (!) trừ khi có comment giải thích rõ lý do
[ ] AngleMode được truyền vào hàm, không hardcode
[ ] NaN/Inf được xử lý (nếu là renderer)
[ ] r âm không bị clamp hay bỏ qua (nếu là PolarRenderer)
[ ] XCTest đã viết và pass (nếu là Core/)
[ ] ViewPort.toCanvas đã verify với 3 assert cụ thể (nếu có liên quan)
[ ] SymbolicDifferentiator đã verify với 6 case trong bảng (nếu có liên quan)
[ ] SymbolicIntegrator đã verify với 10 case, bao gồm case trả lỗi (nếu có liên quan)
[ ] SymbolicIntegrator trả về Result<ASTNode, IntegrationError>, không trả kết quả sai
[ ] Routing logic derivative/integral nằm trong AnalysisViewModel, không trong Core/
[ ] QuickPickData không import SwiftUI, chỉ là pure data
[ ] Không có magic number — dùng constant hoặc parameter
[ ] Không có property mới trong FunctionModel / GraphViewModel chưa được approve
```

---

## 12. Tham khảo

| File | Nội dung |
|---|---|
| `README.md` | Tổng quan project, tính năng, sprint roadmap |
| `AGENT.md` | File này — quy trình và ràng buộc cho AI agent |
| `GEMINI.md` | Phiên bản tương tự, format theo convention Gemini CLI |
