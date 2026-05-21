import SwiftUI

struct ProgressBar: View {
    let value: Double
    var tint: Color = Palette.accent
    var gradient: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.06))
                Capsule().fill(fill)
                    .frame(width: geo.size.width * value)
            }
        }
        .frame(height: 6)
    }

    var fill: some ShapeStyle {
        gradient
            ? AnyShapeStyle(LinearGradient(colors: [Palette.accent, Palette.purple], startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(tint)
    }
}

#Preview("Progress Bars") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quick Scan — 70%")
            ProgressBar(value: 0.7)
        }
        VStack(alignment: .leading, spacing: 4) {
            Text("Full Library — gradient")
            ProgressBar(value: 0.42, gradient: true)
        }
        VStack(alignment: .leading, spacing: 4) {
            Text("Coverage — 84%")
            ProgressBar(value: 0.84, tint: Palette.green)
        }
    }
    .padding()
}
