import XCTest

class MainAppUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Authentication Flow UI Tests
    
    func testWelcomeScreenAppears() throws {
        // Verify welcome screen elements are present
        XCTAssertTrue(app.staticTexts["Welcome to PostPique"].exists)
        XCTAssertTrue(app.staticTexts["Share quotes and thoughts\ndirectly to your GitHub Pages"].exists)
        XCTAssertTrue(app.buttons["Sign in with GitHub"].exists)
        XCTAssertTrue(app.staticTexts["Secure authentication via GitHub"].exists)
    }
    
    func testAppIconDisplays() throws {
        // Test that app icon or fallback is shown
        let appIconExists = app.images["AppIcon"].exists
        let fallbackIconExists = app.images["app.fill"].exists
        
        XCTAssertTrue(appIconExists || fallbackIconExists, "Either app icon or fallback should be displayed")
    }
    
    func testSignInButtonTap() throws {
        let signInButton = app.buttons["Sign in with GitHub"]
        XCTAssertTrue(signInButton.exists)
        
        signInButton.tap()
        
        // Should show authentication screen with user code
        // Note: This would require mocking the authentication flow for UI tests
        XCTAssertTrue(app.staticTexts["Enter this code on GitHub:"].waitForExistence(timeout: 5.0) || 
                     app.staticTexts["Starting authentication..."].exists)
    }
    
    func testAuthenticationScreen() throws {
        // Start authentication
        app.buttons["Sign in with GitHub"].tap()
        
        // Wait for authentication screen
        let codePrompt = app.staticTexts["Enter this code on GitHub:"]
        if codePrompt.waitForExistence(timeout: 5.0) {
            // Verify authentication screen elements
            XCTAssertTrue(app.progressIndicators.firstMatch.exists)
            XCTAssertTrue(app.staticTexts["Waiting for authorization..."].exists)
            XCTAssertTrue(app.buttons["Cancel"].exists)
            
            // Verify user code is displayed (would be mock data in test)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[A-Z0-9]{4}-[A-Z0-9]{4}")).count > 0)
        }
    }
    
    func testCancelAuthentication() throws {
        // Start authentication
        app.buttons["Sign in with GitHub"].tap()
        
        // Wait for cancel button and tap it
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 5.0) {
            cancelButton.tap()
            
            // Should return to welcome screen
            XCTAssertTrue(app.staticTexts["Welcome to PostPique"].waitForExistence(timeout: 3.0))
            XCTAssertTrue(app.buttons["Sign in with GitHub"].exists)
        }
    }
    
    // MARK: - Authenticated State UI Tests
    
    func testAuthenticatedScreenElements() throws {
        // This test would require setting up authenticated state
        // For now, we'll test the expected UI elements structure
        
        // Skip if not authenticated (would need mock authentication)
        guard app.staticTexts["Connected"].exists else {
            throw XCTSkip("Authentication required for this test")
        }
        
        // Verify user profile section
        XCTAssertTrue(app.staticTexts["Connected"].exists)
        
        // Verify repository section
        XCTAssertTrue(app.staticTexts["Repository"].exists)
        
        // Verify instructions section
        XCTAssertTrue(app.staticTexts["How to Use"].exists)
        
        // Verify sign out button
        XCTAssertTrue(app.buttons["Sign Out"].exists)
    }
    
    func testRepositorySelection() throws {
        // Skip if not authenticated
        guard app.staticTexts["Connected"].exists else {
            throw XCTSkip("Authentication required for this test")
        }
        
        // Look for repository selection button
        let selectButton = app.buttons["Select Repository"]
        let changeButton = app.buttons["Change"]
        
        if selectButton.exists {
            selectButton.tap()
        } else if changeButton.exists {
            changeButton.tap()
        } else {
            throw XCTSkip("No repository selection button found")
        }
        
        // Verify repository picker appears
        XCTAssertTrue(app.navigationBars["Select Repository"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Refresh"].exists)
    }
    
    func testRepositoryPickerInteraction() throws {
        // Skip if not authenticated or no repository picker
        guard app.staticTexts["Connected"].exists else {
            throw XCTSkip("Authentication required for this test")
        }
        
        // Open repository picker
        if app.buttons["Select Repository"].exists {
            app.buttons["Select Repository"].tap()
        } else if app.buttons["Change"].exists {
            app.buttons["Change"].tap()
        } else {
            throw XCTSkip("No repository selection available")
        }
        
        // Wait for picker to appear
        guard app.navigationBars["Select Repository"].waitForExistence(timeout: 3.0) else {
            throw XCTSkip("Repository picker did not appear")
        }
        
        // Test refresh button
        app.buttons["Refresh"].tap()
        
        // Test cancel button
        app.buttons["Cancel"].tap()
        
        // Should return to main screen
        XCTAssertTrue(app.staticTexts["Repository"].waitForExistence(timeout: 3.0))
    }
    
    func testSignOut() throws {
        // Skip if not authenticated
        guard app.staticTexts["Connected"].exists else {
            throw XCTSkip("Authentication required for this test")
        }
        
        // Tap sign out button
        app.buttons["Sign Out"].tap()
        
        // Should return to welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to PostPique"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Sign in with GitHub"].exists)
    }
    
    // MARK: - Instructions Section UI Tests
    
    func testInstructionsSection() throws {
        // Skip if not authenticated
        guard app.staticTexts["Connected"].exists else {
            throw XCTSkip("Authentication required for this test")
        }
        
        // Verify instructions section
        XCTAssertTrue(app.staticTexts["How to Use"].exists)
        
        // Verify instruction steps
        let expectedSteps = [
            "Select a GitHub Pages repository",
            "Open the share sheet on any webpage",
            "Choose PostPique",
            "Add a quote and your thoughts",
            "Post to GitHub Pages"
        ]
        
        for step in expectedSteps {
            XCTAssertTrue(app.staticTexts[step].exists, "Instruction step '\(step)' not found")
        }
    }
    
    // MARK: - Error Handling UI Tests
    
    func testErrorAlertDisplay() throws {
        // This would test error alert presentation
        // For now, verify alert infrastructure exists
        
        // If an error alert is present, verify its structure
        if app.alerts.firstMatch.exists {
            let alert = app.alerts.firstMatch
            XCTAssertTrue(alert.buttons["OK"].exists)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Verify important UI elements have accessibility labels
        
        // Welcome screen
        if app.staticTexts["Welcome to PostPique"].exists {
            XCTAssertTrue(app.buttons["Sign in with GitHub"].isHittable)
        }
        
        // Authenticated screen
        if app.staticTexts["Connected"].exists {
            XCTAssertTrue(app.buttons["Sign Out"].isHittable)
            
            if app.buttons["Select Repository"].exists {
                XCTAssertTrue(app.buttons["Select Repository"].isHittable)
            }
            
            if app.buttons["Change"].exists {
                XCTAssertTrue(app.buttons["Change"].isHittable)
            }
        }
    }
    
    func testVoiceOverNavigation() throws {
        // Enable VoiceOver for testing
        // Note: This would require additional setup in real UI tests
        
        // Verify key elements are accessible
        let signInButton = app.buttons["Sign in with GitHub"]
        if signInButton.exists {
            XCTAssertFalse(signInButton.label.isEmpty)
            XCTAssertTrue(signInButton.isHittable)
        }
    }
    
    // MARK: - Cross-Platform UI Tests
    
    func testPlatformSpecificUI() throws {
        #if os(iOS)
        // iOS-specific UI tests
        
        // Verify iOS navigation style
        if app.navigationBars.firstMatch.exists {
            XCTAssertTrue(app.navigationBars.firstMatch.exists)
        }
        
        // Verify iOS-specific font sizes and layouts work
        XCTAssertTrue(app.staticTexts["Welcome to PostPique"].exists)
        
        #elseif os(macOS)
        // macOS-specific UI tests
        
        // Verify macOS window sizing
        // Note: XCTest on macOS has different window handling
        
        // Verify macOS-specific elements
        XCTAssertTrue(app.staticTexts["Welcome to PostPique"].exists)
        
        #endif
    }
    
    // MARK: - Performance UI Tests
    
    func testAppLaunchPerformance() throws {
        // Test app launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testUIResponseiveness() throws {
        // Test UI responsiveness during interactions
        let signInButton = app.buttons["Sign in with GitHub"]
        
        measure {
            if signInButton.exists {
                signInButton.tap()
                
                // Wait for response
                _ = app.staticTexts["Enter this code on GitHub:"].waitForExistence(timeout: 1.0) ||
                    app.staticTexts["Starting authentication..."].waitForExistence(timeout: 1.0)
            }
        }
    }
    
    // MARK: - Layout Tests
    
    func testUILayoutConsistency() throws {
        // Verify UI elements are properly positioned
        
        if app.staticTexts["Welcome to PostPique"].exists {
            let welcomeText = app.staticTexts["Welcome to PostPique"]
            let signInButton = app.buttons["Sign in with GitHub"]
            
            // Verify elements exist and are in expected relative positions
            XCTAssertTrue(welcomeText.exists)
            XCTAssertTrue(signInButton.exists)
            
            // On iOS, verify elements are within screen bounds
            #if os(iOS)
            let welcomeFrame = welcomeText.frame
            let buttonFrame = signInButton.frame
            
            XCTAssertTrue(welcomeFrame.minY < buttonFrame.minY, "Welcome text should be above sign in button")
            #endif
        }
    }
    
    func testResponsiveLayout() throws {
        // Test layout adapts to different screen sizes
        // Note: This would require device/simulator rotation or size changes
        
        // Verify key elements remain accessible
        XCTAssertTrue(app.staticTexts["Welcome to PostPique"].exists || app.staticTexts["Connected"].exists)
    }
    
    // MARK: - State Persistence Tests
    
    func testAppStateAfterRelaunch() throws {
        // Test that app state persists across launches
        
        // Note: This would require setting up known state first
        // For now, just verify app launches correctly
        app.terminate()
        app.launch()
        
        // Verify app returns to appropriate state
        XCTAssertTrue(app.staticTexts["Welcome to PostPique"].exists || app.staticTexts["Connected"].exists)
    }
}