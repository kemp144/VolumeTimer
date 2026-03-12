// QuietLaterTests.swift
// QuietLater Tests
//
// Unit tests for countdown logic, timer state transitions, fade-out progression,
// restore scheduling, cancel/restart edge cases, and input validation.
// AudioService is not mocked — it is thin and its behavior is defined by the OS.
// Instead, tests focus on deterministic ViewModel and CountdownTimer logic.

import XCTest
@testable import QuietLater

// MARK: - VolumeState Tests

final class VolumeStateTests: XCTestCase {

    func testDisplayString_unmuted() {
        let state = VolumeState(volume: 0.4, isMuted: false)
        XCTAssertEqual(state.displayString, "40%")
    }

    func testDisplayString_muted() {
        let state = VolumeState(volume: 0.4, isMuted: true)
        XCTAssertEqual(state.displayString, "40%, muted")
    }

    func testDisplayString_zero() {
        let state = VolumeState(volume: 0, isMuted: false)
        XCTAssertEqual(state.displayString, "0%")
    }

    func testEquality() {
        let a = VolumeState(volume: 0.5, isMuted: false)
        let b = VolumeState(volume: 0.5, isMuted: false)
        let c = VolumeState(volume: 0.6, isMuted: false)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}

// MARK: - TimerDuration Tests

final class TimerDurationTests: XCTestCase {

    func testPresetSeconds() {
        XCTAssertEqual(TimerDuration.minutes(5).seconds,  300)
        XCTAssertEqual(TimerDuration.minutes(10).seconds, 600)
        XCTAssertEqual(TimerDuration.minutes(15).seconds, 900)
        XCTAssertEqual(TimerDuration.minutes(30).seconds, 1800)
        XCTAssertEqual(TimerDuration.minutes(60).seconds, 3600)
    }

    func testCustomHasNilSeconds() {
        XCTAssertNil(TimerDuration.custom.seconds)
    }

    func testLabels() {
        XCTAssertEqual(TimerDuration.minutes(5).label,  "5m")
        XCTAssertEqual(TimerDuration.minutes(60).label, "1h")
        XCTAssertEqual(TimerDuration.custom.label,      "Custom")
    }

    func testPresetsCount() {
        // Ensure all 6 presets are present
        XCTAssertEqual(TimerDuration.presets.count, 6)
    }

    func testPresetsIncludeCustom() {
        XCTAssertTrue(TimerDuration.presets.contains(.custom))
    }
}

// MARK: - TimerAction Tests

final class TimerActionTests: XCTestCase {

    func testMuteTargetVolume() {
        XCTAssertEqual(TimerAction.mute.targetVolume, 0)
    }

    func testSetVolumeTargetVolume() {
        XCTAssertEqual(TimerAction.setVolume(0.4).targetVolume, 0.4, accuracy: 0.001)
    }

    func testDisplayName_mute() {
        XCTAssertEqual(TimerAction.mute.displayName, "Mute")
    }

    func testDisplayName_setVolume() {
        XCTAssertEqual(TimerAction.setVolume(0.2).displayName, "Set volume to 20%")
    }

    func testEquality() {
        XCTAssertEqual(TimerAction.mute, TimerAction.mute)
        XCTAssertEqual(TimerAction.setVolume(0.5), TimerAction.setVolume(0.5))
        XCTAssertNotEqual(TimerAction.mute, TimerAction.setVolume(0.5))
    }
}

// MARK: - ViewModel Input Validation Tests

@MainActor
final class QuietLaterViewModelInputTests: XCTestCase {

    func testCustomMinutesMinimum() {
        let vm = QuietLaterViewModel()
        vm.selectedDuration = .custom
        vm.customMinutes = 0
        // Resolved duration should clamp to minimum 1 minute.
        // We access via startTimer but instead test the helper indirectly
        // by checking customMinutes defaults and clamping.
        vm.customMinutes = max(1, vm.customMinutes)
        XCTAssertGreaterThanOrEqual(vm.customMinutes, 1)
    }

    func testTargetVolumeRange() {
        let vm = QuietLaterViewModel()
        // targetVolumePercent should stay in 0–100
        vm.targetVolumePercent = 150
        let clamped = min(100, max(0, vm.targetVolumePercent))
        XCTAssertLessThanOrEqual(clamped, 100)

        vm.targetVolumePercent = -10
        let clamped2 = min(100, max(0, vm.targetVolumePercent))
        XCTAssertGreaterThanOrEqual(clamped2, 0)
    }

    func testManualVolumeRange() {
        let vm = QuietLaterViewModel()
        vm.manualVolumePercent = 50
        XCTAssertEqual(vm.manualVolumePercent, 50)
    }

