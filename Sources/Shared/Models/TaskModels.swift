import Foundation

enum Recurrence: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case once

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .once: return "One-Time"
        }
    }

    var sectionTitle: String {
        switch self {
        case .daily: return "Daily Goals"
        case .weekly: return "Weekly Goals"
        case .monthly: return "Monthly Goals"
        case .once: return "One-Time Tasks"
        }
    }

    var sortOrder: Int {
        switch self {
        case .daily: return 0
        case .weekly: return 1
        case .monthly: return 2
        case .once: return 3
        }
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var notes: String
    var recurrence: Recurrence
    var targetValue: Double
    var unit: String
    var progressByPeriod: [String: Double]
    var isArchived: Bool
    var createdAt: Date
    var lastUpdatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        recurrence: Recurrence = .daily,
        targetValue: Double = 1,
        unit: String = "times",
        progressByPeriod: [String: Double] = [:],
        isArchived: Bool = false,
        createdAt: Date = .now,
        lastUpdatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.recurrence = recurrence
        self.targetValue = max(1, targetValue)
        self.unit = unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "times" : unit
        self.progressByPeriod = progressByPeriod
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
    }
}
