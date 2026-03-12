// QuietLaterViewModel.swift
// QuietLater
//
// Central state manager for the app. Owns the AudioService, active
// CountdownTimer, and all UI-driving @Published properties.
// All mutation happens on the main thread.

import Foundation
import SwiftUI
import Combine

// MARK: - Timer UI State

enum TimerRunState: Equatable {
    case idle
    case running(remaining: TimeInterval)
    case fadingOut(remaining: TimeInterval)
    case completed
}

// MARK: - ViewModel

@MainActor
final class QuietLaterViewModel: ObservableObject {

    // MARK: - Timer Configuration

    @Published var selectedDuration: TimerDuration = .minutes(15)
    @Published var customMinutes: Int = 20           // used when selectedDuration == .custom
    @Published var actionKind: TimerActionKind = .mute
    @Published var targetVolumePercent: Double = 40  // 0–100, used when actionKind == .setVolume
    @Published var fadeOutEnabled: Bool = false
    @Published var restoreEnabled: Bool = false
    @Published var restoreDelayMinutes: Int = 15

    // MARK: - Timer State

    @Published private(set) var runState: TimerRunState = .idle
    @Published private(set) var capturedState: VolumeState?   // frozen at timer start

    // MARK: - Manual Section

    @Published var manualVolumePercent: Double = 50  // 0–100

    // MARK: - Status

    @Published private(set) var statusMessage: String = "QuietLater lowers your volume, on time."

    // MARK: - Dependencies

    let audio = AudioService()
    private var countdown: CountdownTimer?

    // MARK: - Init

    init() {
        // Seed manual volume slider from current system volume.
        if let state = audio.currentState() {
            manualVolumePercent = Double(state.volume * 100).rounded()
        }
    }

    // MARK: - Computed Helpers

    var isTimerRunning: Bool {
        switch runState {
        case .running, .fadingOut: return true
        default: return false
        }
    }

    var remainingTime: TimeInterval? {
        switch runState {
        case .running(let r), .fadingOut(let r): return r
        default: return nil
        }
    }

    var canRestorePrevious: Bool { capturedState != nil }

    // MARK: - Timer Actions

    func startTimer() {
        // If a timer is already running, cancel it silently and replace it.
        cancelTimer()

        let duration = resolvedDuration()
        guard duration > 0 else {
            statusMessage = "Please enter a valid duration."
            return
        }

        let action   = resolvedAction()
        let state    = audio.currentState()
        capturedState = state

        let config = CountdownConfiguration(
            duration:      duration,
            action:        action,
            fadeOut:       fadeOutEnabled,
            restoreDelay:  restoreEnabled ? TimeInterval(restoreDelayMinutes * 60) : nil,
            capturedState: state
        )

        let timer = CountdownTimer(config: config, audio: audio)
        countdown = timer

        timer.onTick = { [weak self] remaining in
            guard let self else { return }
            switch self.runState {
            case .fadingOut: self.runState = .fadingOut(remaining: remaining)
            default:         self.runState = .running(remaining: remaining)
            }
            self.updateStatusMessage()
        }

        timer.onPhase = { [weak self] phase in
            guard let self else { return }
            switch phase {
            case .fadingOut:
                if let r = self.remainingTime {
                    self.runState = .fadingOut(remaining: r)
                }
                self.updateStatusMessage()
            case .completed:
                self.runState = .completed
                self.statusMessage = self.completionMessage()
            case .cancelled:
                self.runState = .idle
                self.statusMessage = "Timer cancelled."
            case .running:
                break
            }
        }

        timer.onComplete = { [weak self] in
            guard let self else { return }
            self.runState = .completed
            self.statusMessage = self.completionMessage()
        }

        runState = .running(remaining: duration)
        updateStatusMessage()
        timer.start()
    }

    func cancelTimer() {
        countdown?.cancel()
        countdown = nil
        if isTimerRunning || runState == .completed {
            runState = .idle
            statusMessage = "Timer cancelled."
        }
    }

    // MARK: - Manual Actions

    func muteNow() {
        captureStateIfNeeded()
        audio.setMuted(true)
        statusMessage = "Muted now."
    }

    func applyVolumeNow() {
        captureStateIfNeeded()
        let vol = Float(manualVolumePercent / 100)
        audio.setMuted(false)
        audio.setVolume(vol)
        statusMessage = "Volume set to \(Int(manualVolumePercent.rounded()))%."
    }

    func restorePreviousVolume() {
        guard let state = capturedState else { return }
        audio.applyState(state)
        statusMessage = "Restored to \(state.displayString)."
    }

    // MARK: - Helpers

    private func resolvedDuration() -> TimeInterval {
        switch selectedDuration {
        case .minutes(let m): return TimeInterval(m * 60)
        case .custom:         return TimeInterval(max(1, customMinutes) * 60)
        }
    }

    private func resolvedAction() -> TimerAction {
        switch actionKind {
        case .mute:      return .mute
        case .setVolume: return .setVolume(Float(targetVolumePercent / 100))
        }
    }

    private func captureStateIfNeeded() {
        // Capture only once — so repeated manual actions don't overwrite the original.
        if capturedState == nil {
            capturedState = audio.currentState()
        }
    }

    private func updateStatusMessage() {
        guard let remaining = remainingTime else { return }
        let durStr = formattedDuration(remaining)
        let endTime = Date().addingTimeInterval(remaining)
        let endStr  = Self.timeFormatter.string(from: endTime)

        switch actionKind {
        case .mute:
            if restoreEnabled {
                statusMessage = "QuietLater will mute your Mac in \(durStr) (at \(endStr)) and restore volume \(restoreDelayMinutes) min later."
            } else {
                statusMessage = "QuietLater will mute your Mac in \(durStr) (at \(endStr))."
            }
        case .setVolume:
            let pct = Int(targetVolumePercent.rounded())
            if restoreEnabled {
                statusMessage = "QuietLater will set volume to \(pct)% at \(endStr) and restore volume \(restoreDelayMinutes) min later."
            } else {
                statusMessage = "QuietLater will set volume to \(pct)% at \(endStr)."
            }
        }

        if case .fadingOut = runState {
            statusMessage = "Fading out… " + statusMessage
        }
    }

    private func completionMessage() -> String {
        switch actionKind {
        case .mute:
            return restoreEnabled
                ? "Muted. Volume will restore in \(restoreDelayMinutes) min."
                : "Muted."
        case .setVolume:
            let pct = Int(targetVolumePercent.rounded())
            return restoreEnabled
                ? "Volume set to \(pct)%. Restoring in \(restoreDelayMinutes) min."
                : "Volume set to \(pct)%."
        }
    }

    // MARK: - Formatting

    func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        if m > 0 {
            return s == 0 ? "\(m) min" : "\(m):\(String(format: "%02d", s))"
        }
        return "\(s) sec"
    }

    func formattedCountdown(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
}
