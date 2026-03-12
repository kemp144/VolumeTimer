import SwiftUI

/// Large countdown display shown while a timer is active.
struct CountdownDisplayView: View {
    let remaining: TimeInterval
    let isFading: Bool
    let formatted: String   // pre-formatted "MM:SS" or "H:MM:SS"

    var body: some View {
        VStack(spacing: 6) {
            Text(formatted)
                .font(.system(size: 56, weight: .thin, design: .monospaced))
                .foregroundStyle(isFading ? Color.orange : Color.primary)
                .contentTransition(.numericText(countsDown: true))
                .animation(.easeInOut(duration: 0.2), value: formatted)
                .accessibilityLabel(String(format: NSLocalizedString("Time remaining: %@", comment: "Accessibility label for countdown timer; %@ = formatted time string"), formatted))

            if isFading {
                HStack(spacing: 4) {
                    Image(systemName: "waveform.slash")
                        .imageScale(.small)
                    Text("Fading out…")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.vertical, 12)
    }
}
