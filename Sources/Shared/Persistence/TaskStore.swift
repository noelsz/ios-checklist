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
    static let appGroupID = "group.com.noelsz.ioschecklist"
    static let shared = TaskStore()

    private let fileName = "tasks.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var tasks: [TaskItem] = []
    private let calendarProvider: () -> Calendar
    private let nowProvider: () -> Date
    private let storageURLProvider: (() -> URL?)?

    init(
        calendarProvider: @escaping () -> Calendar = { .autoupdatingCurrent },
        nowProvider: @escaping () -> Date = { .now },
        storageURLProvider: (() -> URL?)? = nil
    ) {
        self.calendarProvider = calendarProvider
        self.nowProvider = nowProvider
        self.storageURLProvider = storageURLProvider
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
        cleanupStaleProgress(for: idx, now: date)
        let periodKey = periodIdentifier(for: tasks[idx].recurrence, date: date)
        var task = tasks[idx]
        let current = task.progressByPeriod[periodKey] ?? 0
        let next = max(current + amount, 0)
        task.progressByPeriod[periodKey] = next
        task.lastUpdatedAt = nowProvider()
        tasks[idx] = task
        save()
    }

    func setProgress(id: UUID, to value: Double, at date: Date = .now) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        cleanupStaleProgress(for: idx, now: date)
        let periodKey = periodIdentifier(for: tasks[idx].recurrence, date: date)
        var task = tasks[idx]
        task.progressByPeriod[periodKey] = max(value, 0)
        task.lastUpdatedAt = nowProvider()
        tasks[idx] = task
        save()
    }

    func toggleCompleted(id: UUID, at date: Date = .now) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        cleanupStaleProgress(for: idx, now: date)
        let periodKey = periodIdentifier(for: tasks[idx].recurrence, date: date)
        var task = tasks[idx]
        let current = task.progressByPeriod[periodKey] ?? 0
        task.progressByPeriod[periodKey] = current >= task.targetValue ? 0 : task.targetValue
        task.lastUpdatedAt = nowProvider()
        tasks[idx] = task
        save()
    }

    func progress(for task: TaskItem, on date: Date = .now) -> PeriodProgress {
        let normalizedTask = normalizedForRead(task: task, now: date)
        let periodKey = periodIdentifier(for: normalizedTask.recurrence, date: date)
        return PeriodProgress(
            current: max(normalizedTask.progressByPeriod[periodKey] ?? 0, 0),
            target: max(normalizedTask.targetValue, 1)
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
        let now = nowProvider()
        var cleanedAny = false
        for index in tasks.indices {
            if cleanupStaleProgress(for: index, now: now) {
                cleanedAny = true
            }
        }
        if cleanedAny {
            // Persist cleanup so restarts don't repeatedly process stale periods.
            save()
        }
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
        if let storageURLProvider {
            return storageURLProvider()
        }
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            return groupURL.appendingPathComponent(fileName)
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    func periodIdentifier(for recurrence: Recurrence, date: Date, calendar: Calendar? = nil) -> String {
        var workingCalendar = calendar ?? calendarProvider()
        if workingCalendar.firstWeekday <= 0 {
            workingCalendar.firstWeekday = 2
        }

        switch recurrence {
        case .daily:
            let comp = workingCalendar.dateComponents([.year, .month, .day], from: date)
            return String(format: "d-%04d-%02d-%02d", comp.year ?? 0, comp.month ?? 0, comp.day ?? 0)
        case .weekly:
            let comp = workingCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return String(format: "w-%04d-%02d", comp.yearForWeekOfYear ?? 0, comp.weekOfYear ?? 0)
        case .monthly:
            let comp = workingCalendar.dateComponents([.year, .month], from: date)
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

    private func normalizedForRead(task: TaskItem, now: Date) -> TaskItem {
        let currentKey = periodIdentifier(for: task.recurrence, date: now)
        if task.recurrence == .once {
            return task
        }
        if task.progressByPeriod.keys.count == 1, task.progressByPeriod[currentKey] != nil {
            return task
        }
        var cleaned = task
        if let currentValue = task.progressByPeriod[currentKey] {
            cleaned.progressByPeriod = [currentKey: currentValue]
        } else {
            cleaned.progressByPeriod = [:]
        }
        return cleaned
    }

    private func cleanupStaleProgress(for index: Int, now: Date) -> Bool {
        guard tasks.indices.contains(index) else { return false }
        var task = tasks[index]
        guard task.recurrence != .once else { return false }
        let cleaned = normalizedForRead(task: task, now: now)
        if cleaned.progressByPeriod != task.progressByPeriod {
            task.progressByPeriod = cleaned.progressByPeriod
            tasks[index] = task
            return true
        }
        return false
    }
}
