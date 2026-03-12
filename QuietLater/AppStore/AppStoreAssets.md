# QuietLater — App Store Assets

---

## App Store Description

**Primary description (short form, ~150 words):**

QuietLater lowers, mutes, or restores your Mac's volume — right now or after a countdown timer.

Set a timer and walk away. When time is up, QuietLater mutes your Mac or sets it to any volume you choose. No menu diving. No forgetting. Just quiet, on time.

**Features:**
- Countdown presets: 5, 10, 15, 30, 60 minutes — or a custom duration
- Actions: mute completely or set to any volume level
- Optional fade-out: volume drops smoothly in the last 30 seconds
- Optional restore: your previous volume comes back after a delay
- Immediate controls: mute now, set volume now, restore now
- Works entirely offline — no account, no data collected

Simple, focused, and native. QuietLater does one thing and does it well.

---

## Subtitle Options (max 30 characters each)

1. `Mute your Mac, on time.`
2. `Volume timer for your Mac`
3. `Set volume now or later`
4. `Quiet your Mac on a timer`
5. `Fade out. Mute. Restore.`

**Recommendation:** Option 2 — "Volume timer for your Mac" — is the most searchable and descriptive for discoverability. Option 1 — "Mute your Mac, on time." — is the most brand-consistent.

---

## Keywords (max 100 characters total, comma-separated)

```
volume,mute,timer,fade,sleep,quiet,audio,sound,control,scheduler,countdown,restore,output
```

**Notes:**
- "volume" and "mute" are the highest-intent keywords for this category.
- "fade" captures users looking for gradual volume reduction.
- "sleep" and "quiet" capture bedtime/focus use cases.
- "countdown" and "timer" cover the core timer mechanic.
- Avoid Apple trademarks (e.g., "Mac" in keywords is acceptable as a common word, but avoid "Apple," "macOS," "Siri," etc.).

---

## Privacy Approach

**Recommended privacy disclosure:** "No data collected."

QuietLater does not:
- Collect, transmit, or share any user data
- Connect to the internet
- Store any identifying information
- Use analytics, crash reporting SDKs, or third-party libraries
- Require an account or login

**App Store privacy label:**
Under "Data Not Collected," check all categories. No data types are linked to the user or used for tracking.

**Privacy Policy approach:**
A minimal hosted privacy policy (required by Apple even for apps that collect no data) should state:
- The app does not collect personal data
- The app has no network connectivity
- No third-party analytics or advertising SDKs are included
- Contact email for privacy questions

---

## Technical Risk Review

| Risk Area | Assessment | Mitigation |
|---|---|---|
| CoreAudio sandbox compatibility | **Low.** `kAudioDevicePropertyVolumeScalar` and `kAudioDevicePropertyMute` work in sandbox without entitlements. Verified by many shipping App Store apps. | Use only these APIs. No shell tricks, no AppleScript. |
| Some devices don't support master element | **Low.** Handled by per-channel fallback in `AudioService`. | Tested on MacBook Pro built-in audio and USB audio devices. |
| Mute not supported on all devices | **Low.** `AudioObjectHasProperty` is checked before write. | Graceful no-op if device doesn't support mute property. |
| Timer persistence across quit | **None.** App intentionally cancels timers on quit. | Clearly communicated in UI. |
| 0% volume vs mute state ambiguity | **Low.** App distinguishes them: mute uses `kAudioDevicePropertyMute`, not just 0% scalar. | Both captured and restored independently. |
| Review rejection for "system control" | **Very low.** Volume control is an established Mac App Store category (e.g., Silenz, Quiet, etc.). API used is same as system uses. | Reviewer notes explain the API. |
| Rejection for missing privacy policy URL | **Low.** Required even for no-data apps. | Provide a hosted privacy policy URL before submission. |

---

## Pre-Submission Checklist

### Code & Build
- [ ] Archive build is code-signed with Mac App Store distribution certificate
- [ ] Provisioning profile matches bundle ID with App Sandbox enabled
- [ ] Entitlements file contains only `com.apple.security.app-sandbox = true`
- [ ] No hardcoded team IDs, signing identities, or developer paths in source
- [ ] Build succeeds with no warnings under release configuration
- [ ] Deployment target set to macOS 13.0 minimum (or as determined by testing)
- [ ] `LSMinimumSystemVersion` in Info.plist matches Xcode deployment target

### App Content
- [ ] No placeholder UI, "coming soon" text, or unimplemented features
- [ ] All UI states tested: idle, running, fading, completed, cancelled
- [ ] Error states handled gracefully (no silent failures)
- [ ] App behaves correctly when audio device changes mid-session
- [ ] App behaves correctly when minimized during countdown

### App Store Connect
- [ ] App name: **QuietLater**
- [ ] Subtitle entered (≤30 characters)
- [ ] Primary description entered
- [ ] Keywords entered (≤100 characters)
- [ ] Privacy nutrition labels set to "Data Not Collected" for all categories
- [ ] Privacy policy URL entered (hosted, live, accessible)
- [ ] App category: Utilities
- [ ] Age rating: 4+
- [ ] Version: 1.0, Build: 1
- [ ] Screenshots provided for all required macOS sizes (1280×800, 1440×900, 2560×1600, 2880×1800)
- [ ] App icon provided at all required sizes (1024×1024 base, all scale factors in asset catalog)
- [ ] Reviewer notes submitted with the build

### Final QA Pass
- [ ] Clean uninstall and reinstall tested
- [ ] Tested on latest shipping macOS (Sequoia / macOS 15+)
- [ ] Light mode tested
- [ ] Dark mode tested
- [ ] VoiceOver tested — all controls labeled and navigable
- [ ] Keyboard-only navigation tested (Tab, Return, Escape)
- [ ] No console sandbox violation messages from the app process
- [ ] Notarization / stapling verified for TestFlight or direct distribution (if applicable pre-review)

---

## Brand Positioning: QuietLater vs. Generic Names

**Why "QuietLater" beats "Volume Timer" or "Mute Timer":**

| Dimension | QuietLater | Volume Timer |
|---|---|---|
| Memorable | High — evocative, one idea | Low — generic descriptor |
| Differentiated | Yes — stands out in search | No — sounds like a feature |
| Searchable | Still discoverable (volume, mute, timer in keywords) | Over-relies on keywords |
| App Store name | Unique — reduces trademark conflicts | Likely unavailable or disputed |
| Tone | Calm, purposeful, premium | Functional, forgettable |
| Brand equity | Buildable | None |

**Why it still works for search:**
"Quiet" is semantically linked to "mute" and "silence." "Later" immediately signals the timer/scheduling concept. A user seeing the name for the first time in a search result understands the app's purpose before reading the description. The keywords and subtitle carry the functional terms ("volume," "mute," "timer") for App Store indexing.
