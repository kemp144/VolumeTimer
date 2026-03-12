import SwiftUI

@main
struct QuietLaterApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 420, height: 680)
        .windowResizability(.contentSize)
        .commands {
            // Standard macOS menu items
            CommandGroup(replacing: .appInfo) {
                Button("About QuietLater") {
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "QuietLater",
                            .credits: NSAttributedString(
                                string: NSLocalizedString("A calm, focused utility for controlling your Mac's volume — now or after a timer.", comment: "About panel credits text"),
                                attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
                            ),
                            .version: ""
                        ]
                    )
                }
            }
            CommandGroup(replacing: .newItem) {}   // No "New Window" for single-window utility
        }
    }
}
