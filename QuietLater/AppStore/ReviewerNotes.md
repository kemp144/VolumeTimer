# App Review Notes — QuietLater 1.0

**App name:** QuietLater
**Category:** Utilities
**Platform:** macOS (Mac App Store)

---

## What this app does

QuietLater is a simple Mac utility that lets users lower, mute, or restore their system output volume — immediately or after a countdown timer. It is designed for common personal use cases such as muting audio before a meeting, fading out music at bedtime, or lowering volume after a scheduled event.

## Key behaviors

- **Timer:** The user selects a duration (5, 10, 15, 30, or 60 minutes, or a custom value) and an action (mute or set volume to a specific percentage). When the timer expires, the action is applied.
- **Fade-out:** An optional mode gradually lowers volume during the last 30 seconds of the countdown.
- **Restore:** An optional mode restores the original captured volume after a user-chosen delay.
- **Manual controls:** The user can mute, set a specific volume, or restore the previous volume immediately without starting a timer.

## APIs used

QuietLater uses only documented, public macOS APIs:

- **CoreAudio `AudioObjectGetPropertyData` / `AudioObjectSetPropertyData`** with:
  - `kAudioHardwarePropertyDefaultOutputDevice` — to identify the current output device
  - `kAudioDevicePropertyVolumeScalar` — to read and write output volume
  - `kAudioDevicePropertyMute` — to read and write mute state

These APIs do not require any special entitlements and work fully within the standard Mac App Sandbox.

## Permissions and privacy

- **No account required.** The app works entirely offline with no login.
- **No network access.** The app makes no network connections.
- **No data collected.** No user data is stored, transmitted, or shared.
- **No microphone access.** The app does not record or analyze audio.
- **No Accessibility permissions.** The app does not use the Accessibility API.
- **No AppleScript or Apple Events.** No inter-app scripting is used.
- **Sandbox entitlement only.** The only entitlement is `com.apple.security.app-sandbox = true`.

## Testing the app

1. Launch QuietLater.
2. Select a preset duration (e.g., 5 minutes) and choose "Mute" as the action.
3. Click "Start Timer."
4. Observe the countdown and confirm the system audio mutes when the timer reaches zero.
5. Use "Mute Now" in the "Do it now" section to verify immediate volume control.

For a fast review pass, setting a custom duration of 1 minute (via the Custom option and Stepper) and enabling "Fade out in the last 30 seconds" demonstrates the core feature set quickly.

## Known limitations

- Timer state is not persisted across app quit and relaunch. If the user quits the app while a timer is running, the timer is cancelled. This is communicated in the app's status copy.
- The app controls the default system output device only. Per-app or per-device routing is not supported (out of v1 scope).
