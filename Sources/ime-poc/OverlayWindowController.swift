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
            
            // 少し遅延させてATOKの候補ウィンドウが表示されるのを待つ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                
                var windowOrigin = point
                
                // まずカーソル位置を基準に設定
                print("カーソル位置: \(point)")
                
                // IMEウィンドウの位置を検出して、その近くに表示
                if let imeWindowBounds = IMEWindowDetector.getIMEWindowBounds() {
                    print("IMEウィンドウの位置を検出: \(imeWindowBounds)")
                    // IMEウィンドウの右側に表示
                    windowOrigin.x = imeWindowBounds.maxX + 5
                    // Y座標はIMEウィンドウと同じ高さに
                    if let screen = NSScreen.main {
                        windowOrigin.y = screen.frame.height - imeWindowBounds.maxY
                    } else {
                        windowOrigin.y = imeWindowBounds.minY
                    }
                } else {
                    print("IMEウィンドウが見つかりません。カーソル位置を基準に表示")
                    // カーソル位置の近くに表示（座標系の変換に注意）
                    if let screen = NSScreen.main {
                        // スクリーン座標系からウィンドウ座標系に変換
                        let screenHeight = screen.frame.height
                        let cursorY = screenHeight - point.y  // Y座標を反転
                        
                        windowOrigin.x = point.x + 10
                        windowOrigin.y = cursorY - windowSize.height - 5
                        
                        // 画面外にはみ出さないように調整
                        if windowOrigin.y < 0 {
                            windowOrigin.y = cursorY + 20
                        }
                        if windowOrigin.x + windowSize.width > screen.frame.width {
                            windowOrigin.x = point.x - windowSize.width - 10
                        }
                    } else {
                        // フォールバック
                        windowOrigin.y = point.y - windowSize.height - 20
                    }
                }
                
                self.window?.setFrameOrigin(windowOrigin)
                
                if !self.isVisible {
                    self.window?.orderFront(nil)
                    self.isVisible = true
                }
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
        
        print("入力テキスト: \(inputText)")
        
        if inputText.contains("てすと") || inputText.contains("tesuto") || inputText.contains("test") {
            candidates.append("てすと")
        }
        
        if !inputText.isEmpty && inputText != "てすと" {
            candidates.append(inputText)
        }
        
        print("生成した候補: \(candidates)")
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