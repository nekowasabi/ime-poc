import Cocoa

class OverlayWindowController: NSObject {
    private var window: NSWindow?
    private var candidateListView: CandidateListView?
    private var candidates: [String] = []
    private var isVisible = false
    
    override init() {
        super.init()
        setupWindow()
    }
    
    private func setupWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 200, height: 100)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window?.level = .floating
        window?.isOpaque = false
        window?.backgroundColor = NSColor.clear
        window?.hasShadow = true
        window?.isReleasedWhenClosed = false
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        candidateListView = CandidateListView(frame: contentRect)
        candidateListView?.delegate = self
        window?.contentView = candidateListView
    }
    
    func showCandidates(at point: NSPoint, with inputText: String) {
        updateCandidates(for: inputText)
        
        if !candidates.isEmpty {
            candidateListView?.updateCandidates(candidates)
            
            let windowSize = candidateListView?.calculateWindowSize() ?? NSSize(width: 200, height: 100)
            window?.setContentSize(windowSize)
            
            var windowOrigin = point
            windowOrigin.y -= windowSize.height + 20
            window?.setFrameOrigin(windowOrigin)
            
            if !isVisible {
                window?.orderFront(nil)
                isVisible = true
            }
        } else {
            hide()
        }
    }
    
    func hide() {
        if isVisible {
            window?.orderOut(nil)
            isVisible = false
        }
    }
    
    private func updateCandidates(for inputText: String) {
        candidates = []
        
        if inputText.contains("てすと") || inputText.contains("tesuto") || inputText.contains("test") {
            candidates.append("てすと")
        }
        
        if !inputText.isEmpty {
            candidates.append(inputText)
        }
    }
}

extension OverlayWindowController: InputMonitorDelegate {
    func inputMonitor(_ monitor: InputMonitor, didDetectInput text: String, at point: NSPoint) {
        showCandidates(at: point, with: text)
    }
    
    func inputMonitorDidDetectClear(_ monitor: InputMonitor) {
        hide()
    }
}

extension OverlayWindowController: CandidateListViewDelegate {
    func candidateListView(_ view: CandidateListView, didSelectCandidate candidate: String) {
        insertTextAtCursor(candidate)
        hide()
    }
    
    private func insertTextAtCursor(_ text: String) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for character in text {
            if let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: 0,
                keyDown: true
            ) {
                event.keyboardSetUnicodeString(stringLength: 1, unicodeString: [character.utf16.first ?? 0])
                event.post(tap: .cgAnnotatedSessionEventTap)
            }
        }
    }
}