import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Recurrence.allCases) { recurrence in
                    let tasks = viewModel.tasksForRecurrence(recurrence)
                    if !tasks.isEmpty || viewModel.tasks.isEmpty {
                        Section(recurrence.sectionTitle) {
                            ForEach(tasks) { task in
                                let progress = viewModel.progress(for: task)
                                TaskRowView(
                                    task: task,
                                    progress: progress,
                                    onToggleCompletion: {
                                        viewModel.toggleCompletion(for: task.id)
                                    },
                                    onIncrement: {
                                        viewModel.incrementProgress(for: task.id, by: 1)
                                    },
                                    onDecrement: {
                                        viewModel.decrementProgress(for: task.id, by: 1)
                                    }
                                )
                                .swipeActions {
                                    Button(role: .destructive) {
                                        viewModel.deleteTask(id: task.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Checklist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $showingEditor) {
                TaskEditorView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            .overlay {
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks Yet",
                        systemImage: "checklist",
                        description: Text("Create a daily, weekly, or monthly goal to start tracking progress.")
                    )
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .task {
            viewModel.load()
        }
    }
}

#Preview {
    TaskListView(viewModel: TaskListViewModel())
}
