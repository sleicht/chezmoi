import AppKit
import SwiftUI

// ── Configuration ────────────────────────────────────────────────────────────
let displayDuration: TimeInterval = 2.0
let fadeDuration: TimeInterval = 0.3

// ── HUD View ─────────────────────────────────────────────────────────────────
struct HUDView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
            )
    }
}

// ── App Delegate ─────────────────────────────────────────────────────────────
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let message: String

    init(message: String) {
        self.message = message
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI content
        let hostingView = NSHostingView(rootView: HUDView(text: message))
        hostingView.setFrameSize(hostingView.fittingSize)

        // Create a borderless, transparent, floating window
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true

        // Center on the screen with the mouse cursor (active screen)
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = hostingView.fittingSize
            let x = screenFrame.midX - windowSize.width / 2
            let y = screenFrame.midY - windowSize.height / 2 + screenFrame.height * 0.2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.alphaValue = 0
        window.orderFrontRegardless()

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = fadeDuration
            window.animator().alphaValue = 1
        }

        // After display duration, fade out and quit
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [self] in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = fadeDuration
                window.animator().alphaValue = 0
            }, completionHandler: {
                NSApplication.shared.terminate(nil)
            })
        }
    }
}

// ── Main ─────────────────────────────────────────────────────────────────────
let message: String
if CommandLine.arguments.count > 1 {
    message = CommandLine.arguments.dropFirst().joined(separator: " ")
} else {
    fputs("Usage: hyprspace-hud <message>\n", stderr)
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // No dock icon, no menu bar
let delegate = AppDelegate(message: message)
app.delegate = delegate
app.run()
