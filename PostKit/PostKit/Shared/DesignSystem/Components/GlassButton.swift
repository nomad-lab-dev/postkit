import SwiftUI

struct GlassButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(Palette.text)
            .frame(maxWidth: .infinity)
            .padding(Layout.Padding.button)
            .background(Palette.glassStrong, in: RoundedRectangle(cornerRadius: Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(Palette.border)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview("Glass Button") {
    VStack(spacing: 16) {
        Button("Cancel") {}
            .buttonStyle(GlassButton())

        Button("Skip") {}
            .buttonStyle(GlassButton())
    }
    .padding()
}
