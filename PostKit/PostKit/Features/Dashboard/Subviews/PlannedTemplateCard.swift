import SwiftUI

struct PlannedTemplateCard: View {
    let template: TemplateSnapshot
    let now: Date

    private var wasPostedToday: Bool {
        guard let lastPosted = template.lastPostedAt else { return false }
        return Calendar.current.isDateInToday(lastPosted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12))
                Text(template.name)
                    .font(Typography.subheadline.weight(.semibold))
                    .lineLimit(1)
            }

            Text("\(template.slots.count) slide\(template.slots.count == 1 ? "" : "s")")
                .font(Typography.caption)
                .foregroundStyle(Palette.text3)

            HStack(spacing: 4) {
                ForEach(template.schedule.weekdays.sorted(), id: \.self) { day in
                    Text(day.initial)
                        .font(Typography.caption2.weight(.medium))
                        .foregroundStyle(Palette.accent)
                }
            }
        }
        .frame(width: 150, alignment: .leading)
        .padding(Layout.Padding.card)
        .foregroundStyle(wasPostedToday ? Palette.text3 : Palette.text)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay {
            if wasPostedToday {
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(Palette.bg.opacity(0.5))
                    .overlay {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Palette.green)
                    }
            }
        }
    }
}
