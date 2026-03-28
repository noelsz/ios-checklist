import Foundation
import WidgetKit

struct PeriodProgress: Equatable {
    let current: Double
    let target: Double

    var ratio: Double {
        guard target > 0 else { return 0 }
        return min(max(current / target, 0), 1)
    }
}

final class TaskStore {
    static let appGroupID = "group.com.example.ChecklistApp"
    static let shared = TaskStore()

    private let fileName = "tasks.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var tasks: [TaskItem] = []

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func loadTasks() -> [TaskItem] {
        load()
        return allTasks()
    }

    func saveTasks(_ tasks: [TaskItem]) {
        self.tasks = tasks
        save()
    }

    func allTasks(sorted: Bool = true) -> [TaskItem] {
        if sorted {
            return tasks.sorted(by: sortLogic)
        }
        return tasks
    }

    @discardableResult
    func addTask(title: String, notes: String, recurrence: Recurrence, targetValue: Double, unit: String) -> TaskItem {
        let task = TaskItem(
            title: title,
            notes: notes,
            recurrence: recurrence,
            targetValue: max(targetValue, 1),
            unit: unit
        )
        tasks.append(task)
        save()
        return task
    }

    @discardableResult
    func deleteTask(id: UUID) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return false
        }
        tasks.remove(at: index)
        save()
        return true
    }

    func incrementProgress(id: UUID, amount: Double, at date: Date = .now) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let periodKey = periodIdentifier(for: tasks[idx].recurrence, date: date)
        var task = tasks[idx]
        let current = task.progressByPeriod[periodKey] ?? 0
        let next = min(max(current + amount, 0), task.targetValue)
        task.progressByPeriod[periodKey] = next
        task.lastUpdatedAt = .now
        tasks[idx] = task
        save()
    }

    func setProgress(id: UUID, to value: Double, at date: Date = .now) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let periodKey = periodIdentifier(for: tasks[idx].recurrence, date: date)
        var task = tasks[idx]
        task.progressByPeriod[periodKey] = min(max(value, 0), task.targetValue)
        task.lastUpdatedAt = .now
        tasks[idx] = task
        save()
    }

    func toggleCompleted(id: UUID, at date: Date = .now) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let periodKey = periodIdentifier(for: tasks[idx].recurrence, date: date)
        var task = tasks[idx]
        let current = task.progressByPeriod[periodKey] ?? 0
        task.progressByPeriod[periodKey] = current >= task.targetValue ? 0 : task.targetValue
        task.lastUpdatedAt = .now
        tasks[idx] = task
        save()
    }

    func progress(for task: TaskItem, on date: Date = .now) -> PeriodProgress {
        let periodKey = periodIdentifier(for: task.recurrence, date: date)
        return PeriodProgress(
            current: max(task.progressByPeriod[periodKey] ?? 0, 0),
            target: max(task.targetValue, 1)
        )
    }

    func progress(for id: UUID, on date: Date = .now) -> PeriodProgress {
        guard let task = tasks.first(where: { $0.id == id }) else {
            return PeriodProgress(current: 0, target: 1)
        }
        return progress(for: task, on: date)
    }

    func isTaskComplete(_ id: UUID, on date: Date = .now) -> Bool {
        let snapshot = progress(for: id, on: date)
        return snapshot.current >= snapshot.target
    }

    private func load() {
        guard let url = storageURL() else {
            tasks = []
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            tasks = []
            return
        }
        tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
    }

    private func save() {
        guard let url = storageURL() else { return }
        do {
            let data = try encoder.encode(tasks)
            try data.write(to: url, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            assertionFailure("Failed saving tasks: \(error)")
        }
    }

    private func storageURL() -> URL? {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            return groupURL.appendingPathComponent(fileName)
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    func periodIdentifier(for recurrence: Recurrence, date: Date) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        switch recurrence {
        case .daily:
            let comp = calendar.dateComponents([.year, .month, .day], from: date)
            return String(format: "d-%04d-%02d-%02d", comp.year ?? 0, comp.month ?? 0, comp.day ?? 0)
        case .weekly:
            let comp = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return String(format: "w-%04d-%02d", comp.yearForWeekOfYear ?? 0, comp.weekOfYear ?? 0)
        case .monthly:
            let comp = calendar.dateComponents([.year, .month], from: date)
            return String(format: "m-%04d-%02d", comp.year ?? 0, comp.month ?? 0)
        case .once:
            return "once"
        }
    }

    private func sortLogic(lhs: TaskItem, rhs: TaskItem) -> Bool {
        if lhs.recurrence != rhs.recurrence {
            return lhs.recurrence.sortOrder < rhs.recurrence.sortOrder
        }
        if lhs.isArchived != rhs.isArchived {
            return !lhs.isArchived
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}
