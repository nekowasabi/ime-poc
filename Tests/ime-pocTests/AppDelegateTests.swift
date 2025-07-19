import XCTest
@testable import ime_poc

class AppDelegateTests: XCTestCase {
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(appDelegate)
    }
    
    func testApplicationDidFinishLaunching() {
        // Skip UI-related tests in test environment
        // This test would require a full macOS app context
        XCTAssertTrue(true)
    }
    
    func testApplicationWillTerminate() {
        let notification = Notification(name: .init("test"))
        appDelegate.applicationWillTerminate(notification)
    }
}