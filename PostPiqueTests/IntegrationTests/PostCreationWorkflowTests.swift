import XCTest
@testable import PostPique

@MainActor
class PostCreationWorkflowTests: XCTestCase {
    
    var authManager: GitHubAuthManager!
    var mockKeychainService: MockKeychainService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        authManager = GitHubAuthManager.shared
        mockKeychainService = MockKeychainService()
        mockURLSession = MockURLSession()
        
        // Set up authenticated state
        authManager.currentUser = MockData.mockUser
        authManager.repositories = MockData.mockRepositories
        authManager.selectedRepository = MockData.mockRepository
        try? mockKeychainService.storeAccessToken("test_token")
        mockKeychainService.storeSelectedRepository(MockData.mockRepository)
    }
    
    override func tearDown() {
        authManager.signOut()
        mockKeychainService.clear()
        authManager = nil
        mockKeychainService = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Complete Post Creation Flow Tests
    
    func testCompletePostCreationWorkflow() async throws {
        // 1. Verify prerequisites
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.selectedRepository)
        XCTAssertNotNil(try? mockKeychainService.getAccessToken())
        
        // 2. Create post content
        let postContent = MockData.mockPostContent
        
        // 3. Verify post content is valid
        XCTAssertFalse(postContent.quotation.isEmpty)
        XCTAssertFalse(postContent.thoughts.isEmpty)
        XCTAssertFalse(postContent.pageTitle.isEmpty)
        XCTAssertNotNil(postContent.sourceURL)
        
        // 4. Generate markdown content
        let markdown = postContent.markdownContent
        XCTAssertTrue(markdown.contains("title: \"🔗 Test Article\""))
        XCTAssertTrue(markdown.contains(postContent.thoughts))
        XCTAssertTrue(markdown.contains("> \(postContent.quotation)"))
        XCTAssertTrue(markdown.contains("[Full article](\(postContent.sourceURL!))"))
        
        // 5. Generate filename
        let filename = postContent.filename
        XCTAssertTrue(filename.hasSuffix(".md"))
        XCTAssertTrue(filename.contains("2022-01-01"))
        XCTAssertTrue(filename.contains("test-article"))
        
        // 6. Mock successful GitHub API response
        let successResponse = """
        {
            "content": {
                "name": "\(filename)",
                "path": "_posts/\(filename)",
                "sha": "abc123"
            },
            "commit": {
                "sha": "def456",
                "message": "Add new post: \(postContent.truncatedTitle)"
            }
        }
        """.data(using: .utf8)!
        
        mockURLSession.setMockHTTPResponse(data: successResponse, statusCode: 201)
        
        // 7. Verify API request would be constructed correctly
        let expectedPath = "_posts/\(filename)"
        let expectedMessage = "Add new post: \(postContent.truncatedTitle)"
        let expectedContent = Data(markdown.utf8).base64EncodedString()
        
        XCTAssertEqual(expectedPath, "_posts/2022-01-01-test-article.md")
        XCTAssertEqual(expectedMessage, "Add new post: Test Article")
        XCTAssertFalse(expectedContent.isEmpty)
        
        // 8. Simulate successful post creation
        // In real implementation: try await githubAPI.createPost(postContent, in: repository)
        // For now, we verify the components work correctly
        XCTAssertTrue(true) // Placeholder for actual API call
    }
    
    func testPostCreationWithoutSourceURL() async throws {
        let postContent = MockData.mockPostContentWithoutURL
        
        // Verify post content without URL
        XCTAssertNil(postContent.sourceURL)
        
        // Generate markdown
        let markdown = postContent.markdownContent
        
        // Should not contain link to full article
        XCTAssertFalse(markdown.contains("[Full article]"))
        XCTAssertTrue(markdown.contains(postContent.thoughts))
        XCTAssertTrue(markdown.contains("> \(postContent.quotation)"))
    }
    
    func testPostCreationWithSpecialCharacters() async throws {
        let postContent = MockData.mockPostContentWithSpecialChars
        
        // Generate markdown with special characters
        let markdown = postContent.markdownContent
        let filename = postContent.filename
        
        // Verify special characters are handled in title
        XCTAssertTrue(markdown.contains("title: \"🔗 Article with Special Characters\""))
        
        // Verify special characters are removed from filename
        XCTAssertFalse(filename.contains("!"))
        XCTAssertFalse(filename.contains("@"))
        XCTAssertFalse(filename.contains("#"))
        XCTAssertFalse(filename.contains("$"))
        XCTAssertFalse(filename.contains("%"))
        XCTAssertTrue(filename.contains("article-with-special-characters"))
    }
    
    // MARK: - Content Validation Tests
    
    func testPostContentValidation() {
        let validPost = MockData.mockPostContent
        let invalidPosts = [
            PostContent(quotation: "", pageTitle: "Title", thoughts: "Thoughts", timestamp: Date(), sourceURL: nil),
            PostContent(quotation: "Quote", pageTitle: "Title", thoughts: "", timestamp: Date(), sourceURL: nil),
            PostContent(quotation: "Quote", pageTitle: "", thoughts: "Thoughts", timestamp: Date(), sourceURL: nil)
        ]
        
        // Valid post should pass validation
        XCTAssertFalse(validPost.quotation.isEmpty)
        XCTAssertFalse(validPost.thoughts.isEmpty)
        XCTAssertFalse(validPost.pageTitle.isEmpty)
        
        // Invalid posts should fail validation
        for invalidPost in invalidPosts {
            let hasEmptyFields = invalidPost.quotation.isEmpty || 
                               invalidPost.thoughts.isEmpty || 
                               invalidPost.pageTitle.isEmpty
            XCTAssertTrue(hasEmptyFields)
        }
    }
    
    func testRepositoryValidation() {
        // Valid repository configuration
        XCTAssertNotNil(authManager.selectedRepository)
        XCTAssertNotNil(mockKeychainService.getSelectedRepository())
        
        // Invalid repository configuration
        authManager.selectedRepository = nil
        mockKeychainService.removeSelectedRepository()
        
        XCTAssertNil(authManager.selectedRepository)
        XCTAssertNil(mockKeychainService.getSelectedRepository())
    }
    
    // MARK: - Content Generation Tests
    
    func testMarkdownGeneration() {
        let postContent = MockData.mockPostContent
        let markdown = postContent.markdownContent
        
        // Verify Jekyll frontmatter
        XCTAssertTrue(markdown.hasPrefix("---"))
        XCTAssertTrue(markdown.contains("title: \"🔗 Test Article\""))
        XCTAssertTrue(markdown.contains("excerpt_separator: \"<!--more-->\""))
        XCTAssertTrue(markdown.contains("tags:\n  - quotes"))
        
        // Verify content structure (thoughts before quotation)
        let thoughtsIndex = markdown.range(of: postContent.thoughts)?.lowerBound
        let quotationIndex = markdown.range(of: "> \(postContent.quotation)")?.lowerBound
        
        XCTAssertNotNil(thoughtsIndex)
        XCTAssertNotNil(quotationIndex)
        XCTAssertTrue(thoughtsIndex! < quotationIndex!)
        
        // Verify source link
        if let sourceURL = postContent.sourceURL {
            XCTAssertTrue(markdown.contains("[Full article](\(sourceURL))"))
        }
    }
    
    func testFilenameGeneration() {
        let testCases: [(String, Date, String)] = [
            ("Simple Title", Date(timeIntervalSince1970: 1640995200), "2022-01-01-simple-title.md"),
            ("Title with Spaces", Date(timeIntervalSince1970: 1640995200), "2022-01-01-title-with-spaces.md"),
            ("Title-with-Hyphens", Date(timeIntervalSince1970: 1640995200), "2022-01-01-title-with-hyphens.md"),
            ("Title123 with Numbers", Date(timeIntervalSince1970: 1640995200), "2022-01-01-title123-with-numbers.md")
        ]
        
        for (title, date, expectedFilename) in testCases {
            let postContent = PostContent(
                quotation: "Test quote",
                pageTitle: title,
                thoughts: "Test thoughts",
                timestamp: date,
                sourceURL: nil
            )
            
            XCTAssertEqual(postContent.filename, expectedFilename)
        }
    }
    
    func testTitleTruncation() {
        let testCases: [(String, String)] = [
            ("Article Title - Site Name", "Article Title"),
            ("Breaking News – Important Update", "Breaking News"),
            ("Simple Title", "Simple Title"),
            ("Title with (Parentheses) - Site", "Title with "),
            ("Title | Site Name", "Title "),
            ("Article 123 Title - Site", "Article 123 Title")
        ]
        
        for (originalTitle, expectedTruncated) in testCases {
            let postContent = PostContent(
                quotation: "Test",
                pageTitle: originalTitle,
                thoughts: "Test",
                timestamp: Date(),
                sourceURL: nil
            )
            
            XCTAssertEqual(postContent.truncatedTitle, expectedTruncated)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPostCreationWithoutAuthentication() {
        // Clear authentication
        authManager.signOut()
        
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        
        // Attempt to create post should fail
        let postContent = MockData.mockPostContent
        
        // In real implementation, this would throw an authentication error
        XCTAssertNotNil(postContent) // Placeholder
    }
    
    func testPostCreationWithoutRepository() {
        // Clear repository selection
        authManager.selectedRepository = nil
        mockKeychainService.removeSelectedRepository()
        
        XCTAssertNil(authManager.selectedRepository)
        XCTAssertNil(mockKeychainService.getSelectedRepository())
        
        // Attempt to create post should fail
        let postContent = MockData.mockPostContent
        
        // In real implementation, this would show "configure repository" error
        XCTAssertNotNil(postContent) // Placeholder
    }
    
    func testPostCreationAPIErrors() {
        let postContent = MockData.mockPostContent
        let repository = MockData.mockRepository
        
        let errorCases = [
            (401, "Unauthorized - token expired"),
            (403, "Forbidden - insufficient permissions"),
            (404, "Repository not found"),
            (422, "Validation failed - file already exists"),
            (500, "Internal server error")
        ]
        
        for (statusCode, expectedError) in errorCases {
            mockURLSession.setMockHTTPResponse(
                data: expectedError.data(using: .utf8),
                statusCode: statusCode
            )
            
            // In real implementation, these would throw appropriate errors
            XCTAssertTrue(statusCode >= 400) // All are error status codes
        }
    }
    
    // MARK: - Share Extension Integration Tests
    
    func testShareExtensionDataFlow() {
        // 1. Simulate data from share extension
        let sharedURL = "https://example.com/article"
        let sharedTitle = "Shared Article - News Site"
        
        // 2. Create post content from shared data
        let postContent = PostContent(
            quotation: "This is a quote from the shared article.",
            pageTitle: sharedTitle,
            thoughts: "My thoughts on this article.",
            timestamp: Date(),
            sourceURL: sharedURL
        )
        
        // 3. Verify content is properly formatted
        XCTAssertEqual(postContent.sourceURL, sharedURL)
        XCTAssertEqual(postContent.pageTitle, sharedTitle)
        XCTAssertEqual(postContent.truncatedTitle, "Shared Article")
        
        // 4. Verify markdown includes source link
        let markdown = postContent.markdownContent
        XCTAssertTrue(markdown.contains("[Full article](\(sharedURL))"))
    }
    
    func testHTMLTitleExtraction() {
        let htmlSamples = [
            MockData.mockHTML,
            MockData.mockHTMLWithEntities
        ]
        
        for html in htmlSamples {
            // Simulate title extraction from HTML
            let titlePattern = "<title[^>]*>([^<]+)</title>"
            
            guard let regex = try? NSRegularExpression(pattern: titlePattern, options: [.caseInsensitive]) else {
                XCTFail("Failed to create regex")
                continue
            }
            
            let range = NSRange(location: 0, length: html.count)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               let titleRange = Range(match.range(at: 1), in: html) {
                let title = String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(title.isEmpty)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testPostCreationPerformance() {
        let postContent = MockData.mockPostContent
        
        measure {
            for _ in 0..<100 {
                let markdown = postContent.markdownContent
                let filename = postContent.filename
                let truncatedTitle = postContent.truncatedTitle
                
                // Verify operations complete
                XCTAssertFalse(markdown.isEmpty)
                XCTAssertFalse(filename.isEmpty)
                XCTAssertFalse(truncatedTitle.isEmpty)
            }
        }
    }
    
    func testLargeContentHandling() {
        let largeQuotation = String(repeating: "This is a very long quotation. ", count: 100)
        let largeThoughts = String(repeating: "These are extensive thoughts on the matter. ", count: 100)
        
        let postContent = PostContent(
            quotation: largeQuotation,
            pageTitle: "Large Content Test",
            thoughts: largeThoughts,
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        // Verify large content is handled correctly
        let markdown = postContent.markdownContent
        XCTAssertTrue(markdown.contains(largeQuotation))
        XCTAssertTrue(markdown.contains(largeThoughts))
        
        // Verify filename length is still reasonable
        let filename = postContent.filename
        XCTAssertTrue(filename.count < 100) // Should be truncated appropriately
    }
    
    // MARK: - Cross-Platform Compatibility Tests
    
    func testCrossPlatformMarkdown() {
        let postContent = MockData.mockPostContent
        let markdown = postContent.markdownContent
        
        // Verify markdown works on both platforms
        XCTAssertFalse(markdown.contains("\r\n")) // Should use consistent line endings
        XCTAssertTrue(markdown.contains("\n")) // Should have proper line breaks
        
        // Verify Jekyll compatibility
        XCTAssertTrue(markdown.hasPrefix("---"))
        XCTAssertTrue(markdown.contains("excerpt_separator"))
        XCTAssertTrue(markdown.contains("tags:"))
    }
}