# GraphCalc iOS

Máy tính đồ thị cá nhân xây dựng bằng SwiftUI, lấy cảm hứng từ Desmos.
Hỗ trợ vẽ hàm Cartesian và Polar, tìm nghiệm, đạo hàm symbolic, tích phân số trị, và chuyển đổi Radian/Degree.

> Dự án cá nhân / học tập — không publish App Store.

---

## Tính năng (MVP)

| Tính năng | Mô tả |
|---|---|
| Vẽ hàm cơ bản | `sin(x)`, `x^2 + 1`, `ln(x)`, ... |
| Nhiều hàm cùng lúc | Mỗi hàm một màu, bật/tắt riêng |
| Zoom & Pan | Pinch to zoom, drag to pan |
| Tính tại điểm | Nhập `a` → hiển thị `f(a)` trên đồ thị |
| Tìm nghiệm | Tìm `x` sao cho `f(x) = 0` (bisection, chính xác đến `1e-10`) |
| Đạo hàm — symbolic | Nhập `x` (hoặc để trống) → tìm `f′(x)` dạng biểu thức |
| Đạo hàm — tại điểm | Nhập số `a` → tính giá trị `f′(a)` |
| Nguyên hàm — symbolic | Không nhập cận → tìm `F(x)` dạng biểu thức (+ C) |
| Nguyên hàm — tích phân xác định | Nhập cận `[a, b]` → tính `∫[a,b] f(x)dx`, tô màu vùng diện tích |
| Quick-pick | Bảng chọn nhanh hàm phổ biến theo danh mục, không cần gõ |
| Rad / Deg | Toggle trên toolbar, mặc định **Radian** |
| Đồ thị Polar | Nhập `r = f(θ)`, toggle Polar / Cartesian |

---

## Yêu cầu

- Xcode 15+
- iOS 17+
- Swift 5.9+

---

## Thư viện (SPM)

| Package | Mục đích | URL |
|---|---|---|
| `Expression` — Nick Lockwood | Parse và evaluate biểu thức | `https://github.com/nicklockwood/Expression` |
| `swift-numerics` — Apple | Tính toán số học chính xác | `https://github.com/apple/swift-numerics` |

---

## Cấu trúc file

```
GraphCalc/
├── App/
│   ├── GraphCalcApp.swift
│   └── ContentView.swift
│
├── Models/                          ← Shared data types, không có logic
│   ├── FunctionModel.swift          # struct, Identifiable, Codable
│   ├── AngleMode.swift              # enum: .radian, .degree
│   ├── GraphMode.swift              # enum: .cartesian, .polar
│   └── AnalysisResult.swift         # enum với associated values
│
├── Core/                            ← KHÔNG import SwiftUI — testable độc lập
│   ├── Parser/
│   │   ├── Lexer.swift              # String → [Token]
│   │   ├── Token.swift              # enum Token
│   │   ├── ASTNode.swift            # indirect enum, cây biểu thức
│   │   └── ExpressionParser.swift   # [Token] → ASTNode
│   ├── Engine/
│   │   ├── Evaluator.swift               # ASTNode + x → Double
│   │   ├── SymbolicDifferentiator.swift  # ASTNode → ASTNode (f′)
│   │   ├── SymbolicIntegrator.swift      # ASTNode → ASTNode (F(x)+C) — basic rules
│   │   └── NumericsEngine.swift          # bisection, Simpson's rule
│   └── Geometry/
│       └── ViewPort.swift           # toCanvas(_:size:) — convert tọa độ
│
├── Features/                        ← Theo feature, không theo layer
│   ├── Graph/
│   │   ├── GraphViewModel.swift     # @Observable, functions, viewport, mode
│   │   ├── GraphView.swift          # SwiftUI Canvas, gesture handler
│   │   ├── CartesianRenderer.swift  # vẽ lưới vuông + đường cong
│   │   └── PolarRenderer.swift      # vẽ lưới cực + đường cong polar
│   ├── Analysis/
│   │   ├── AnalysisViewModel.swift  # routing logic: symbolic vs numeric
│   │   ├── AnalysisPanel.swift      # UI với tab Derivative / Integral
│   │   └── QuickPickData.swift      # danh sách hàm phổ biến theo danh mục
│   └── Input/
│       └── InputPanel.swift         # TextField hàm, list màu, toggles
│
└── Shared/
    ├── Color+Codable.swift          # extension Color: Codable
    ├── Double+Formatting.swift      # .formatted(decimalPlaces:)
    └── ToggleChip.swift             # component dùng chung cho toggles
```

