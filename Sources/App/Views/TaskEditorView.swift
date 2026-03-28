import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel

    @State private var title = ""
    @State private var notes = ""
    @State private var recurrence: Recurrence = .daily
    @State private var targetValue = "1"
    @State private var unit = "times"

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section("Repeat") {
                    Picker("Cadence", selection: $recurrence) {
                        ForEach(Recurrence.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Goal") {
                    TextField("Target value", text: $targetValue)
                        .keyboardType(.decimalPad)
                    TextField("Unit (e.g. L, times, pages)", text: $unit)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(targetValue) == nil)
                }
            }
        }
    }

    private func save() {
        guard let target = Double(targetValue), target > 0 else { return }
        viewModel.addTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            recurrence: recurrence,
            targetValue: target,
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "times" : unit.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dismiss()
    }
}
