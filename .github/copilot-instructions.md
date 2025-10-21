# Task Timer – AI Assistant Guide

## Quick Orientation
- macOS SwiftUI + AppKit hybrid; entry point is `TaskTimerApp.swift` which boots `AppDelegate` only (no SwiftUI `WindowGroup`).
- Core UI lives inside a single floating `NSWindow` managed by `FloatingWindow.swift`; `RootView` swaps between `ContentView.swift` and `CompactView.swift` based on `TaskTimerViewModel.settings.isCompactMode`.
- All state funnels through `TaskTimerViewModel.swift` (`@EnvironmentObject` everywhere). It owns timers, persistence, menu-facing state, and settings.

## Building & Debugging
- Launch with Xcode: `open task-timer.xcodeproj` then build/run (⌘B / ⌘R). No command-line build scripts.
- User data persists in `UserDefaults` keys `savedTasks` and `userSettings`; clear via Xcode scheme environment or `defaults delete com.your.bundle.id savedTasks` when you need a clean slate.

## Window & Status Bar Behavior
- `FloatingWindow.setupWindow()` configures the overlay window (`level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`) so it stays above full-screen apps. Keep these flags unless you fully understand Spaces behavior.
- `AppDelegate` creates both the floating window and a status-bar menu (`NSStatusBar.system.statusItem`). Menu items call back into `TaskTimerViewModel` for timer, theme, opacity, and compact mode toggles; update handlers should regenerate the menu (`statusBarItem?.menu = createMenu()`).
- Compact mode forces `NSWindow` into borderless style. Notice the convention in `FloatingWindow.updateWindowMovable`: when the window is not movable we flip `ignoresMouseEvents` on so clicks pass through—replicate that if you add new mobility modes.

## Timer & Notifications
- `TaskTimerViewModel` drives two `Timer.publish` streams (clock + pomodoro). `timerSeconds` counts elapsed seconds; `timerTargetSeconds` holds the selected duration.
- Completion posts `TaskTimerViewModel.timerDidCompleteNotification`; `FloatingWindow` listens and shows a blocking `NSAlert`. If you add alternative alerts/toasts, wire them to that notification instead of duplicating logic.
- Status bar quick-start items (5–60 min + custom) funnel through `AppDelegate.startTimerWithDuration`, which sets duration then calls `viewModel.toggleTimer()`. Keep timer mutations inside the view model to avoid desync.

## Tasks & Lists
- Task data model (`Models.swift::Task`) is `Codable` with manual `sortOrder`. `TaskTimerViewModel.reorderTasks()` keeps incomplete tasks before completed ones; `moveTask` rejects drags that would cross that boundary. When editing, update the task in place and call `saveTasks()` afterward.
- First-run sample data lives in `addSampleTasks()`. If you rely on empty state, delete persisted tasks first.

## Settings & Themes
- `SettingsView.swift` operates on a copy (`tempSettings`) and writes back via `viewModel.saveSettings()`. Keep that pattern so popovers/windows can cancel cleanly.
- Theme handling is enum-based (`Theme.system/light/dark`). `FloatingWindow.updateAppearance` swaps `NSAppearance`; returning `nil` reverts to system. Respect this when introducing new appearance toggles.
- Opacity slider persists to both the model and the live window via `FloatingWindow.setOpacity(_:)`. Any new window-affecting setting should update both the `NSWindow` instance and persisted settings.

## Compact View Conventions
- `CompactView` reads typography and color from `UserSettings` (`compactTimeFontSize`, `compactTaskFontSize`, `compactColorHex`). Reuse `Color(hex:)` helpers for additional customizable elements; they already guard against malformed input.
- When adding more compact-mode UI, remember that the window might ignore mouse events if `isWindowMovable == false`.

## UI Composition Patterns
- Popovers (`AddTaskView`, `EditTaskView`, `SettingsView`) use `@State` bindings to control presentation. Persist or dismiss via the shared `TaskTimerViewModel`—avoid separate storage.
- Background blur uses `VisualEffectBlur` wrapper around `NSVisualEffectView`. For new translucent regions, reuse this wrapper instead of stacking opacity hacks.

## Extending the App
- Add new status-bar actions inside `AppDelegate.createMenu()`; keep localization-ready strings consistent with existing Chinese labels.
- When introducing new persisted fields, update both `UserSettings` defaults and decode paths so existing installs load without crashing.
- For new timer modes, expose toggles through the view model (`@Published` state + persistence) and surface controls in both window and status bar to stay in sync.