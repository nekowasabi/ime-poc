import XCTest
@testable import ime_poc

class InputMonitorTests: XCTestCase {
    var inputMonitor: InputMonitor!
    var mockDelegate: MockInputMonitorDelegate!
    
    override func setUp() {
        super.setUp()
        inputMonitor = InputMonitor()
        mockDelegate = MockInputMonitorDelegate()
        inputMonitor.delegate = mockDelegate
    }
    
    override func tearDown() {
        inputMonitor.stop()
        inputMonitor = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(inputMonitor)
        XCTAssertNotNil(inputMonitor.delegate)
    }
    
    func testStartAndStop() {
        inputMonitor.start()
        inputMonitor.stop()
    }
    
    func testDelegateAssignment() {
        XCTAssertTrue(inputMonitor.delegate === mockDelegate)
    }
}

class MockInputMonitorDelegate: InputMonitorDelegate {
    var detectedText: String?
    var detectedPoint: NSPoint?
    var didDetectInputCalled = false
    var didDetectClearCalled = false
    
    func inputMonitor(_ monitor: InputMonitor, didDetectInput text: String, at point: NSPoint) {
        detectedText = text
        detectedPoint = point
        didDetectInputCalled = true
    }
    
    func inputMonitorDidDetectClear(_ monitor: InputMonitor) {
        didDetectClearCalled = true
    }
}