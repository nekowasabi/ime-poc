import Cocoa
import Carbon

protocol InputMonitorDelegate: AnyObject {
    func inputMonitor(_ monitor: InputMonitor, didDetectInput text: String, at point: NSPoint)
    func inputMonitorDidDetectClear(_ monitor: InputMonitor)
}

class InputMonitor {
    weak var delegate: InputMonitorDelegate?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var currentInputText = ""
    private var lastEventTime: TimeInterval = 0
    private let inputTimeout: TimeInterval = 0.5
    
    func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                let monitor = Unmanaged<InputMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            // キーコードを取得
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print("キーコード: \(keyCode)")
            
            // 日本語入力中はキーコードから文字を推測
            if isJapaneseInput() {
                print("日本語入力中のため、キーコードから推測")
                processKeyCode(Int(keyCode), event: event)
            } else {
                // 通常の文字取得を試みる
                if let characters = event.getStringValue(), !characters.isEmpty {
                    print("通常の文字取得成功: '\(characters)'")
                    processInput(characters, event: event)
                } else {
                    print("文字取得失敗、キーコードから推測")
                    processKeyCode(Int(keyCode), event: event)
                }
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func processInput(_ characters: String, event: CGEvent) {
        let currentTime = Date().timeIntervalSince1970
        
        if currentTime - lastEventTime > inputTimeout {
            currentInputText = ""
        }
        
        lastEventTime = currentTime
        
        print("キー入力検出: \(characters), 日本語入力: \(isJapaneseInput())")
        
        currentInputText += characters
        print("現在の入力文字列: '\(currentInputText)'")
        
        // リセット条件を緩和
        if currentInputText.count > 10 {
            print("入力文字列をリセット（10文字超過）")
            currentInputText = ""
        }
        
        // マッチング条件を緩和（大文字小文字を無視）
        let lowerInput = currentInputText.lowercased()
        if lowerInput.contains("test") || 
           lowerInput.contains("tesuto") ||  // ローマ字入力を追加
           currentInputText.contains("てすと") || 
           currentInputText.contains("テスト") {
            print("候補表示トリガー検出！")
            let cursorLocation = getCursorLocation() ?? NSEvent.mouseLocation
            print("カーソル位置: \(cursorLocation)")
            delegate?.inputMonitor(self, didDetectInput: currentInputText, at: cursorLocation)
        }
        
        // Escapeキーや確定でリセット
        if characters == "\u{1B}" || characters == "\r" || characters == "\n" {
            print("入力確定/キャンセルを検出")
            currentInputText = ""
            delegate?.inputMonitorDidDetectClear(self)
        }
    }
    
    private func processKeyCode(_ keyCode: Int, event: CGEvent) {
        print("キーコードから文字を推測: \(keyCode)")
        
        // 日本語入力中のキーコードマッピング（簡易版）
        let keyMap: [Int: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
            11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2", 20: "3",
            21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j", 39: "'",
            40: "k", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "n", 46: "m", 47: ".", 50: "`",
            // Enter, Space, Escape, Delete
            36: "\r", 49: " ", 53: "\u{1B}", 51: "\u{8}"
        ]
        
        if let character = keyMap[keyCode] {
            // 日本語入力中の場合はキーコードから推測した文字を使用
            if isJapaneseInput() {
                // Deleteキーの処理
                if character == "\u{8}" {
                    if !currentInputText.isEmpty {
                        currentInputText.removeLast()
                        print("文字削除、現在の入力文字列: '\(currentInputText)'")
                    }
                } else {
                    currentInputText += character
                    print("推測した文字: '\(character)', 現在の入力文字列: '\(currentInputText)'")
                }
                
                // マッチング条件を確認
                let lowerInput = currentInputText.lowercased()
                if lowerInput.contains("test") || 
                   lowerInput.contains("tesuto") ||  // ローマ字入力を追加
                   currentInputText.contains("てすと") || 
                   currentInputText.contains("テスト") {
                    print("候補表示トリガー検出！")
                    let cursorLocation = getCursorLocation() ?? NSEvent.mouseLocation
                    print("カーソル位置: \(cursorLocation)")
                    delegate?.inputMonitor(self, didDetectInput: currentInputText, at: cursorLocation)
                }
                
                // リセット条件
                if currentInputText.count > 20 || character == "\r" || character == "\u{1B}" {
                    currentInputText = ""
                    delegate?.inputMonitorDidDetectClear(self)
                }
            }
        }
    }
    
    private func isJapaneseInput() -> Bool {
        if let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() {
            if let sourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                let sourceIDString = Unmanaged<CFString>.fromOpaque(sourceID).takeUnretainedValue() as String
                return sourceIDString.contains("Japanese") || sourceIDString.contains("Hiragana") || sourceIDString.contains("Katakana")
            }
        }
        return false
    }
    
    private func getCursorLocation() -> NSPoint? {
        // まずフォーカスされた要素を取得
        guard let systemWideElement = AXUIElementCreateSystemWide() as AXUIElement? else { return nil }
        
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if result == .success, let element = focusedElement as! AXUIElement? {
            // 選択されたテキストの範囲を取得
            var selectedRange: CFTypeRef?
            let rangeResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRange)
            
            if rangeResult == .success, let range = selectedRange {
                // 選択範囲の境界を取得
                var boundsValue: CFTypeRef?
                let parameter = range as! AXValue
                let boundsResult = AXUIElementCopyParameterizedAttributeValue(
                    element,
                    kAXBoundsForRangeParameterizedAttribute as CFString,
                    parameter,
                    &boundsValue
                )
                
                if boundsResult == .success, let bounds = boundsValue {
                    var rect = CGRect.zero
                    if AXValueGetValue(bounds as! AXValue, .cgRect, &rect) {
                        // スクリーン座標系で返す（下側に候補を表示）
                        return NSPoint(x: rect.minX, y: rect.maxY)
                    }
                }
            }
            
            // フォールバック：要素の位置を取得
            var position: CFTypeRef?
            let posResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)
            
            if posResult == .success, let posValue = position {
                var point = CGPoint.zero
                if AXValueGetValue(posValue as! AXValue, .cgPoint, &point) {
                    return NSPoint(x: point.x, y: point.y + 20) // 少し下にオフセット
                }
            }
        }
        
        // 最終フォールバック：マウス位置
        return NSEvent.mouseLocation
    }
}

extension CGEvent {
    func getStringValue() -> String? {
        var length = 0
        self.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        
        guard length > 0 else { 
            print("文字列長が0です")
            return nil 
        }
        
        var buffer = [UniChar](repeating: 0, count: length)
        self.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: nil, unicodeString: &buffer)
        
        let result = String(utf16CodeUnits: buffer, count: length)
        print("取得した文字列: '\(result)'")
        return result
    }
}