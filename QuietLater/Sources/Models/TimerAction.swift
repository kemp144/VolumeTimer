import Foundation

/// The action to perform when the countdown timer expires.
enum TimerAction: Equatable {
    /// Mute the system output.
    case mute
    /// Set system output volume to a specific level (0.0 – 1.0).
    case setVolume(Float)

    var displayName: String {
        switch self {
        case .mute: return "Mute"
        case .setVolume(let v): return "Set volume to \(Int(v * 100))%"
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
    case mute = "Mute"
    case setVolume = "Set volume to…"

    var id: String { rawValue }
}
