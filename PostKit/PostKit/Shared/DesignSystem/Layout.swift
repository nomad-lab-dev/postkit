import SwiftUI

enum Layout {
    enum Padding {
        static let screen = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        static let card   = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        static let row    = EdgeInsets(top: 8,  leading: 16, bottom: 8,  trailing: 16)
        static let chip   = EdgeInsets(top: 4,  leading: 10, bottom: 4,  trailing: 10)
        static let button = EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        static let sheet  = EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20)
    }

    enum Stack {
        static let tight: CGFloat = 4
        static let cozy:  CGFloat = 8
        static let comfy: CGFloat = 12
        static let roomy: CGFloat = 20
        static let loose: CGFloat = 32
    }

    enum Grid {
        static let photoGrid: CGFloat = 4
        static let bento:     CGFloat = 8
        static let pills:     CGFloat = 6
    }
}