---

## Kiến trúc — 3 layer

```
┌─────────────────────────────────────────┐
│  Features/   SwiftUI Views + ViewModels  │  ← có thể import SwiftUI
├─────────────────────────────────────────┤
│  Models/     Data types thuần Swift      │  ← không import SwiftUI
├─────────────────────────────────────────┤
│  Core/       Parser + Engine + Geometry  │  ← không import SwiftUI
└─────────────────────────────────────────┘
```

Quy tắc cứng: `Core/` và `Models/` không được `import SwiftUI`.
Nhờ đó toàn bộ logic toán học có thể test bằng XCTest mà không cần simulator.

### Data flow

```
User nhập biểu thức
       ↓
Lexer → Token → ASTNode (ExpressionParser)
       ↓
Evaluator.evaluate(node:x:angleMode:)
       ↓
GraphViewModel tập hợp mảng điểm
       ↓
ViewPort.toCanvas(_:size:) — toán học → CGPoint
       ↓
Canvas.stroke(path) — render lên màn hình
```

---

## Data models chính

### FunctionModel

```swift
struct FunctionModel: Identifiable, Codable {
    let id: UUID
    var expression: String      // "sin(x)", "1+cos(t)"
    var color: Color            // cần Color+Codable.swift
    var isVisible: Bool = true
    var isPolar: Bool = false
}
```

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

### ViewPort

```swift
struct ViewPort {
    var xMin: Double = -10
    var xMax: Double = 10
    var yMin: Double = -6
    var yMax: Double = 6

    func toCanvas(_ mathX: Double, _ mathY: Double, size: CGSize) -> CGPoint {
        let px = (mathX - xMin) / (xMax - xMin) * size.width
        let py = (1 - (mathY - yMin) / (yMax - yMin)) * size.height
        // py lật vì y Canvas tăng xuống dưới, y toán học tăng lên trên
        return CGPoint(x: px, y: py)
    }
}
```

### AnalysisResult

```swift
enum AnalysisResult {
    // f(a) tại điểm
    case value(x: Double, y: Double)

    // Tìm nghiệm f(x) = 0
    case roots([Double])

    // Đạo hàm: nhập "x" hoặc để trống → symbolic expression
    case derivativeSymbolic(expression: String)

    // Đạo hàm: nhập số a → giá trị f′(a)
    case derivativeAtPoint(x: Double, result: Double)

    // Nguyên hàm: không nhập cận → symbolic expression F(x) + C
    case antiderivative(expression: String)

    // Tích phân xác định: nhập [a, b] → giá trị số + tô màu vùng
    case integral(a: Double, b: Double, result: Double)
}
```

**Routing logic trong `AnalysisViewModel`:**
- Derivative tab: parse input — nếu là `Double` → `.derivativeAtPoint`; nếu là `"x"` hoặc rỗng → `.derivativeSymbolic`
- Integral tab: nếu cả `a` và `b` đều có giá trị → `.integral`; nếu một trong hai rỗng → `.antiderivative`

### GraphViewModel

```swift
@Observable
class GraphViewModel {
    var functions: [FunctionModel] = []
    var viewport: ViewPort = ViewPort()
    var mode: GraphMode = .cartesian
    var angleMode: AngleMode = .radian   // mặc định radian
}
```

---

## Thứ tự implementation

Dependency phải tồn tại trước khi viết file phụ thuộc vào nó:

```
1. Models/          — FunctionModel, AngleMode, GraphMode, AnalysisResult (6 cases)
2. Core/Parser/     — Lexer → Token → ASTNode → ExpressionParser  ✓ test
3. Core/Engine/     — Evaluator → SymbolicDifferentiator
                      → SymbolicIntegrator → NumericsEngine  ✓ test
4. Core/Geometry/   — ViewPort  ✓ test
5. Features/Graph/  — GraphViewModel → Renderers → GraphView
6. Features/Analysis/ — QuickPickData → AnalysisViewModel → AnalysisPanel
7. Features/Input/  — InputPanel
8. App/             — ContentView → GraphCalcApp
```

`✓ test` — viết XCTest ngay sau khi hoàn thành bước đó, không để dồn.

---

## Roadmap (Sprint)

### Sprint 1 — Parser + Canvas cơ bản
- Lexer tách token, build AST, `evaluate(x:)`
- Canvas vẽ trục tọa độ + đường cong
- Deliverable: nhập `sin(x)` → thấy đồ thị ngay

