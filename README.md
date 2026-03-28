# ios-checklist

Minimalist iOS checklist app with:

- Tasks/checklist items you can complete
- Recurrence support: daily, weekly, monthly, one-time
- Quantified progress for each recurrence period (e.g., 1500/2000 ml daily, 3/5 gym weekly)
- Home Screen widget with direct completion toggles
- Widget sections grouped by cadence (daily, weekly, monthly, one-time)

## Critical identifiers (already aligned)

These values are now consistent across:
- app target bundle ID
- widget target bundle ID
- app and widget entitlements
- shared persistence container lookup

Current defaults:
- App bundle ID: `com.noelsz.ioschecklist`
- Widget bundle ID: `com.noelsz.ioschecklist.widget`
- App Group: `group.com.noelsz.ioschecklist`

If you change one, change all related values.

## Project structure

- `project.yml` – XcodeGen spec for app + widget
- `Sources/Shared` – shared models and persistence used by app + widget
- `Sources/App` – SwiftUI app
- `Sources/Widget` – WidgetKit extension with interactive buttons
- `Config` – app group entitlements
- `Tests/SharedTests` – recurrence and persistence tests for shared store logic

## Build/run

1. Install XcodeGen if needed:
   - `brew install xcodegen`
2. Generate the Xcode project:
   - `xcodegen generate`
3. Open `ChecklistApp.xcodeproj` in Xcode.
4. Set a development team and run on iOS 17+ simulator/device.

## Reliability details

- Shared data is persisted in `tasks.json` inside the app group container.
- If the app group container is unavailable (common in preview/misconfigured simulator), storage falls back to Documents.
- Widget timelines are reloaded on every store write and after intent actions.
- Progress resets are period-key based (daily/weekly/monthly keys), so no explicit destructive reset is needed.
- Weekly keys use `Calendar.current` locale/week rules and `yearForWeekOfYear + weekOfYear`.
- Progress is intentionally allowed to exceed target (e.g. `6/5`) for over-completion tracking.

## Manual verification checklist

1. Add task in app → force quit app → relaunch → task remains.
2. Add/complete task in app → widget updates quickly.
3. Complete task from widget → app reflects completion.
4. Daily task around midnight boundary uses a new day bucket.
5. Weekly task aligns to device locale week settings.
6. Edge cases:
   - progress can exceed target (e.g., 6/5)
   - deleting tasks removes them from widget
   - empty state view appears with no tasks
   - many tasks still grouped by recurrence in list/widget

## XcodeGen signing note

`xcodegen generate` can reset per-user signing settings in Xcode project state.
If that happens, re-select your Team and signing profile in Xcode for both app and widget targets.
