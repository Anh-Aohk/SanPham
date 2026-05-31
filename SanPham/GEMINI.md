# GEMINI.md — GraphCalc iOS

Tài liệu này hướng dẫn AI agent làm việc chính xác trên project **GraphCalc iOS**.
Đọc toàn bộ file này trước khi thực hiện bất kỳ thay đổi nào.

---

## Tổng quan project

**GraphCalc** là máy tính đồ thị cá nhân trên iOS, viết bằng SwiftUI + Swift.
Lấy cảm hứng từ Desmos: đồ thị chiếm phần lớn màn hình, input là text field.

| Thông tin | Giá trị |
|---|---|
| Platform | iOS 17+ |
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| State management | `@Observable` (không dùng `ObservableObject`) |
| Toán học | `Expression` (Nick Lockwood, SPM) + `swift-numerics` (Apple) |
| Góc mặc định | **Radian** |

---

## Cấu trúc file — bắt buộc tuân thủ

```
GraphCalc/
├── App/
│   ├── GraphCalcApp.swift
│   └── ContentView.swift
│
├── Models/                          ← Shared data types, không logic
│   ├── FunctionModel.swift
│   ├── AngleMode.swift
│   ├── GraphMode.swift
│   └── AnalysisResult.swift
│
├── Core/                            ← KHÔNG được import SwiftUI
│   ├── Parser/
│   │   ├── Lexer.swift
│   │   ├── Token.swift
│   │   ├── ASTNode.swift
│   │   └── ExpressionParser.swift
│   ├── Engine/
│   │   ├── Evaluator.swift
│   │   ├── SymbolicDifferentiator.swift
│   │   └── NumericsEngine.swift
│   └── Geometry/
│       └── ViewPort.swift
│
├── Features/
│   ├── Graph/
│   │   ├── GraphViewModel.swift
│   │   ├── GraphView.swift
│   │   ├── CartesianRenderer.swift
│   │   └── PolarRenderer.swift
│   ├── Analysis/
│   │   ├── AnalysisViewModel.swift
│   │   └── AnalysisPanel.swift
│   └── Input/
│       └── InputPanel.swift
│
└── Shared/
    ├── Color+Codable.swift
    ├── Double+Formatting.swift
    └── ToggleChip.swift
```

---

## Quy tắc cứng — không được vi phạm

### R1 — `Core/` không được import SwiftUI

Mọi file trong `Core/` và `Models/` phải hoạt động độc lập với SwiftUI.
Compiler phải pass khi build target test riêng cho `Core/`.

```swift
// ✅ Đúng — Core/Engine/NumericsEngine.swift
import Foundation
import Numerics

// ❌ Sai
import SwiftUI
```

### R2 — Dùng `@Observable`, không dùng `ObservableObject`

```swift
// ✅ Đúng
@Observable
class GraphViewModel { ... }

// ❌ Sai
class GraphViewModel: ObservableObject {
    @Published var functions: [FunctionModel] = []
}
```

### R3 — Không thay đổi public interface khi implement

Nếu interface đã được define (trong task hoặc file hiện tại), implement phải khớp chính xác signature. Không được thêm, bớt, hay đổi tên parameter.

### R4 — `FunctionModel` phải là struct, Identifiable, Codable

```swift
struct FunctionModel: Identifiable, Codable {
    let id: UUID
    var expression: String
    var color: Color        // cần Color+Codable.swift extension
    var isVisible: Bool
    var isPolar: Bool
}
```

### R5 — Radian là mặc định, Degree là opt-in

Mọi hàm trig trong `Evaluator` phải nhận `AngleMode` và convert khi cần:

```swift
func sin(_ x: Double, mode: AngleMode) -> Double {
    Foundation.sin(mode == .degree ? x * .pi / 180 : x)
}
```

Không bao giờ hardcode radian hay degree trong logic tính toán.

### R6 — `r` âm trong polar là hợp lệ

Khi vẽ đồ thị polar, không được clamp hoặc bỏ qua giá trị `r < 0`.
Convert tự nhiên: `x = r * cos(θ)`, `y = r * sin(θ)`.

### R7 — Handle NaN và Inf trong renderer

Khi duyệt qua mảng điểm để vẽ, gặp `NaN` hoặc `Inf` phải "nhấc bút":

```swift
guard x.isFinite && y.isFinite else {
    started = false
    continue
}
```

---

## Data models chính

### FunctionModel

```swift
struct FunctionModel: Identifiable, Codable {
    let id: UUID
    var expression: String      // "sin(x)", "1+cos(t)"
    var color: Color
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

`indirect` là bắt buộc — enum phải chứa chính nó (cây đệ quy).

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
        // py bị lật: y toán học tăng lên trên, y Canvas tăng xuống dưới
        return CGPoint(x: px, y: py)
    }
}
```

**Đây là hàm nhạy cảm nhất trong project.** Không được sửa công thức `py`
mà không có test verify trước.

### AnalysisResult

```swift
enum AnalysisResult {
    case value(x: Double, y: Double)
    case roots([Double])
    case derivative(expression: String)
    case integral(a: Double, b: Double, result: Double)
}
```

Dùng `switch` exhaustive khi render, không dùng `if case`.

### GraphViewModel

```swift
@Observable
class GraphViewModel {
    var functions: [FunctionModel] = []
    var viewport: ViewPort = ViewPort()
    var mode: GraphMode = .cartesian
    var angleMode: AngleMode = .radian     // mặc định radian
}
```

### AngleMode / GraphMode

```swift
enum AngleMode { case radian, degree }
enum GraphMode  { case cartesian, polar }
```

---

## Thứ tự implementation bắt buộc