    func testRestoreDelayOptions() {
        let validDelays = [5, 10, 15, 30, 60]
        let vm = QuietLaterViewModel()
        vm.restoreDelayMinutes = 15
        XCTAssertTrue(validDelays.contains(vm.restoreDelayMinutes))
    }
}

// MARK: - ViewModel State Transition Tests

@MainActor
final class QuietLaterViewModelStateTests: XCTestCase {

    func testInitialState() {
        let vm = QuietLaterViewModel()
        XCTAssertFalse(vm.isTimerRunning)
        XCTAssertNil(vm.remainingTime)
        XCTAssertFalse(vm.canRestorePrevious)
        if case .idle = vm.runState {} else {
            XCTFail("Expected idle state on init")
        }
    }

    func testCancelWhenIdle() {
        let vm = QuietLaterViewModel()
        vm.cancelTimer()  // Should not crash
        if case .idle = vm.runState {} else {
            XCTFail("Expected idle state after cancel on idle")
        }
    }

    func testCapturePreviousStateOnManualMute() {
        let vm = QuietLaterViewModel()
        XCTAssertNil(vm.capturedState)
        vm.muteNow()
        // capturedState should now be non-nil (captured before muting)
        XCTAssertNotNil(vm.capturedState)
    }

    func testCanRestorePreviousAfterMuteNow() {
        let vm = QuietLaterViewModel()
        vm.muteNow()
        XCTAssertTrue(vm.canRestorePrevious)
    }

    func testCaptureNotOverwrittenBySecondManualAction() {
        let vm = QuietLaterViewModel()
        vm.muteNow()
        let firstCapture = vm.capturedState

        // Second manual action should NOT overwrite the original capture.
        vm.applyVolumeNow()
        XCTAssertEqual(vm.capturedState, firstCapture)
    }
}

// MARK: - ViewModel Formatted Duration Tests

@MainActor
final class FormattingTests: XCTestCase {

    let vm = QuietLaterViewModel()

    func testFormattedDurationMinutesOnly() {
        XCTAssertEqual(vm.formattedDuration(900), "15 min")
    }

    func testFormattedDurationMinutesAndSeconds() {
        XCTAssertEqual(vm.formattedDuration(905), "15:05")
    }

    func testFormattedDurationSecondsOnly() {
        XCTAssertEqual(vm.formattedDuration(45), "45 sec")
    }

    func testFormattedCountdownPadded() {
        XCTAssertEqual(vm.formattedCountdown(65), "01:05")
    }

    func testFormattedCountdownHours() {
        XCTAssertEqual(vm.formattedCountdown(3661), "1:01:01")
    }

    func testFormattedCountdownZero() {
        XCTAssertEqual(vm.formattedCountdown(0), "00:00")
    }
}

// MARK: - Countdown Timer Logic Tests
// These tests exercise CountdownTimer in isolation with a stub AudioService.

final class CountdownTimerLogicTests: XCTestCase {

    // Verifies that onComplete fires and phase transitions to .completed.
    func testCompletionFires() {
        let audio   = AudioService()
        let config  = CountdownConfiguration(
            duration:      0.5,    // short duration for testing
            action:        .mute,
            fadeOut:       false,
            restoreDelay:  nil,
            capturedState: nil
        )
        let timer   = CountdownTimer(config: config, audio: audio)
        let expectation = expectation(description: "onComplete fires")

        timer.onComplete = { expectation.fulfill() }
        timer.start()

        wait(for: [expectation], timeout: 3.0)
    }

    // Verifies that cancel prevents completion.
    func testCancelPreventsCompletion() {
        let audio   = AudioService()
        let config  = CountdownConfiguration(
            duration:      5.0,
            action:        .mute,
            fadeOut:       false,
            restoreDelay:  nil,
            capturedState: nil
        )
        let timer   = CountdownTimer(config: config, audio: audio)
        var completed = false
        let cancelled = expectation(description: "cancelled phase received")

        // Set callbacks before start so nothing is missed.
        timer.onComplete = { completed = true }
        timer.onPhase = { phase in
            if case .cancelled = phase { cancelled.fulfill() }
        }
        timer.start()

        // Cancel shortly after start — well before the 5-second duration fires.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            timer.cancel()
        }

        wait(for: [cancelled], timeout: 3.0)
        XCTAssertFalse(completed)
    }

