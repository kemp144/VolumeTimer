import SwiftUI

struct TimerSectionView: View {
    @ObservedObject var vm: QuietLaterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // MARK: Duration Presets
            VStack(alignment: .leading, spacing: 8) {
                Label("After", systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(.primary)

                DurationChipRow(selected: $vm.selectedDuration)

                if vm.selectedDuration == .custom {
                    customDurationInput
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // MARK: Action
            VStack(alignment: .leading, spacing: 8) {
                Label("Do this", systemImage: "speaker.wave.2")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Picker("Action", selection: $vm.actionKind) {
                    ForEach(TimerActionKind.allCases) { kind in
                        Text(verbatim: kind.localizedTitle).tag(kind)
                    }
                }
                .pickerStyle(.radioGroup)
                .accessibilityLabel("Timer action")

                if vm.actionKind == .setVolume {
                    volumeTargetSlider
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // MARK: Options
            VStack(alignment: .leading, spacing: 10) {
                Label("Options", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Toggle(isOn: $vm.fadeOutEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fade out in the last 30 seconds")
                        Text("Gradually lower volume before the timer ends")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $vm.restoreEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Restore previous volume later")
                        Text("Bring back your original volume after a delay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if vm.restoreEnabled {
                    restoreDelayPicker
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // MARK: Controls
            timerControls

            // MARK: Live Countdown
            if vm.isTimerRunning, let remaining = vm.remainingTime {
                CountdownDisplayView(
                    remaining: remaining,
                    isFading: { if case .fadingOut = vm.runState { return true }; return false }(),
                    formatted: vm.formattedCountdown(remaining)
                )
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if case .completed = vm.runState {
                completedBadge
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.selectedDuration == .custom)
        .animation(.easeInOut(duration: 0.25), value: vm.actionKind)
        .animation(.easeInOut(duration: 0.25), value: vm.restoreEnabled)
        .animation(.easeInOut(duration: 0.25), value: vm.isTimerRunning)
        .animation(.easeInOut(duration: 0.25), value: vm.runState == .completed)
    }

    // MARK: - Sub-views

    private var customDurationInput: some View {
        HStack(spacing: 8) {
            Text("Duration:")

            TextField(
                "",
                value: $vm.customMinutes,
                format: .number.grouping(.never)
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 68)
            .multilineTextAlignment(.trailing)
            .onChange(of: vm.customMinutes) { newValue in
                vm.customMinutes = min(600, max(1, newValue))
            }

            Text(verbatim: NSLocalizedString("min", comment: "Duration unit label for custom minute entry"))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()
        }
        .accessibilityLabel(String(format: NSLocalizedString("Custom duration: %ld minutes", comment: "Accessibility label for custom duration stepper; %ld = minutes"), vm.customMinutes))
    }

    private var volumeTargetSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Target volume")
                Spacer()
                Text(verbatim: String(format: NSLocalizedString("%ld%%", comment: "Volume state: percentage only, e.g. '40%'"), Int(vm.targetVolumePercent.rounded())))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }
            .font(.subheadline)

            Slider(value: $vm.targetVolumePercent, in: 0...100, step: 1)
                .accessibilityLabel(String(format: NSLocalizedString("Target volume: %ld percent", comment: "Accessibility label for target volume slider; %ld = percentage"), Int(vm.targetVolumePercent.rounded())))
        }
    }

    private var restoreDelayPicker: some View {
        HStack(spacing: 8) {
            Text("Restore after")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Restore delay", selection: $vm.restoreDelayMinutes) {
                ForEach([5, 10, 15, 30, 60], id: \.self) { n in
                    Text(verbatim: String(format: NSLocalizedString("%ld min", comment: "Duration display: whole minutes; %ld = number of minutes"), n)).tag(n)
                }
            }
            .labelsHidden()
            .frame(width: 100)
        }
    }

    private var timerControls: some View {
        HStack(spacing: 12) {
            Button {
                vm.startTimer()
            } label: {
                Label(vm.isTimerRunning ? "Replace Timer" : "Start Timer",
                      systemImage: vm.isTimerRunning ? "arrow.clockwise" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [])
            .accessibilityHint("Starts the countdown with your selected settings")

            if vm.isTimerRunning {
                Button {
                    vm.cancelTimer()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.escape, modifiers: [])
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }

    private var completedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Done")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
