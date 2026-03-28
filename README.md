# ios-checklist

Minimalist iOS checklist app with:

- Tasks/checklist items you can complete
- Recurrence support: daily, weekly, monthly, one-time
- Quantified progress for each recurrence period (e.g., 1500/2000 ml daily, 3/5 gym weekly)
- Home Screen widget with direct completion toggles
- Widget sections grouped by cadence (daily, weekly, monthly, one-time)

## Project structure

- `project.yml` – XcodeGen spec for app + widget
- `Sources/Shared` – shared models and persistence used by app + widget
- `Sources/App` – SwiftUI app
- `Sources/Widget` – WidgetKit extension with interactive buttons
- `Config` – app group entitlements

## Build/run

1. Install XcodeGen if needed:
   - `brew install xcodegen`
2. Generate the Xcode project:
   - `xcodegen generate`
3. Open `ChecklistApp.xcodeproj` in Xcode.
4. Set a development team and run on iOS 17+ simulator/device.

> App Group identifier is set to `group.com.example.ChecklistApp`.  
> You can change bundle IDs and app-group values in `project.yml` and the entitlements files.

## UX notes

- Typography uses SF (`.headline`, `.subheadline`, `.caption`) and restrained spacing for a minimal look.
- The app surfaces recurrence sections and progress bars to make daily/weekly/monthly goals visible at a glance.
- Widget allows direct progress updates without opening the app.

## Clarifications needed for final product decisions

To tailor this exactly to your workflow, I still need your preferences on:

1. **Progress units**: free text per task (ml, times, pages) vs predefined unit list?
2. **Auto-reset behavior**:
   - Should daily/weekly/monthly progress reset automatically when a new period begins? (currently yes)
   - Should completing a target lock the task for the rest of the period, or still allow over-completion?
3. **Widget prioritization**:
   - Should widget show only active tasks due today/current week/month, or all tasks in each section?
4. **Checklist notes format**:
   - Plain text notes per task (current), or nested sub-checklist items inside a task?
5. **Sorting defaults**:
   - By recurrence then title (current), or custom manual order?
