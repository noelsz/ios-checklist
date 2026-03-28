import SwiftUI
import WidgetKit

struct WidgetTaskItem: Hashable {
    let id: UUID
    let title: String
    let recurrence: Recurrence
    let progressText: String
    let isComplete: Bool
}

struct ChecklistEntry: TimelineEntry {
    let date: Date
    let sections: [WidgetSection]
}

struct WidgetSection: Hashable {
    let title: String
    let recurrence: Recurrence
    let items: [WidgetTaskItem]
}

struct ChecklistProvider: TimelineProvider {
    private let store = TaskStore.shared

    func placeholder(in context: Context) -> ChecklistEntry {
        .init(
            date: Date(),
            sections: [
                WidgetSection(
                    title: Recurrence.daily.sectionTitle,
                    recurrence: .daily,
                    items: [
                        WidgetTaskItem(
                            id: UUID(),
                            title: "Drink water",
                            recurrence: .daily,
                            progressText: "1 / 2 L",
                            isComplete: false
                        )
                    ]
                )
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChecklistEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChecklistEntry>) -> Void) {
        let entry = makeEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> ChecklistEntry {
        let tasks = store.loadTasks()

        let grouped = Dictionary(grouping: tasks.filter { !$0.isArchived }, by: \.recurrence)
        let sections = Recurrence.allCases.compactMap { recurrence -> WidgetSection? in
            let recurrenceTasks = (grouped[recurrence] ?? []).filter { task in
                !store.isTaskComplete(task.id, on: .now) || recurrence == .once
            }
            guard !recurrenceTasks.isEmpty else { return nil }

            let items = recurrenceTasks.prefix(4).map { task in
                let progress = store.progress(for: task.id, on: .now)
                return WidgetTaskItem(
                    id: task.id,
                    title: task.title,
                    recurrence: task.recurrence,
                    progressText: "\(pretty(progress.current)) / \(pretty(progress.target)) \(task.unit)",
                    isComplete: progress.current >= progress.target
                )
            }

            return WidgetSection(
                title: recurrence.sectionTitle,
                recurrence: recurrence,
                items: Array(items)
            )
        }

        return ChecklistEntry(date: Date(), sections: sections)
    }
}

struct ChecklistWidgetView: View {
    var entry: ChecklistProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if entry.sections.isEmpty {
                Text("No active goals")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                ForEach(Array(entry.sections.prefix(2)), id: \.self) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        ForEach(section.items, id: \.id) { item in
                            HStack(spacing: 8) {
                                if item.isComplete {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                } else {
                                    Button(intent: ToggleTaskIntent(taskID: item.id.uuidString)) {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .lineLimit(1)
                                    Text(item.progressText)
                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(.background, for: .widget)
    }
}

struct ChecklistWidget: Widget {
    let kind: String = "ChecklistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChecklistProvider()) { entry in
            ChecklistWidgetView(entry: entry)
        }
        .configurationDisplayName("Checklist Goals")
        .description("Track daily, weekly, and monthly progress at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct ChecklistWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChecklistWidget()
    }
}

private func pretty(_ value: Double) -> String {
    if value.rounded(.towardZero) == value {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}
