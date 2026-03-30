import SwiftUI

@main
struct NeuralClawSetupApp: App {
    @NSApplicationDelegateAdaptor(SetupAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SetupWizardView()
                .frame(width: 720, height: 700)
                .fixedSize()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class SetupAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Standard windowed app — show in dock
        NSApp.setActivationPolicy(.regular)

        // Set app icon from bundled resource
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }

        // Center the window on screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                window.center()
                window.makeKeyAndOrderFront(nil)
                window.isMovableByWindowBackground = true
                // Set the window title for accessibility
                window.title = "NeuralClaw Setup"
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
