import SwiftUI

struct ScalingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.interpolatingSpring(stiffness: 320, damping: 22),
                       value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScalingButtonStyle {
    static var scaling: ScalingButtonStyle { .init() }
}
