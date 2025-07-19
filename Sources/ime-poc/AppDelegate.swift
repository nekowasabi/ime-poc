import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindowController: OverlayWindowController?
    private var inputMonitor: InputMonitor?
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("アプリケーション起動開始")
        setupStatusBarItem()
        print("ステータスバーアイテム設定完了")
        setupAccessibilityPermissions()
        print("アクセシビリティ権限確認完了")
        startInputMonitoring()
        print("入力モニタリング開始完了")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        inputMonitor?.stop()
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "IME"
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "IME POC is running", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    private func setupAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            showAccessibilityAlert()
        }
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Please grant accessibility permissions to ime-poc in System Preferences > Security & Privacy > Privacy > Accessibility"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
    
    private func startInputMonitoring() {
        overlayWindowController = OverlayWindowController()
        inputMonitor = InputMonitor()
        inputMonitor?.delegate = overlayWindowController
        inputMonitor?.start()
        
    }
}