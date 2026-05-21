import SwiftUI

struct ProgressBar: View {
    let value: Double
    var tint: Color = Palette.accent
    var gradient: Bool = false
    var glow: Bool = false

    private var clampedValue: Double { min(max(value, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            let barWidth = geo.size.width * clampedValue
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.06))

                Capsule().fill(fill)
                    .frame(width: barWidth)
                    .overlay {
                        if glow {
                            Capsule().fill(fill)
                                .blur(radius: 6)
                                .opacity(0.6)
                        }
                    }
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.3), value: clampedValue)
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
            Text("Full Library — gradient + glow")
            ProgressBar(value: 0.42, gradient: true, glow: true)
        }
        VStack(alignment: .leading, spacing: 4) {
            Text("Coverage — 84%")
            ProgressBar(value: 0.84, tint: Palette.green)
        }
    }
    .padding()
}
