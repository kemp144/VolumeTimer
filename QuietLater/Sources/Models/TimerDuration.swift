import Foundation

/// Preset countdown durations available in the UI.
enum TimerDuration: Hashable, Identifiable {
    case minutes(Int)
    case custom

    var id: String {
        switch self {
        case .minutes(let m): return "\(m)m"
        case .custom: return "custom"
        }
    }

    var label: String {
        switch self {
        case .minutes(let m) where m < 60:
            return String(format: NSLocalizedString("%ldm", comment: "Duration chip label: X minutes, e.g. '15m'"), m)
        case .minutes(let m):
            return String(format: NSLocalizedString("%ldh", comment: "Duration chip label: X hours, e.g. '1h'"), m / 60)
        case .custom:
            return NSLocalizedString("Custom", comment: "Duration chip label: custom duration")
        }
    }

    /// Resolved total seconds. Returns nil for `.custom` (caller supplies value).
    var seconds: TimeInterval? {
        switch self {
        case .minutes(let m): return TimeInterval(m * 60)
        case .custom: return nil
        }
    }

    static let presets: [TimerDuration] = [
        .minutes(5), .minutes(10), .minutes(15), .minutes(30), .minutes(60), .custom
    ]
}
