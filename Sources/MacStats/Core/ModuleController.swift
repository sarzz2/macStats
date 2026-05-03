import Cocoa
import SwiftUI

class ModuleController: NSObject, NSPopoverDelegate {
    var statusItem: NSStatusItem
    var popover: NSPopover
    var updateClosure: (NSButton) -> Void
    var iconName: String

    // Update interval kept at 2s (matches fast timer) but uses the already-computed published values
    // so no extra computation happens here — just a UI refresh.
    private var uiTimer: Timer?

    init(title: String, iconName: String, view: AnyView, popoverHeight: CGFloat = 300, width: CGFloat? = nil, updateClosure: @escaping (NSButton) -> Void) {
        if let w = width {
            self.statusItem = NSStatusBar.system.statusItem(withLength: w)
        } else {
            self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        self.popover = NSPopover()
        self.updateClosure = updateClosure
        self.iconName = iconName
        super.init()

        self.popover.delegate = self

        setupStatusItem()
        setupPopover(view: view, height: popoverHeight)

        // UI refresh timer — stored as strong reference on main RunLoop
        uiTimer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
        RunLoop.main.add(uiTimer!, forMode: .common)
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
            button.imagePosition = .imageLeft
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        updateUI()
    }

    private func setupPopover(view: AnyView, height: CGFloat) {
        popover.behavior = .transient
        let controller = NSHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 320, height: height)
        popover.contentViewController = controller
    }

    @objc func updateUI() {
        if let button = statusItem.button {
            updateClosure(button)
        }
    }

    private var eventMonitor: Any?

    @objc func togglePopover(_ sender: AnyObject?) {
        guard statusItem.button != nil else { return }
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            button.highlight(true)
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover(sender)
            }
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        statusItem.button?.highlight(false)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - NSPopoverDelegate
    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.highlight(false)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func popoverWillShow(_ notification: Notification) {
        statusItem.button?.highlight(true)
    }

    deinit {
        uiTimer?.invalidate()
    }
}
