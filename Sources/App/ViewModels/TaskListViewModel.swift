import Foundation

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []

    private let store = TaskStore.shared

    init() {
        load()
    }

    func load() {
        tasks = store.loadTasks()
    }

    func addTask(title: String, notes: String, recurrence: Recurrence, targetValue: Double, unit: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = store.addTask(
            title: trimmed,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            recurrence: recurrence,
            targetValue: max(1, targetValue),
            unit: unit
        )
        load()
    }

    func deleteTask(id: UUID) {
        _ = store.deleteTask(id: id)
        load()
    }

    func incrementProgress(for id: UUID, by amount: Double = 1) {
        store.incrementProgress(id: id, amount: amount)
        load()
    }

    func decrementProgress(for id: UUID, by amount: Double = 1) {
        store.incrementProgress(id: id, amount: -abs(amount))
        load()
    }

    func setProgress(for id: UUID, to value: Double) {
        store.setProgress(id: id, to: value)
        load()
    }

    func toggleCompletion(for id: UUID) {
        store.toggleCompleted(id: id)
        load()
    }

    func progress(for task: TaskItem) -> PeriodProgress {
        store.progress(for: task)
    }

    func tasksForRecurrence(_ recurrence: Recurrence) -> [TaskItem] {
        tasks.filter { !$0.isArchived && $0.recurrence == recurrence }
    }
}
