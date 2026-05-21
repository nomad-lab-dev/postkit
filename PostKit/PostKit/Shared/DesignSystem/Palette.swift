import SwiftUI
import UIKit

enum Palette {
    // MARK: - Surfaces

    static let bg = Color(UIColor.systemGroupedBackground)
    static let surface = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.72)
    })
    static let glass = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.06)
            : UIColor.white.withAlphaComponent(0.55)
    })
    static let glassStrong = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.white.withAlphaComponent(0.78)
    })
    static let border = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.08)
    })

    // MARK: - Text

    static let text  = Color(UIColor.label)
    static let text2 = Color(UIColor.secondaryLabel)
    static let text3 = Color(UIColor.tertiaryLabel)
    static let text4 = Color(UIColor.quaternaryLabel)

    // MARK: - Accents

    static let accent = Color(UIColor.systemBlue)
    static let green  = Color(UIColor.systemGreen)
    static let yellow = Color(UIColor.systemYellow)
    static let orange = Color(UIColor.systemOrange)
    static let red    = Color(UIColor.systemRed)
    static let purple = Color(UIColor.systemPurple)
    static let pink   = Color(UIColor.systemPink)
    static let cyan   = Color(UIColor.systemCyan)

    // MARK: - Tints

    static let accentTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.systemBlue.withAlphaComponent(0.18)
            : UIColor.systemBlue.withAlphaComponent(0.08)
    })
    static let greenTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.systemGreen.withAlphaComponent(0.18)
            : UIColor.systemGreen.withAlphaComponent(0.10)
    })
    static let yellowTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.systemYellow.withAlphaComponent(0.18)
            : UIColor.systemYellow.withAlphaComponent(0.10)
    })
    static let orangeTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.systemOrange.withAlphaComponent(0.18)
            : UIColor.systemOrange.withAlphaComponent(0.10)
    })
    static let redTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.systemRed.withAlphaComponent(0.18)
            : UIColor.systemRed.withAlphaComponent(0.08)
    })
    static let purpleTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.systemPurple.withAlphaComponent(0.18)
            : UIColor.systemPurple.withAlphaComponent(0.08)
    })
    static let cyanTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.systemCyan.withAlphaComponent(0.18)
            : UIColor.systemCyan.withAlphaComponent(0.10)
    })

    // MARK: - Semantic

    static let onAccent = Color.white
    static let onDark   = Color.white
    static let scrim = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.72)
            : UIColor.black.withAlphaComponent(0.55)
    })
    static let placeholder = Color(UIColor.systemGray5)
    static let track = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.06)
    })
    static let neutralTint = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.05)
    })

    static func secondaryText(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? text2 : text3
    }

    static func color(forHex hex: String) -> Color {
        Color(hex: hex)
    }
}
