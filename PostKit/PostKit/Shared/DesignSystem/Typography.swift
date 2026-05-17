import SwiftUI

enum Typography {
    static let largeTitle  = Font.system(.largeTitle, design: .default, weight: .bold)
    static let title       = Font.system(.title, design: .default, weight: .semibold)
    static let title2      = Font.system(.title2, design: .default, weight: .semibold)
    static let title3      = Font.system(.title3, design: .default, weight: .semibold)
    static let headline    = Font.system(.headline)
    static let body        = Font.system(.body)
    static let callout     = Font.system(.callout)
    static let subheadline = Font.system(.subheadline, design: .default, weight: .medium)
    static let footnote    = Font.system(.footnote)
    static let caption     = Font.system(.caption, design: .default, weight: .medium)
    static let caption2    = Font.system(.caption2, design: .default, weight: .medium)
    static let mono        = Font.system(.footnote, design: .monospaced).weight(.medium)
    static let display     = Font.system(size: 40, weight: .bold).leading(.tight)
}
