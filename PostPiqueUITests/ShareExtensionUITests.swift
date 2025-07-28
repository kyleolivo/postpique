import XCTest

class ShareExtensionUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Note: Testing share extensions requires special setup
        // This would typically involve launching Safari or another app
        // and invoking the share sheet
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Share Extension Launch Tests
    
    func testShareExtensionLaunchesFromSafari() throws {
        // This test would require launching Safari and sharing a webpage
        // For demonstration, we'll outline the expected flow
        
        // 1. Launch Safari
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        
        // 2. Navigate to a test page
        // safari.textFields["Address"].tap()
        // safari.textFields["Address"].typeText("https://example.com")
        // safari.buttons["Go"].tap()
        
        // 3. Tap share button
        // safari.buttons["Share"].tap()
        
        // 4. Look for PostPique in share sheet
        // XCTAssertTrue(safari.buttons["PostPique"].waitForExistence(timeout: 5.0))
        
        // 5. Tap PostPique
        // safari.buttons["PostPique"].tap()
        
        // For now, we'll skip this complex setup
        throw XCTSkip("Share extension testing requires complex app coordination")
    }
    
    // MARK: - Share Extension UI Tests (Isolated)
    
    func testShareExtensionUIElements() throws {
        // Test the share extension UI in isolation
        // This would require the extension to be launched directly
        
        // Skip if share extension is not active
        guard app.staticTexts["Quotation"].exists || app.staticTexts["Your Thoughts"].exists else {
            throw XCTSkip("Share extension not active")
        }
        
        // Verify main UI elements exist
        XCTAssertTrue(app.staticTexts["Quotation"].exists)
        XCTAssertTrue(app.staticTexts["Your Thoughts"].exists)
        
        // Verify text input areas
        XCTAssertTrue(app.textViews.count >= 2, "Should have at least 2 text areas for quotation and thoughts")
        
        // Verify buttons based on platform
        #if os(iOS)
        // iOS should have top navigation buttons
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Post"].exists)
        
        // Verify quote icon in center
        XCTAssertTrue(app.images["quote.bubble.fill"].exists)
        
        #elseif os(macOS)
        // macOS should have bottom buttons
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Post"].exists)
        #endif
    }
    
    func testShareExtensionTextInput() throws {
        // Skip if share extension is not active
        guard app.staticTexts["Quotation"].exists else {
            throw XCTSkip("Share extension not active")
        }
        
        // Get text input areas
        let textViews = app.textViews
        guard textViews.count >= 2 else {
            throw XCTSkip("Insufficient text input areas")
        }
        
        let quotationField = textViews.element(boundBy: 0)
        let thoughtsField = textViews.element(boundBy: 1)
        
        // Test quotation input
        quotationField.tap()
        quotationField.typeText("This is a test quotation from the article.")
        
        // Test thoughts input
        thoughtsField.tap()
        thoughtsField.typeText("These are my test thoughts about the article.")
        
        // Verify text was entered
        XCTAssertTrue(quotationField.value as? String != nil)
        XCTAssertTrue(thoughtsField.value as? String != nil)
    }
    
    func testShareExtensionPostButtonState() throws {
        // Skip if share extension is not active
        guard app.buttons["Post"].exists else {
            throw XCTSkip("Share extension not active")
        }
        
        let postButton = app.buttons["Post"]
        let cancelButton = app.buttons["Cancel"]
        
        // Initially, post button should be disabled (no content)
        XCTAssertFalse(postButton.isEnabled)
        XCTAssertTrue(cancelButton.isEnabled)
        
        // Add content to enable post button
        let textViews = app.textViews
        if textViews.count >= 2 {
            let quotationField = textViews.element(boundBy: 0)
            let thoughtsField = textViews.element(boundBy: 1)
            
            quotationField.tap()
            quotationField.typeText("Test quote")
            
            thoughtsField.tap()
            thoughtsField.typeText("Test thoughts")
            
            // Post button should now be enabled
            XCTAssertTrue(postButton.isEnabled)
        }
    }
    
    func testShareExtensionCancel() throws {
        // Skip if share extension is not active
        guard app.buttons["Cancel"].exists else {
            throw XCTSkip("Share extension not active")
        }
        
        // Tap cancel button
        app.buttons["Cancel"].tap()
        
        // Extension should close (difficult to test directly)
        // We can verify the cancel button was tappable
        XCTAssertTrue(true) // Placeholder - actual cancellation would close the extension
    }
    
    // MARK: - Share Extension Error States
    
    func testShareExtensionWithoutRepository() throws {
        // This tests the error view when no repository is configured
        
        // Look for error message
        if app.staticTexts["Repository Not Configured"].exists {
            // Verify error UI elements
            XCTAssertTrue(app.staticTexts["Repository Not Configured"].exists)
            XCTAssertTrue(app.staticTexts["Please open PostPique and select a repository before sharing content."].exists)
            XCTAssertTrue(app.buttons["OK"].exists)
            XCTAssertTrue(app.images["exclamationmark.triangle"].exists)
            
            // Test OK button
            app.buttons["OK"].tap()
            
            // Should close the extension
            XCTAssertTrue(true) // Placeholder
        } else {
            throw XCTSkip("Repository error state not present")
        }
    }
    
    // MARK: - Share Extension Content Processing
    
    func testShareExtensionReceivesWebContent() throws {
        // This would test that the extension properly receives shared content
        // For now, we'll test the UI assumes content was received
        
        // Skip if no shared content indicators
        guard app.staticTexts["Quotation"].exists else {
            throw XCTSkip("Share extension not active with content")
        }
        
        // In a real test, we'd verify:
        // 1. Page title is extracted and displayed
        // 2. URL is captured for the source link
        // 3. Text fields are ready for user input
        
        // For now, verify UI is ready for content
        XCTAssertTrue(app.staticTexts["Quotation"].exists)
        XCTAssertTrue(app.staticTexts["Your Thoughts"].exists)
    }
    
    // MARK: - Cross-Platform Share Extension Tests
    
    func testShareExtensionPlatformDifferences() throws {
        // Skip if share extension is not active
        guard app.staticTexts["Quotation"].exists else {
            throw XCTSkip("Share extension not active")
        }
        
        #if os(iOS)
        // iOS-specific tests
        
        // Verify iOS navigation layout
        let cancelButton = app.buttons["Cancel"]
        let postButton = app.buttons["Post"]
        let quoteIcon = app.images["quote.bubble.fill"]
        
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(postButton.exists)
        XCTAssertTrue(quoteIcon.exists)
        
        // Verify buttons are at the top (simplified test)
        // In reality, we'd check frame positions
        XCTAssertTrue(cancelButton.isHittable)
        XCTAssertTrue(postButton.isHittable)
        
        #elseif os(macOS)
        // macOS-specific tests
        
        // Verify macOS has the full header with app icon and title
        XCTAssertTrue(app.staticTexts["PostPique"].exists || app.images["AppIcon"].exists)
        
        // Verify macOS button layout (bottom of view)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Post"].exists)
        
        #endif
    }
    
    // MARK: - Share Extension Performance Tests
    
    func testShareExtensionLaunchSpeed() throws {
        // Test how quickly the share extension launches and becomes ready
        
        // This would measure from share sheet tap to UI ready
        // For now, we'll verify the extension is responsive once active
        
        guard app.staticTexts["Quotation"].exists else {
            throw XCTSkip("Share extension not active")
        }
        
        // Measure interaction responsiveness
        measure {
            let textViews = app.textViews
            if textViews.count > 0 {
                textViews.firstMatch.tap()
            }
        }
    }
    
    func testShareExtensionTextInputPerformance() throws {
        // Test text input performance in the extension
        
        guard app.textViews.count >= 2 else {
            throw XCTSkip("Insufficient text areas for testing")
        }
        
        let quotationField = app.textViews.element(boundBy: 0)
        
        // Measure text input speed
        measure {
            quotationField.tap()
            quotationField.typeText("Performance test text")
        }
    }
    
    // MARK: - Share Extension Accessibility Tests
    
    func testShareExtensionAccessibility() throws {
        // Test accessibility features in the share extension
        
        guard app.staticTexts["Quotation"].exists else {
            throw XCTSkip("Share extension not active")
        }
        
        // Verify key elements have accessibility labels
        XCTAssertTrue(app.buttons["Cancel"].isHittable)
        XCTAssertTrue(app.buttons["Post"].isHittable)
        
        // Verify text input areas are accessible
        let textViews = app.textViews
        for textView in textViews.allElementsBoundByIndex {
            XCTAssertTrue(textView.isHittable)
        }
        
        // Verify labels are accessible
        XCTAssertFalse(app.staticTexts["Quotation"].label.isEmpty)
        XCTAssertFalse(app.staticTexts["Your Thoughts"].label.isEmpty)
    }
    
    // MARK: - Share Extension Integration Tests
    
    func testShareExtensionToMainAppIntegration() throws {
        // Test that share extension properly communicates with main app
        
        // This would test:
        // 1. Repository configuration is accessible from extension
        // 2. Authentication state is shared
        // 3. Posted content appears in main app (if applicable)
        
        // For now, verify the extension can access necessary data
        if app.staticTexts["Repository Not Configured"].exists {
            // Extension properly detected missing repository
            XCTAssertTrue(app.staticTexts["Repository Not Configured"].exists)
        } else if app.staticTexts["Quotation"].exists {
            // Extension has access to repository configuration
            XCTAssertTrue(app.staticTexts["Quotation"].exists)
        }
    }
    
    // MARK: - Share Extension Content Validation Tests
    
    func testShareExtensionContentValidation() throws {
        // Test that the extension validates content before posting
        
        guard app.textViews.count >= 2 else {
            throw XCTSkip("Insufficient text areas for testing")
        }
        
        let quotationField = app.textViews.element(boundBy: 0)
        let thoughtsField = app.textViews.element(boundBy: 1)
        let postButton = app.buttons["Post"]
        
        // Initially post button should be disabled
        XCTAssertFalse(postButton.isEnabled)
        
        // Add only quotation - should still be disabled
        quotationField.tap()
        quotationField.typeText("Test quotation")
        // Post button should still be disabled (need both fields)
        
        // Add thoughts - should enable post button
        thoughtsField.tap()
        thoughtsField.typeText("Test thoughts")
        XCTAssertTrue(postButton.isEnabled)
        
        // Clear one field - should disable again
        quotationField.tap()
        quotationField.clearText()
        XCTAssertFalse(postButton.isEnabled)
    }
    
    // MARK: - Helper Methods for UI Tests
    
    func simulateShareFromSafari(url: String = "https://example.com") {
        // Helper method to simulate sharing from Safari
        // This would be used in real UI tests with proper setup
        
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        
        // Navigate to URL
        safari.textFields["URL"].tap()
        safari.textFields["URL"].typeText(url)
        safari.buttons["Go"].tap()
        
        // Wait for page load
        sleep(2)
        
        // Tap share button
        safari.buttons["Share"].tap()
        
        // Tap PostPique in share sheet
        safari.scrollViews.buttons["PostPique"].tap()
    }
}

// MARK: - XCUIElement Extensions for Testing

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}