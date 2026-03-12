import SwiftUI

struct ManualSectionView: View {
    @ObservedObject var vm: QuietLaterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Label("Do it now", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            // Volume slider + Apply button
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Volume")
                        .font(.subheadline)
                    Spacer()
                    Text(verbatim: String(format: NSLocalizedString("%ld%%", comment: "Volume state: percentage only, e.g. '40%'"), Int(vm.manualVolumePercent.rounded())))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
                Slider(value: $vm.manualVolumePercent, in: 0...100, step: 1)
                    .accessibilityLabel(String(format: NSLocalizedString("Immediate volume: %ld percent", comment: "Accessibility label for immediate volume slider; %ld = percentage"), Int(vm.manualVolumePercent.rounded())))
            }

            HStack(spacing: 10) {
                Button {
                    vm.applyVolumeNow()
                } label: {
                    Label("Apply Now", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityHint("Sets system volume to the selected level immediately")

                Button {
                    vm.muteNow()
                } label: {
                    Label("Mute Now", systemImage: "speaker.slash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityHint("Mutes system audio immediately")
            }

            if vm.canRestorePrevious {
                Button {
                    vm.restorePreviousVolume()
                } label: {
                    Label("Restore Previous Volume",
                          systemImage: "arrow.uturn.backward.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityHint("Restores volume to the level captured when you last started a timer or manual action")
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.canRestorePrevious)
    }
}
