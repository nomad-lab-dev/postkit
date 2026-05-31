import SwiftUI

// MARK: - Localized string extraction (Mirror-based, iOS 18+)

func localizedString(for key: LocalizedStringKey) -> String {
    let mirror = Mirror(reflecting: key)
    if let keyStr = mirror.children.first(where: { $0.label == "key" })?.value as? String {
        return NSLocalizedString(keyStr, bundle: .main, comment: "")
    }
    return ""
}

// MARK: - Typewriter text (eyebrow / mono labels)

/// Character-by-character reveal matching the MagicDemoCard chat bubble typing pattern.
struct TypewriterText: View {
    let text: String
    let font: Font
    let color: Color
    var tracking: CGFloat = 0.54
    var show: Bool
    var onFinished: (() -> Void)? = nil

    @State private var revealed: String = ""
    @State private var showCursor: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(revealed.isEmpty ? " " : revealed)
                .font(font)
                .foregroundStyle(revealed.isEmpty ? Color.clear : color)
                .tracking(tracking)
                .textCase(.uppercase)
            if showCursor {
                Rectangle()
                    .fill(color)
                    .frame(width: 1.5, height: 8)
                    .padding(.leading, 1)
            }
        }
        .task(id: show) {
            guard show else { return }
            revealed = ""
            showCursor = true
            for char in text {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int.random(in: 30...65)))
                revealed.append(char)
            }
            showCursor = false
            onFinished?()
        }
    }
}

// MARK: - Typewriter headline (multi-segment, mixed fonts/colors)

struct HeadlineSegment {
    let text: String
    let font: Font
    let color: Color
}

/// Reveals a multi-styled headline character-by-character.
/// An invisible spaceholder prevents layout shifts during typing.
struct TypewriterHeadline: View {
    let segments: [HeadlineSegment]
    var show: Bool
    var onFinished: (() -> Void)? = nil

    @State private var revealedCount: Int = 0

    private var totalLength: Int {
        segments.reduce(0) { $0 + $1.text.count }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Invisible full text — reserves layout size so nothing shifts
            buildText(reveal: totalLength).opacity(0)
            // Revealed portion grows character by character
            buildText(reveal: revealedCount)
        }
        .fixedSize(horizontal: false, vertical: true)
        .task(id: show) {
            guard show else { return }
            revealedCount = 0
            while revealedCount < totalLength {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int.random(in: 15...40)))
                revealedCount += 1
            }
            onFinished?()
        }
    }

    private func buildText(reveal count: Int) -> Text {
        var remaining = count
        var result = Text("")
        for seg in segments {
            guard remaining > 0 else { break }
            let chars = Array(seg.text)
            let toReveal = min(remaining, chars.count)
            result = result + Text(verbatim: String(chars.prefix(toReveal)))
                .font(seg.font)
                .foregroundColor(seg.color)
            remaining -= toReveal
        }
        return result
    }
}

// MARK: - Entrance modifiers

extension View {
    func obEntrance(show: Bool) -> some View {
        self
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 10)
            .blur(radius: show ? 0 : 4)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: show)
    }

    func obCTAEntrance(show: Bool) -> some View {
        self
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 50)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: show)
    }
}
