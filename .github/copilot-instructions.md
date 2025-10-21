# Task Timer - AI Coding Assistant Instructions

## Project Overview
A macOS SwiftUI application that provides an always-on-top floating window for task management and time tracking. The app uses a hybrid SwiftUI + AppKit approach to achieve floating window behavior that works even over full-screen applications.

## Architecture & Key Patterns

### Floating Window Implementation
- **Core Pattern**: `FloatingWindow.swift` uses AppKit `NSWindow` with specific configuration for system-wide overlay
- **Critical Settings**: 
  ```swift
  window.level = .floating
  window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
  ```
- **Always-on-Top**: Uses `NSWorkspace` notifications to maintain window precedence across app switches
- **SwiftUI Integration**: Content delivered via `NSHostingView` wrapping SwiftUI views

### App Structure
- **Entry Point**: `TaskTimerApp.swift` with `NSApplicationDelegateAdaptor` pattern
- **Window Management**: `AppDelegate` handles lifecycle, status bar, and floating window creation
- **UI Layer**: SwiftUI views in `ContentView.swift` with custom `VisualEffectBlur` for native blur effects
- **Data Layer**: `TaskTimerViewModel` as `ObservableObject` managing state and persistence

### Data Management
- **Models**: All in `Models.swift` - enums for Priority/Status, structs for Task/UserSettings
- **Persistence**: UserDefaults with JSON encoding/decoding (see `TaskTimerViewModel` save/load methods)
- **State Management**: Combine publishers for real-time updates (timer, clock)

## Development Workflows

### Building & Running
```bash
# From project root
open task-timer.xcodeproj
# Build in Xcode (Cmd+B) or run (Cmd+R)
```

### File Organization
- **Source**: All Swift files in `task-timer/` subdirectory
- **Project Structure**: Uses Xcode's new file system synchronized groups (objectVersion = 77)
- **Assets**: Standard `.xcassets` bundle for icons/colors

## Project-Specific Conventions

### SwiftUI + AppKit Hybrid
- **Window Creation**: Always use AppKit `NSWindow` for window-level control
- **Content Rendering**: Wrap SwiftUI views in `NSHostingView` for AppKit integration
- **System Integration**: Use AppKit for system-level features (status bar, notifications, window behavior)

### Timer Implementation
- **Real-time Updates**: `Timer.publish().autoconnect().sink()` pattern for both clock and pomodoro timer
- **State Synchronization**: Published properties in ViewModel automatically update UI
- **Lifecycle Management**: Store `AnyCancellable` references to prevent timer cleanup

### Visual Effects
- **Native Blur**: Custom `VisualEffectBlur` NSViewRepresentable using `NSVisualEffectView`
- **Transparency**: Combine window `alphaValue` with `NSVisualEffectView` for layered transparency
- **Theme Support**: Enum-driven theme switching with system appearance detection

## Integration Points

### System Permissions
- **Full-Screen Overlay**: Requires `.fullScreenAuxiliary` collection behavior
- **Always-on-Top**: May need accessibility permissions for certain window levels
- **Notifications**: Built for future notification integration (see timer completion flow)

### Data Flow
1. **User Input** → `ContentView` → `TaskTimerViewModel` methods
2. **Timer Events** → Combine publishers → `@Published` properties → UI updates
3. **Persistence** → Immediate save to UserDefaults on model changes

### External Dependencies
- **System Frameworks**: SwiftUI, AppKit, Combine, Foundation only
- **No External Packages**: Pure Apple ecosystem implementation
- **Asset Dependencies**: System SF Symbols for icons

## Critical Implementation Details

### Window Lifecycle
- **Creation**: Always through `FloatingWindow` wrapper class, never direct SwiftUI `WindowGroup`
- **Persistence**: Set `isReleasedWhenClosed = false` to maintain window across hide/show cycles
- **Focus Management**: Use `orderFrontRegardless()` instead of standard focus methods

### State Management
- **Single Source of Truth**: `TaskTimerViewModel` as environment object
- **Immediate Persistence**: All model changes trigger UserDefaults save
- **Timer State**: Separate cancellable references for clock vs pomodoro timer

### UI Patterns
- **Popover Usage**: Task creation uses `.popover()` for lightweight modal experience
- **Context Menus**: Task actions via `.contextMenu` for native macOS interaction
- **Lazy Loading**: `LazyVStack` for task list performance with large datasets

## Development Guidelines

### Adding New Features
1. **Model Changes**: Update `Models.swift` first, ensure `Codable` compliance
2. **ViewModel**: Add business logic and `@Published` properties to `TaskTimerViewModel`
3. **UI**: Create SwiftUI views, inject ViewModel as `@EnvironmentObject`
4. **Persistence**: Add save/load logic following existing UserDefaults pattern

### Window Behavior Modifications
- **Always test** with full-screen apps (spaces, full-screen mode)
- **Verify** `collectionBehavior` changes don't break overlay functionality
- **Test** window level changes against system modal dialogs

### Performance Considerations
- **Timer Frequency**: 1-second intervals are optimal for UI responsiveness vs battery
- **List Rendering**: Use `LazyVStack` for task lists >50 items
- **State Updates**: Minimize `@Published` property changes during heavy user interaction