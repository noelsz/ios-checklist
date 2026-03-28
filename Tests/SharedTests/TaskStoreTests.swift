import Foundation
import XCTest
@testable import ChecklistApp

final class TaskStoreTests: XCTestCase {
    func testDailyPeriodIdentifierChangesAcrossMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let store = makeStore(calendar: calendar)

        let beforeMidnight = calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 23, minute: 59))!
        let afterMidnight = calendar.date(from: DateComponents(year: 2026, month: 3, day: 29, hour: 0, minute: 1))!

        let beforeKey = store.periodIdentifier(for: .daily, date: beforeMidnight)
        let afterKey = store.periodIdentifier(for: .daily, date: afterMidnight)
        XCTAssertNotEqual(beforeKey, afterKey)
    }

    func testWeeklyPeriodIdentifierUsesCalendarWeekBoundary() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1 // Sunday locale-like behavior
        let store = makeStore(calendar: calendar)

        let sunday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 29))!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 30))!

        let sundayKey = store.periodIdentifier(for: .weekly, date: sunday)
        let mondayKey = store.periodIdentifier(for: .weekly, date: monday)
        XCTAssertEqual(sundayKey, mondayKey)
    }

    func testProgressAllowsOverTarget() {
        let task = TaskItem(title: "Gym", recurrence: .weekly, targetValue: 5, unit: "times")
        let store = makeStore()
        store.saveTasks([task])

        store.incrementProgress(id: task.id, amount: 8)
        let progress = store.progress(for: task.id)
        XCTAssertEqual(progress.current, 8)
        XCTAssertEqual(progress.target, 5)
    }

    func testOnlyCurrentPeriodProgressIsKeptAfterReload() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let noon = calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12))!
        let fileURL = uniqueTempFileURL()

        var seededStore = TaskStore(
            calendarProvider: { calendar },
            nowProvider: { noon },
            storageURLProvider: { fileURL }
        )
        let marchTask = TaskItem(
            title: "Water",
            recurrence: .daily,
            targetValue: 2,
            unit: "L",
            progressByPeriod: [
                "d-2026-03-27": 2,
                "d-2026-03-28": 1
            ]
        )
        seededStore.saveTasks([marchTask])
        seededStore = TaskStore(
            calendarProvider: { calendar },
            nowProvider: { noon },
            storageURLProvider: { fileURL }
        )

        let loaded = seededStore.loadTasks()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].progressByPeriod.keys.sorted(), ["d-2026-03-28"])
        XCTAssertEqual(loaded[0].progressByPeriod["d-2026-03-28"], 1)
    }

    private func makeStore(calendar: Calendar = .gregorian) -> TaskStore {
        TaskStore(
            calendarProvider: { calendar },
            nowProvider: { Date(timeIntervalSince1970: 0) },
            storageURLProvider: { uniqueTempFileURL() }
        )
    }

    private func uniqueTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }
}
