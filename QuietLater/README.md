# QuietLater

A calm, focused Mac utility that lowers, mutes, or restores your system volume — now or after a timer.

---

## Project Setup

### Requirements
- Xcode 15 or later
- macOS 13.0+ deployment target
- Swift 5.9+

### Creating the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**
3. Configure:
   - **Product Name:** QuietLater
   - **Bundle Identifier:** `com.yourcompany.QuietLater` (replace before submission)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Include Tests:** Yes

4. Set **Deployment Target** to macOS 13.0

5. Add all source files from `Sources/` to the main target:
   - `QuietLaterApp.swift`
   - `Models/TimerAction.swift`
   - `Models/TimerDuration.swift`
   - `Models/VolumeState.swift`
   - `Services/AudioService.swift`
   - `Services/CountdownTimer.swift`
   - `ViewModels/QuietLaterViewModel.swift`
   - `Views/ContentView.swift`
   - `Views/CountdownDisplayView.swift`
   - `Views/DurationChipView.swift`
   - `Views/TimerSectionView.swift`
   - `Views/ManualSectionView.swift`

6. Add `Tests/QuietLaterTests.swift` to the test target

7. Replace the auto-generated `Info.plist` with the one in `Resources/`
   (or merge key-value pairs into your project's Info.plist)

8. Create a `.entitlements` file for the target named `QuietLater.entitlements`
   and copy the contents from `Resources/QuietLater.entitlements`

9. In **Signing & Capabilities**, add **App Sandbox** (required for Mac App Store)
   — no other capabilities are needed

10. Link **CoreAudio.framework** in **Build Phases → Link Binary With Libraries**

### Running

Build and run in Xcode (⌘R). The app opens a single utility window.

### Testing

Run tests with ⌘U. Tests cover:
- Model logic (VolumeState, TimerDuration, TimerAction)
- ViewModel state transitions and input validation
- Formatting helpers
- CountdownTimer tick, cancel, and phase callbacks

---

## Architecture

```
QuietLater
├── Models/           Pure value types. No dependencies.
│   ├── TimerAction   Enum: .mute or .setVolume(Float)
│   ├── TimerDuration Enum: preset minutes or .custom
│   └── VolumeState   Struct: volume scalar + mute flag
│
├── Services/         Stateful service objects.
│   ├── AudioService  CoreAudio read/write wrapper (no dependencies)
│   └── CountdownTimer Single-use countdown with fade and restore logic
│
├── ViewModels/
│   └── QuietLaterViewModel  @MainActor ObservableObject owning all UI state
│
└── Views/            Pure SwiftUI. Depend only on ViewModel.
    ├── ContentView
    ├── TimerSectionView
    ├── ManualSectionView
    ├── CountdownDisplayView
    └── DurationChipView
```

### Key design decisions

**CoreAudio — App Store safety:**
`AudioObjectSetPropertyData` with `kAudioDevicePropertyVolumeScalar` and `kAudioDevicePropertyMute` are documented public APIs. They work inside the App Sandbox without any special entitlements. No AppleScript, no shell invocations, no private APIs.

**Volume channel strategy:**
macOS audio devices vary. Some expose a master element (element 0); others require per-channel writes (channels 1, 2). `AudioService` tries master first, then falls back to channels 1 and 2.

**Captured state:**
Volume state is captured once — at the moment `startTimer()` or the first manual action is called. It is not updated if the user changes system volume manually during a countdown. This matches the expected behavior: "restore what I had before QuietLater touched it."

**Timer replacement:**
If the user starts a new timer while one is active, the active timer is cancelled and replaced. A new state is captured. This is simpler and more predictable than queuing timers.

**No persistence across quit:**
Timer state intentionally does not persist across quit/relaunch. This avoids complexity and avoids the edge case of stale timers firing unexpectedly after relaunch. The UI copy reflects this.

---

## App Store

See `AppStore/` for:
- `ReviewerNotes.md` — draft reviewer notes for App Review submission
- `AppStoreAssets.md` — description, subtitle options, keywords, privacy approach, risk review, and pre-submission checklist
