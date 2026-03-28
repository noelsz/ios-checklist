import SwiftUI

@main
struct ChecklistApp: App {
    @StateObject private var viewModel = TaskListViewModel()

    var body: some Scene {
        WindowGroup {
            TaskListView(viewModel: viewModel)
        }
    }
}
