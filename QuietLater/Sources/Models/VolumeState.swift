import Foundation

/// A snapshot of the system output volume at a point in time.
/// Used to capture state before an action so it can be restored later.
struct VolumeState: Equatable {
    /// Volume scalar, 0.0 (silent) to 1.0 (full).
    let volume: Float
    /// Whether the output was muted independently of the volume level.
    let isMuted: Bool

    /// A human-readable summary, e.g. "40%, unmuted".
    var displayString: String {
        let pct = Int((volume * 100).rounded())
        return isMuted ? "\(pct)%, muted" : "\(pct)%"
    }
}
