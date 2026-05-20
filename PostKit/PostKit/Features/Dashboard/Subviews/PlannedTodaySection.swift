import SwiftUI

struct PlannedTodaySection: View {
    let templates: [TemplateSnapshot]
    let now: Date
    let onTap: (TemplateSnapshot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Planned today")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(templates) { template in
                        Button {
                            onTap(template)
                        } label: {
                            PlannedTemplateCard(template: template, now: now)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