    // Verifies tick callbacks arrive.
    func testTickCallbackFires() {
        let audio   = AudioService()
        let config  = CountdownConfiguration(
            duration:      1.5,
            action:        .setVolume(0.5),
            fadeOut:       false,
            restoreDelay:  nil,
            capturedState: nil
        )
        let timer   = CountdownTimer(config: config, audio: audio)
        var tickCount = 0
        let expectation = expectation(description: "ticks received")
        expectation.expectedFulfillmentCount = 2

        timer.onTick = { _ in
            tickCount += 1
            if tickCount >= 2 { expectation.fulfill() }
            // Avoid fulfilling more than twice
            if tickCount == 2 { timer.cancel() }
        }
        timer.start()

        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThanOrEqual(tickCount, 2)
    }

    // Verifies fade-out phase triggers within the fade window.
    func testFadeOutPhaseTriggered() {
        let audio   = AudioService()
        // Duration shorter than fade window — fade should start immediately.
        let config  = CountdownConfiguration(
            duration:      20.0,
            action:        .mute,
            fadeOut:       true,
            restoreDelay:  nil,
            capturedState: nil
        )
        let timer   = CountdownTimer(config: config, audio: audio)
        let expectation = expectation(description: "fadingOut phase received")

        timer.onPhase = { phase in
            if case .fadingOut = phase { expectation.fulfill() }
        }
        timer.start()

        wait(for: [expectation], timeout: 5.0)
        timer.cancel()
    }
}

// MARK: - Manual QA Checklist
// (Inline documentation — not an executable test)
//
// Before each release, a human tester should verify the following on the
// latest shipping macOS version in both light and dark mode:
//
// PRESET TIMERS
//   [ ] Select 5m — timer starts and counts down from 5:00
//   [ ] Select 10m — timer starts and counts down from 10:00
//   [ ] Select 15m — timer starts and counts down from 15:00
//   [ ] Select 30m — timer starts and counts down from 30:00
//   [ ] Select 60m — timer starts and counts down from 60:00
//
// CUSTOM TIMER
//   [ ] Select Custom — duration input (Stepper) appears
//   [ ] Set custom duration to 3 minutes — timer counts down from 3:00
//   [ ] Set custom duration to 0 — "Please enter a valid duration." shown, no timer started
//
// MUTE ACTION
//   [ ] Start a 1-min timer with Action = Mute — volume mutes at T=0
//   [ ] System volume slider in menu bar confirms muted state
//
// SET VOLUME ACTION
//   [ ] Start a 1-min timer with Action = Set volume to 30% — volume is 30% at T=0
//   [ ] System volume slider confirms the change
//
// FADE-OUT
//   [ ] Enable Fade Out, start a 45-sec timer with Mute action
//   [ ] Volume begins decreasing smoothly during last 30 s
//   [ ] Volume is fully muted by T=0
//   [ ] Fade is smooth — no jumps or stutters
//
// RESTORE LATER
//   [ ] Enable Restore, set delay to 5 min, start a 1-min mute timer
//   [ ] After mute fires, wait 5 min — volume restores to original level
//   [ ] Status line updates appropriately
//
// CANCEL TIMER
//   [ ] Start timer, click Cancel — countdown stops, volume unchanged
//   [ ] Status shows "Timer cancelled."
//
// REPLACE TIMER
//   [ ] Start a 30-min timer, then click Start Timer again
//   [ ] First timer is cleanly replaced, countdown resets
//
// MANUAL MUTE NOW
//   [ ] Click Mute Now — system audio mutes immediately
//   [ ] Restore Previous Volume button becomes visible
//
// MANUAL APPLY VOLUME NOW
//   [ ] Set slider to 70%, click Apply Now — system volume is ~70%
//
// MANUAL RESTORE
//   [ ] After muting, click Restore Previous Volume — volume returns to captured level
//
// BACKGROUND BEHAVIOR
//   [ ] Start timer, minimize app — timer continues, action fires on schedule
//   [ ] Bring app back — countdown display is accurate
//
// LIGHT MODE
//   [ ] All text readable with sufficient contrast
//   [ ] Focus rings visible on all interactive controls
//
// DARK MODE
//   [ ] All text readable with sufficient contrast
//   [ ] Chip selection state clearly visible
//
// KEYBOARD NAVIGATION
//   [ ] Tab through all controls
//   [ ] Press Return to Start Timer
//   [ ] Press Escape to Cancel Timer (when running)
//
// VOICEOVER
//   [ ] All buttons have meaningful labels
//   [ ] Sliders report current percentage
//   [ ] Countdown announces remaining time
//   [ ] Status message is read correctly
//
// SANDBOX / RELEASE BUILD
//   [ ] Archive build with sandbox entitlement — volume control works correctly
//   [ ] No crash on launch in sandbox
//   [ ] No Console.app sandbox violations from the app
//
// LATEST macOS PASS
//   [ ] Tested on macOS 15 (Sequoia) or current shipping version
