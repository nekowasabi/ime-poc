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
            if let characters = event.getStringValue() {
                processInput(characters, event: event)
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
        
        if isJapaneseInput() {
            currentInputText += characters
            
            if let cursorLocation = getCursorLocation() {
                delegate?.inputMonitor(self, didDetectInput: currentInputText, at: cursorLocation)
            }
        } else {
            if !currentInputText.isEmpty {
                currentInputText = ""
                delegate?.inputMonitorDidDetectClear(self)
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
        if let systemWideElement = AXUIElementCreateSystemWide() as AXUIElement? {
            var focusedElement: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
            
            if result == .success, let element = focusedElement {
                var position: CFTypeRef?
                let posResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &position)
                
                if posResult == .success {
                    // Get the position of the focused element
                    var elementPosition: CFTypeRef?
                    let positionResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXPositionAttribute as CFString, &elementPosition)
                    
                    if positionResult == .success, let posValue = elementPosition {
                        var point = CGPoint.zero
                        if AXValueGetValue(posValue as! AXValue, .cgPoint, &point) {
                            return NSPoint(x: point.x, y: point.y)
                        }
                    }
                }
            }
        }
        
        // Fallback to mouse location
        return NSEvent.mouseLocation
    }
}

extension CGEvent {
    func getStringValue() -> String? {
        var length = 0
        self.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        
        guard length > 0 else { return nil }
        
        var buffer = [UniChar](repeating: 0, count: length)
        self.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: nil, unicodeString: &buffer)
        
        return String(utf16CodeUnits: buffer, count: length)
    }
}