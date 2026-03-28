import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let progress: PeriodProgress
    var onToggleCompletion: () -> Void
    var onIncrement: () -> Void
    var onDecrement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(task.recurrence.title)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress.ratio)
                .tint(progress.ratio >= 1 ? .green : .accentColor)

            HStack {
                Button(action: onDecrement) {
                    Label("Decrease", systemImage: "minus.circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(progress.current <= 0)

                Text("\(formatNumber(progress.current)) / \(formatNumber(progress.target)) \(task.unit)")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 110, alignment: .leading)

                Button(action: onIncrement) {
                    Label("Increase", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(progress.ratio >= 1)

                Spacer()

                Button(action: onToggleCompletion) {
                    Label(
                        progress.ratio >= 1 ? "Completed" : "Mark complete",
                        systemImage: progress.ratio >= 1 ? "checkmark.circle.fill" : "circle"
                    )
                    .labelStyle(.titleAndIcon)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(progress.ratio >= 1 ? .green : .accentColor)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func formatNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
