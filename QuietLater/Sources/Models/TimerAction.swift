import Foundation

/// The action to perform when the countdown timer expires.
enum TimerAction: Equatable {
    /// Mute the system output.
    case mute
    /// Set system output volume to a specific level (0.0 – 1.0).
    case setVolume(Float)

    var displayName: String {
        switch self {
        case .mute:
            return NSLocalizedString("Mute", comment: "Timer action: mute the system audio")
        case .setVolume(let v):
            return String(format: NSLocalizedString("Set volume to %ld%%", comment: "Timer action display name; %ld = integer percentage"), Int(v * 100))
        }
    }

    /// The target volume scalar this action will produce (0 = muted/silent).
    var targetVolume: Float {
        switch self {
        case .mute: return 0
        case .setVolume(let v): return v
        }
    }
}

/// Identifies the action type for use with Picker / RadioGroup bindings.
enum TimerActionKind: String, CaseIterable, Identifiable {
    case mute
    case setVolume

    var id: Self { self }

    var localizedTitle: String {
        switch self {
        case .mute:
            return NSLocalizedString("Mute", comment: "Action picker option: mute the system audio")
        case .setVolume:
            return NSLocalizedString("Set volume to…", comment: "Action picker option: set the system volume to a target level")
        }
    }
}
