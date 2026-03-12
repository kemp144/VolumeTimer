import SwiftUI

/// A single selectable chip for preset timer durations.
struct DurationChip: View {
    let duration: TimerDuration
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(duration.label)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(isSelected ? 0.12 : 0.04),
                                radius: isSelected ? 3 : 1, y: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(duration.label) preset")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Row of preset duration chips.
struct DurationChipRow: View {
    @Binding var selected: TimerDuration

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimerDuration.presets) { preset in
                DurationChip(duration: preset, isSelected: selected == preset) {
                    selected = preset
                }
            }
        }
    }
}
