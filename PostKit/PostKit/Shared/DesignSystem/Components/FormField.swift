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
        FormField(value: .constant("Automotive"), placeholder: "Topic name")
        FormField(value: .constant("Developer"), placeholder: "Topic name", error: "This topic already exists")
        FormField(value: .constant(""), placeholder: "What is this topic about?")
    }
    .padding()
    .background(Palette.bg)
}
