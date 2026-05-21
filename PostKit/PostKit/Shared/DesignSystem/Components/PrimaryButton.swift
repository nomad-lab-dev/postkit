import SwiftUI

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(Layout.Padding.button)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct DestructiveButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(Palette.red)
            .frame(maxWidth: .infinity)
            .padding(Layout.Padding.button)
            .background(Palette.redTint, in: RoundedRectangle(cornerRadius: Radius.button))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        Button("Get Started →") {}
            .buttonStyle(PrimaryButton())

        Button("Delete Topic") {}
            .buttonStyle(DestructiveButton())
    }
    .padding()
}
