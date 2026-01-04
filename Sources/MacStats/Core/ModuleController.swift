import Cocoa
import SwiftUI

class ModuleController: NSObject, NSPopoverDelegate {
    var statusItem: NSStatusItem
    var popover: NSPopover
    var updateClosure: (NSButton) -> Void
    var iconName: String
    
    init(title: String, iconName: String, view: AnyView, width: CGFloat? = nil, updateClosure: @escaping (NSButton) -> Void) {
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
        setupPopover(view: view)
        
        // Start update timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
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
    
    private func setupPopover(view: AnyView) {
        popover.behavior = .transient
        // Wrap in a sizing controller
        let controller = NSHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 320, height: 300)
        popover.contentViewController = controller
        // popover.appearance = nil // Default to system theme
    }
    
    @objc func updateUI() {
        if let button = statusItem.button {
            updateClosure(button)
        }
    }
    
    private var eventMonitor: Any?
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if statusItem.button != nil {
            if popover.isShown {
                closePopover(sender)
            } else {
                showPopover(sender)
            }
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            button.highlight(true)
            
            // Monitor clicks outside
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
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
}
