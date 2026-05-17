import SwiftUI

struct FormField: View {
    @Binding var value: String
    let placeholder: String
    var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Stack.tight) {
            TextField(placeholder, text: $value)
                .font(Typography.body)
                .padding(Layout.Padding.button)
                .background(.white, in: RoundedRectangle(cornerRadius: Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input)
                        .stroke(error == nil ? Palette.border : Palette.red)
                )
            if let error {
                Text(error).font(Typography.caption).foregroundStyle(Palette.red)
            }
        }
    }
}

#Preview("Form Fields") {
    VStack(spacing: 16) {
        FormField(value: .constant("Automotive"), placeholder: "Pillar name")
        FormField(value: .constant("Developer"), placeholder: "Pillar name", error: "This pillar already exists")
        FormField(value: .constant(""), placeholder: "What is this pillar about?")
    }
    .padding()
    .background(Palette.bg)
}