### Sprint 2 — Viewport + UX Desmos-style
- Zoom bằng `MagnifyGesture`, pan bằng `DragGesture`
- State `xMin/xMax/yMin/yMax` trong `ViewPort`
- Thêm nhiều hàm, mỗi hàm một màu
- Toggle Rad/Deg ở toolbar
- Deliverable: trải nghiệm giống Desmos trên iPhone

### Sprint 3 — Tính toán từ hàm
- `f(a)`: evaluate tại điểm, vẽ dot + label trên Canvas
- Tìm nghiệm: quét đổi dấu → bisection 50 vòng lặp (chính xác đến `1e-10`)
- Deliverable: `AnalysisPanel` hoàn chỉnh

### Sprint 4 — Giải tích nâng cao
- **Đạo hàm dual-mode:** input là `x`/rỗng → symbolic `f′(x)`; input là số → evaluate `f′(a)`
- **Nguyên hàm dual-mode:** không có cận → symbolic `F(x) + C`; có cận `[a,b]` → Simpson's rule + tô màu
- **`SymbolicIntegrator`:** các rule cơ bản — hằng số, `x^n`, `sin`, `cos`, `e^x`, `ln(x)`, constant multiple, sum/difference
- **Quick-pick panel:** danh sách hàm phổ biến theo danh mục (Basic, Trig, Exp/Log, Polar), chọn là điền vào input ngay
- Deliverable: không cần gõ một chữ vẫn dùng được đầy đủ tính năng giải tích

### Sprint 5 — Đồ thị Polar
- Parse `r = f(θ)`, lấy mẫu `θ ∈ [0, 2π]` (~1500 bước)
- Convert `x = r·cos(θ)`, `y = r·sin(θ)` — `r` âm hợp lệ, không clamp
- Vẽ lưới cực: vòng tròn đồng tâm + tia góc mỗi 30°
- Toggle Polar / Cartesian, tự reset viewport khi đổi mode
- Deliverable: `r = 1 + cos(θ)` vẽ được hình tim

---

## Ghi chú kỹ thuật

**Radian mặc định.** `AngleMode` phải được truyền vào mọi hàm trig trong `Evaluator`, không hardcode.

**`r` âm trong polar là hợp lệ.** Không clamp, không bỏ qua — convert tự nhiên sang Cartesian.

**NaN và Inf trong renderer.** Gặp điểm không finite thì "nhấc bút" (reset `Path.move`), không crash.

**Đạo hàm dual-mode.** `AnalysisViewModel` parse input string: `Double(input) != nil` → numeric tại điểm; ngược lại → symbolic. Không để logic này lọt vào `Core/`.

**Nguyên hàm dual-mode.** Nếu cả `boundA` và `boundB` đều có giá trị → `NumericsEngine.integrate` + tô màu; ngược lại → `SymbolicIntegrator`. Kết quả symbolic luôn kèm `+ C`.

**`SymbolicIntegrator` có giới hạn.** Chỉ hỗ trợ: hằng số, `x^n` (n ≠ -1), `1/x`, `sin(x)`, `cos(x)`, `e^x`, constant multiple, sum/difference. Các hàm phức tạp hơn (chain rule ngược) sẽ trả về lỗi rõ ràng, không bịa kết quả.

**Quick-pick** là pure data (`QuickPickData.swift`) — không có logic, chỉ là array of `(label, expression)`. `AnalysisPanel` đọc và render thành scrollable chip row.

**Symbolic derivative** hỗ trợ: `x^n`, `sin`, `cos`, `tan`, `ln`, `exp`, chain rule, product rule cơ bản.

**`ViewPort.toCanvas`** là hàm nhạy cảm nhất — công thức `py` có dấu lật y. Verify bằng assert trước khi dùng.

**Simpson's rule** thay vì trapezoidal cho tích phân số trị — chính xác hơn với cùng số bước `n`.

---

## Làm việc với AI agent

Project có hai file hướng dẫn cho AI agent:

| File | Dùng khi |
|---|---|
| `AGENT.md` | Hướng dẫn chung — áp dụng cho mọi agent (Claude, Cursor, Copilot...) |
| `GEMINI.md` | Convention riêng theo format Gemini CLI |

Cả hai file đều bao gồm: quy tắc cứng, thứ tự implementation, prompt template,
bảng verify thủ công cho những phần dễ sai, và checklist trước khi hoàn thành file.

---

## License

MIT — dự án cá nhân / học tập.
