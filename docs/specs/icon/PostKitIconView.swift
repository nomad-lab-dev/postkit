import SwiftUI

// MARK: - PostKit App Icon
//
// Usage in app:
//   PostKitIconView()
//     .frame(width: 120, height: 120)
//     .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
//
// Export as PNG (run from a @main SwiftUI App on macOS):
//   let renderer = ImageRenderer(content: PostKitIconView().frame(width: 1024, height: 1024))
//   renderer.scale = 1.0
//   if let png = renderer.nsImage { /* save to disk */ }

struct PostKitIconView: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                IconBackground()
                ApertureDisc(size: size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Background

private struct IconBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.05, blue: 0.22), // deep indigo
                Color(red: 0.34, green: 0.16, blue: 0.54)  // rich violet
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Aperture

private struct ApertureDisc: View {
    let size: CGFloat

    private var outerR: CGFloat { size * 0.40 }
    private var innerR: CGFloat { size * 0.12 }

    var body: some View {
        ZStack {
            // Gold disc
            Circle()
                .fill(goldGradient)
                .frame(width: outerR * 2, height: outerR * 2)

            // 6 dark gap wedges — 60° apart, +15° twist for iris sweep
            ForEach(0..<6, id: \.self) { i in
                ApertureGapShape(
                    angle: CGFloat(i) * (.pi / 3) + (.pi / 12),
                    outerFraction: 0.40,
                    innerFraction: 0.126,
                    outerHalfAngle: .pi / 22,  // ~8.2°
                    innerHalfAngle: .pi / 110  // ~1.6°
                )
                .fill(gapGradient)
            }

            // Center dark void with subtle glow
            Circle()
                .fill(centerGradient)
                .frame(width: innerR * 1.85, height: innerR * 1.85)
        }
    }

    // Champagne → gold radial — off-center highlight for 3D feel
    private var goldGradient: some ShapeStyle {
        RadialGradient(
            colors: [
                Color(red: 0.97, green: 0.90, blue: 0.64), // bright champagne
                Color(red: 0.88, green: 0.76, blue: 0.42), // warm gold
                Color(red: 0.72, green: 0.57, blue: 0.22)  // deep bronze edge
            ],
            center: .init(x: 0.38, y: 0.32),
            startRadius: 0,
            endRadius: outerR
        )
    }

    // Dark indigo gap — matches background
    private var gapGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.05, blue: 0.22).opacity(0.97),
                Color(red: 0.18, green: 0.09, blue: 0.38).opacity(0.88)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Center void — deep dark with subtle violet glow at edge
    private var centerGradient: some ShapeStyle {
        RadialGradient(
            colors: [
                Color(red: 0.03, green: 0.01, blue: 0.10),
                Color(red: 0.06, green: 0.03, blue: 0.18),
                Color(red: 0.22, green: 0.10, blue: 0.42).opacity(0.6)
            ],
            center: .center,
            startRadius: 0,
            endRadius: innerR * 1.1
        )
    }
}

// MARK: - Aperture Gap Shape
//
// Each gap = a wedge that fans from a narrow inner slit to a wider outer slice.
// 6 gaps arranged with +15° rotational offset = classic iris "swept blade" look.

private struct ApertureGapShape: Shape {
    let angle: CGFloat         // center angle of the gap (radians)
    let outerFraction: CGFloat // outer radius as fraction of min(w,h)
    let innerFraction: CGFloat // inner radius as fraction of min(w,h)
    let outerHalfAngle: CGFloat // half-width at outer edge (radians)
    let innerHalfAngle: CGFloat // half-width at inner edge (radians)

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let s = min(rect.width, rect.height)
        let outerR = s * outerFraction
        let innerR = s * innerFraction

        let oStart = angle - outerHalfAngle
        let oEnd   = angle + outerHalfAngle
        let iStart = angle - innerHalfAngle
        let iEnd   = angle + innerHalfAngle

        var p = Path()
        // Inner edge — narrow slit
        p.move(to: pt(center: center, r: innerR, a: iStart))
        p.addLine(to: pt(center: center, r: outerR, a: oStart))
        // Outer arc — fan out
        p.addArc(center: center, radius: outerR,
                 startAngle: .radians(oStart), endAngle: .radians(oEnd),
                 clockwise: false)
        // Back to inner edge, other side
        p.addLine(to: pt(center: center, r: innerR, a: iEnd))
        // Inner arc close
        p.addArc(center: center, radius: innerR,
                 startAngle: .radians(iEnd), endAngle: .radians(iStart),
                 clockwise: true)
        p.closeSubpath()
        return p
    }

    private func pt(center: CGPoint, r: CGFloat, a: CGFloat) -> CGPoint {
        CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
    }
}

// MARK: - Preview

#Preview("Icon — 1024pt") {
    PostKitIconView()
        .frame(width: 400, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 88, style: .continuous))
        .padding(40)
        .background(Color.gray.opacity(0.15))
}

#Preview("Icon — Grid sizes") {
    HStack(spacing: 20) {
        ForEach([180, 120, 76, 60, 40], id: \.self) { size in
            VStack(spacing: 6) {
                PostKitIconView()
                    .frame(width: CGFloat(size), height: CGFloat(size))
                    .clipShape(RoundedRectangle(
                        cornerRadius: CGFloat(size) * 0.2237,
                        style: .continuous)
                    )
                Text("\(size)pt")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding(30)
    .background(Color.gray.opacity(0.1))
}

// MARK: - PNG Export Helper (macOS only)
//
// Drop this in a macOS target or a SwiftUI Playground to export the 1024×1024 PNG:
//
// #if os(macOS)
// func exportIconPNG(to url: URL) {
//     let view = PostKitIconView()
//         .frame(width: 1024, height: 1024)
//         .clipShape(RoundedRectangle(cornerRadius: 229, style: .continuous))
//     let renderer = ImageRenderer(content: view)
//     renderer.scale = 1.0
//     if let image = renderer.nsImage,
//        let tiff = image.tiffRepresentation,
//        let bitmap = NSBitmapImageRep(data: tiff),
//        let png = bitmap.representation(using: .png, properties: [:]) {
//         try? png.write(to: url)
//     }
// }
// #endif