Dependency phải tồn tại trước khi implement file phụ thuộc vào nó.
Không được đảo thứ tự này:

```
Bước 1 — Models/
  FunctionModel → AngleMode → GraphMode → AnalysisResult

Bước 2 — Core/Parser/
  Token → Lexer → ASTNode → ExpressionParser
  ✓ Viết XCTest ngay sau bước này

Bước 3 — Core/Engine/
  Evaluator → SymbolicDifferentiator → NumericsEngine
  ✓ Viết XCTest ngay sau bước này

Bước 4 — Core/Geometry/
  ViewPort
  ✓ Test toCanvas() với giá trị cụ thể

Bước 5 — Features/Graph/
  GraphViewModel → CartesianRenderer → PolarRenderer → GraphView

Bước 6 — Features/Analysis/
  AnalysisViewModel → AnalysisPanel

Bước 7 — Features/Input/
  InputPanel

Bước 8 — App/
  ContentView → GraphCalcApp
```

---

## Quy trình làm việc theo từng task

### Bước A — Xác nhận interface trước khi implement

Với mỗi file mới, output public interface trước (không có body):

```swift
// Chỉ signature, chưa implement
struct NumericsEngine {
    func findRoots(
        of expression: String,
        in range: ClosedRange<Double>,
        steps: Int,
        angleMode: AngleMode
    ) -> [Double]

    func integrate(
        _ expression: String,
        from a: Double,
        to b: Double,
        steps: Int,
        angleMode: AngleMode
    ) -> Double
}
```

Chờ confirm trước khi viết implementation.

### Bước B — Implement với đầy đủ context

Khi implement, context tối thiểu cần có:
- File đang viết + mô tả
- Tất cả file nó `import` hoặc dùng type từ đó
- Signature đã được approve từ Bước A

### Bước C — Viết test ngay (chỉ cho Core/)

Sau mỗi file trong `Core/`, viết XCTestCase tương ứng.
Test phải cover: happy path, edge case, invalid input.

---

## Prompt template chuẩn

Dùng template này khi nhận task implement một file:

```
## Task
Implement [tên file] trong [thư mục]

## Dependencies (nội dung thực tế)
[paste nội dung các file phụ thuộc]

## Interface đã approve
[paste public interface từ Bước A]

## Ràng buộc
- [ ] Không import SwiftUI (nếu là Core/)
- [ ] Không thay đổi signature đã approve
- [ ] Xử lý NaN/Inf nếu là renderer
- [ ] AngleMode phải được truyền vào, không hardcode
- [ ] Tuân thủ thứ tự implementation

## Không làm
- Không tự thêm property vào FunctionModel
- Không dùng @StateObject hay @Published
- Không hardcode màu sắc hay kích thước
- Không bỏ qua r âm trong polar renderer
```

---

## Những phần cần review kỹ — dễ sai

### SymbolicDifferentiator

Verify thủ công với các case này sau khi implement:

| Input | Expected output |
|---|---|
| `x^2` | `2*x` |
| `sin(x)` | `cos(x)` |
| `sin(x^2)` | `cos(x^2) * 2*x` (chain rule) |
| `x * sin(x)` | `sin(x) + x*cos(x)` (product rule) |
| `ln(cos(x))` | `-sin(x)/cos(x)` |
| `5` (hằng số) | `0` |

Nếu bất kỳ case nào sai, không merge — sửa trước.

### ViewPort.toCanvas

Verify với giá trị cụ thể:

```swift
let vp = ViewPort(xMin: -10, xMax: 10, yMin: -6, yMax: 6)
let size = CGSize(width: 400, height: 300)

// Gốc tọa độ (0,0) phải ra trung tâm canvas
assert(vp.toCanvas(0, 0, size: size) == CGPoint(x: 200, y: 150))

// Góc trên trái toán học (-10, 6) phải ra (0, 0) canvas
assert(vp.toCanvas(-10, 6, size: size) == CGPoint(x: 0, y: 0))
```

### NumericsEngine.findRoots (bisection)

- Quét qua các khoảng đổi dấu trước, rồi mới bisect trong từng khoảng
- Dừng sau 50 vòng lặp hoặc khi `|f(mid)| < 1e-10`
- Trả về nhiều nghiệm nếu có nhiều khoảng đổi dấu

---

## Những thứ AI agent không được tự quyết

Những quyết định sau đây phải hỏi trước, không được tự suy:

- Thêm property mới vào `FunctionModel` hoặc `GraphViewModel`
- Thay đổi thuật toán tìm nghiệm (bisection → Newton hay khác)
- Thêm dependency SPM mới
- Thay đổi viewport mặc định
- Thêm GraphMode hoặc AngleMode mới
- Tái cấu trúc thư mục

---

## Checklist trước khi hoàn thành một file

```
[ ] File nằm đúng thư mục theo cấu trúc quy định
[ ] Import đúng (Core/ không có SwiftUI)
[ ] Signature khớp với interface đã approve
[ ] Không có force unwrap (!) trừ khi có comment giải thích
[ ] NaN/Inf được xử lý (renderer)
[ ] AngleMode được truyền vào hàm, không hardcode
[ ] r âm không bị bỏ qua (polar)
[ ] XCTest đã viết (nếu là Core/)
[ ] ViewPort.toCanvas đã verify với assert (nếu có liên quan)
```

---

## Tham khảo nhanh

- README.md — tổng quan tính năng và sprint roadmap
- Ngôn ngữ mặc định trong code: **tiếng Anh** (tên biến, comment, doc comment)
- Ngôn ngữ giao tiếp với user: **tiếng Việt**
- iOS target: **17.0+**
- Không cần backward compatibility
