// CountdownTimer.swift
// QuietLater
//
// Manages countdown, optional fade-out, action execution, and optional restore.
// All callbacks are guaranteed to arrive on the main thread.
//
// DESIGN NOTE — manual vs timer volume changes:
// If the user manually changes system volume while a countdown is running,
// the captured restore state is NOT updated (it was frozen at timer-start).
// The fade-out origin volume is recaptured at fade-start so the fade always
// progresses from whatever the actual volume is at that moment.

import Foundation

// MARK: - Configuration

struct CountdownConfiguration {
    let duration:        TimeInterval     // total seconds for the countdown
    let action:          TimerAction      // what to do when time is up
    let fadeMode:        FadeMode         // how volume should fade before the timer ends
    let restoreDelay:    TimeInterval?    // nil = no restore; else seconds after action
    let capturedState:   VolumeState?     // the state to restore (captured at timer start)
}

enum FadeMode: Equatable {
    case none
    case last30Seconds
    case fullDuration
}

// MARK: - Phase

enum CountdownPhase: Equatable {
    case running
    case fadingOut
    case completed
    case cancelled
}

// MARK: - CountdownTimer

/// A single-use countdown object. Create a new instance for each timer run.
final class CountdownTimer {

    // Callbacks — always called on main thread
    var onTick:      ((TimeInterval) -> Void)?   // remaining seconds
    var onPhase:     ((CountdownPhase) -> Void)?
    var onComplete:  (() -> Void)?               // fired after action is applied

    private let config:       CountdownConfiguration
    private let audio:        AudioService
    private var remaining:    TimeInterval
    private var phase:        CountdownPhase = .running
    private var tickTimer:    Timer?
    private var restoreTimer: Timer?

    /// Volume at the moment the fade started (so the fade originates from reality).
    private var fadeStartVolume: Float = 0
    private var fadeStartRemaining: TimeInterval = 0
    private var fadeDuration: TimeInterval = 0

    static let fadeWindow: TimeInterval = 30  // seconds before end where fade begins
    static let tickInterval: TimeInterval = 0.5

    init(config: CountdownConfiguration, audio: AudioService) {
        self.config    = config
        self.audio     = audio
        self.remaining = config.duration
    }

    // MARK: - Lifecycle

    func start() {
        phase = .running
        if config.fadeMode == .fullDuration {
            beginFade(duration: max(config.duration, Self.tickInterval))
            phase = .fadingOut
            onPhase?(.fadingOut)
        }
        scheduleTickTimer()
    }

    func cancel() {
        stopTimers()
        phase = .cancelled
        onPhase?(.cancelled)
    }

    // MARK: - Timer

    private func scheduleTickTimer() {
        tickTimer = Timer.scheduledTimer(
            withTimeInterval: Self.tickInterval,
            repeats: true
        ) { [weak self] _ in
            self?.tick()
        }
        // Ensure the timer fires even when a modal is up or the user is dragging.
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    private func tick() {
        remaining -= Self.tickInterval
        remaining = max(0, remaining)

        onTick?(remaining)

        if remaining <= 0 {
            finish()
            return
        }

        if shouldStartLast30SecondFade {
            beginFade(duration: min(Self.fadeWindow, remaining))
            phase = .fadingOut
            onPhase?(.fadingOut)
        }

        // Apply incremental fade.
        if phase == .fadingOut {
            applyFadeStep()
        }
    }

    private func applyFadeStep() {
        guard phase == .fadingOut, remaining > 0, fadeDuration > 0 else { return }
        let elapsed = min(fadeDuration, max(0, fadeStartRemaining - remaining))
        let progress = elapsed / fadeDuration
        let newVolume = fadeStartVolume * Float(1.0 - progress)
        audio.setVolume(max(0, newVolume))
    }

    private func finish() {
        stopTimers()
        phase = .completed

        // Apply the configured action.
        switch config.action {
        case .mute:
            audio.setMuted(true)
        case .setVolume(let v):
            audio.setVolume(v)
            // If fading out to a non-zero target, the fade ended at 0;
            // now jump to the requested target level.
            if config.fadeMode != .none { audio.setMuted(false) }
        }

        onPhase?(.completed)
        onComplete?()

        // Schedule restore if requested.
        if let delay = config.restoreDelay, let saved = config.capturedState {
            scheduleRestore(after: delay, state: saved)
        }
    }

    private func scheduleRestore(after delay: TimeInterval, state: VolumeState) {
        restoreTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.audio.applyState(state)
        }
        RunLoop.main.add(restoreTimer!, forMode: .common)
    }

    private func stopTimers() {
        tickTimer?.invalidate()
        tickTimer = nil
        restoreTimer?.invalidate()
        restoreTimer = nil
    }

    private var shouldStartLast30SecondFade: Bool {
        config.fadeMode == .last30Seconds &&
        phase == .running &&
        remaining <= Self.fadeWindow
    }

    private func beginFade(duration: TimeInterval) {
        fadeStartVolume = audio.currentState()?.volume ?? 1.0
        fadeStartRemaining = remaining
        fadeDuration = max(duration, Self.tickInterval)
    }

    deinit {
        stopTimers()
    }
}
