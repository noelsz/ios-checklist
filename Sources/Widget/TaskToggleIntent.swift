import AppIntents

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Checklist Task"
    static var description = IntentDescription("Toggles checklist task completion for the current period.")

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: taskID) else {
            return .result()
        }
        TaskStore.shared.toggleCompleted(id: id)
        return .result()
    }
}
