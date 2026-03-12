import SwiftUI

struct ContentView: View {
    @StateObject private var vm = QuietLaterViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Header
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                Divider()

                // MARK: Timer Section
                TimerSectionView(vm: vm)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                Divider()

                // MARK: Manual Section
                ManualSectionView(vm: vm)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                Divider()

                // MARK: Status Bar
                statusBar
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
        }
        .frame(width: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("QuietLater")
                .font(.system(.title2, design: .rounded, weight: .semibold))
            Text("Lower your volume, on time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)

            Text(vm.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: vm.statusMessage)
        .accessibilityLabel("Status: \(vm.statusMessage)")
    }

    private var statusDotColor: Color {
        switch vm.runState {
        case .idle:      return .secondary.opacity(0.4)
        case .running:   return .accentColor
        case .fadingOut: return .orange
        case .completed: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
