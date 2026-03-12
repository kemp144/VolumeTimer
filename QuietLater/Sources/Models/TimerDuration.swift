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
        case .minutes(let m) where m < 60: return "\(m)m"
        case .minutes(let m): return "\(m / 60)h"
        case .custom: return "Custom"
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
