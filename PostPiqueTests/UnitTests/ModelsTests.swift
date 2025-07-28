import XCTest
@testable import PostPique

class ModelsTests: XCTestCase {
    
    // MARK: - PostContent Tests
    
    func testPostContentTruncatedTitle() {
        // Test truncation at first non-alphanumeric character
        let postContent = PostContent(
            quotation: "Test quote",
            pageTitle: "Article Title - Site Name",
            thoughts: "Test thoughts",
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        XCTAssertEqual(postContent.truncatedTitle, "Article Title")
    }
    
    func testPostContentTruncatedTitleWithHyphen() {
        let postContent = PostContent(
            quotation: "Test quote",
            pageTitle: "Breaking News – Important Update",
            thoughts: "Test thoughts",
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        XCTAssertEqual(postContent.truncatedTitle, "Breaking News")
    }
    
    func testPostContentTruncatedTitleNoSpecialChars() {
        let postContent = PostContent(
            quotation: "Test quote",
            pageTitle: "Simple Title",
            thoughts: "Test thoughts",
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        XCTAssertEqual(postContent.truncatedTitle, "Simple Title")
    }
    
    func testPostContentTruncatedTitleWithNumbers() {
        let postContent = PostContent(
            quotation: "Test quote",
            pageTitle: "Article 123 Title - Site",
            thoughts: "Test thoughts",
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        XCTAssertEqual(postContent.truncatedTitle, "Article 123 Title")
    }
    
    func testPostContentMarkdownContent() {
        let postContent = PostContent(
            quotation: "This is a test quotation.",
            pageTitle: "Test Article",
            thoughts: "These are my thoughts.",
            timestamp: Date(),
            sourceURL: "https://example.com/article"
        )
        
        let markdown = postContent.markdownContent
        
        XCTAssertTrue(markdown.contains("title: \"🔗 Test Article\""))
        XCTAssertTrue(markdown.contains("These are my thoughts."))
        XCTAssertTrue(markdown.contains("> This is a test quotation."))
        XCTAssertTrue(markdown.contains("[Full article](https://example.com/article)"))
    }
    
    func testPostContentMarkdownContentWithoutURL() {
        let postContent = PostContent(
            quotation: "Test quotation",
            pageTitle: "Test Article",
            thoughts: "Test thoughts",
            timestamp: Date(),
            sourceURL: nil
        )
        
        let markdown = postContent.markdownContent
        
        XCTAssertFalse(markdown.contains("[Full article]"))
    }
    
    func testPostContentMarkdownContentWithQuotes() {
        let postContent = PostContent(
            quotation: "Quote with \"nested quotes\"",
            pageTitle: "Article with \"quotes\"",
            thoughts: "Thoughts about quotes",
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        let markdown = postContent.markdownContent
        
        XCTAssertTrue(markdown.contains("title: \"🔗 Article with \\\"quotes\\\"\""))
    }
    
    func testPostContentFilename() {
        let date = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let postContent = PostContent(
            quotation: "Test quote",
            pageTitle: "Test Article - Site Name",
            thoughts: "Test thoughts",
            timestamp: date,
            sourceURL: "https://example.com"
        )
        
        let filename = postContent.filename
        
        XCTAssertTrue(filename.hasPrefix("2022-01-01-"))
        XCTAssertTrue(filename.contains("test-article"))
        XCTAssertTrue(filename.hasSuffix(".md"))
    }
    
    func testPostContentFilenameWithSpecialCharacters() {
        let date = Date(timeIntervalSince1970: 1640995200)
        let postContent = PostContent(
            quotation: "Test quote",
            pageTitle: "Article with @#$% Special! Characters",
            thoughts: "Test thoughts",
            timestamp: date,
            sourceURL: "https://example.com"
        )
        
        let filename = postContent.filename
        
        // Special characters should be removed
        XCTAssertFalse(filename.contains("@"))
        XCTAssertFalse(filename.contains("#"))
        XCTAssertFalse(filename.contains("$"))
        XCTAssertFalse(filename.contains("%"))
        XCTAssertFalse(filename.contains("!"))
        XCTAssertTrue(filename.contains("article-with-special-characters"))
    }
    
    func testPostContentFilenameLengthLimit() {
        let date = Date(timeIntervalSince1970: 1640995200)
        let longTitle = String(repeating: "very long title ", count: 10)
        let postContent = PostContent(
            quotation: "Test quote",
            pageTitle: longTitle,
            thoughts: "Test thoughts",
            timestamp: date,
            sourceURL: "https://example.com"
        )
        
        let filename = postContent.filename
        let titlePart = filename.dropFirst(11).dropLast(3) // Remove date and .md
        
        XCTAssertTrue(titlePart.count <= 50)
    }
    
    // MARK: - GitHubUser Tests
    
    func testGitHubUserDecoding() throws {
        let json = MockData.mockUserJSON
        let user = try JSONDecoder().decode(GitHubUser.self, from: json)
        
        XCTAssertEqual(user.id, 12345)
        XCTAssertEqual(user.login, "testuser")
        XCTAssertEqual(user.avatarUrl, "https://avatars.githubusercontent.com/u/12345?v=4")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
    }
    
    func testGitHubUserWithNilValues() throws {
        let jsonString = """
        {
            "id": 12345,
            "login": "testuser",
            "avatar_url": "https://avatars.githubusercontent.com/u/12345?v=4",
            "name": null,
            "email": null
        }
        """
        let json = jsonString.data(using: .utf8)!
        let user = try JSONDecoder().decode(GitHubUser.self, from: json)
        
        XCTAssertEqual(user.id, 12345)
        XCTAssertEqual(user.login, "testuser")
        XCTAssertNil(user.name)
        XCTAssertNil(user.email)
    }
    
    // MARK: - GitHubRepository Tests
    
    func testGitHubRepositoryDecoding() throws {
        let json = MockData.mockRepositoriesJSON
        let repositories = try JSONDecoder().decode([GitHubRepository].self, from: json)
        
        XCTAssertEqual(repositories.count, 1)
        let repo = repositories[0]
        
        XCTAssertEqual(repo.id, 98765)
        XCTAssertEqual(repo.name, "test-repo")
        XCTAssertEqual(repo.fullName, "testuser/test-repo")
        XCTAssertEqual(repo.owner.login, "testuser")
        XCTAssertEqual(repo.defaultBranch, "main")
        XCTAssertEqual(repo.htmlUrl, "https://github.com/testuser/test-repo")
        XCTAssertFalse(repo.isPrivate)
    }
    
    func testGitHubRepositoryPrivate() {
        let repo = MockData.mockPrivateRepository
        XCTAssertTrue(repo.isPrivate)
    }
    
    // MARK: - DeviceCodeResponse Tests
    
    func testDeviceCodeResponseDecoding() throws {
        let json = MockData.mockDeviceCodeJSON
        let response = try JSONDecoder().decode(DeviceCodeResponse.self, from: json)
        
        XCTAssertEqual(response.deviceCode, "device_code_123")
        XCTAssertEqual(response.userCode, "ABCD-1234")
        XCTAssertEqual(response.verificationURI, "https://github.com/login/device")
        XCTAssertEqual(response.verificationURIComplete, "https://github.com/login/device/continue")
        XCTAssertEqual(response.expiresIn, 900)
        XCTAssertEqual(response.interval, 5)
    }
    
    // MARK: - PostPiqueError Tests
    
    func testPostPiqueErrorDescriptions() {
        XCTAssertEqual(PostPiqueError.noAccessToken.errorDescription, "Please sign in again")
        XCTAssertEqual(PostPiqueError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(PostPiqueError.requestFailed("Test error").errorDescription, "Test error")
        XCTAssertEqual(PostPiqueError.decodingError.errorDescription, "Failed to decode response")
        XCTAssertEqual(PostPiqueError.keychainError("Keychain fail").errorDescription, "Keychain fail")
        XCTAssertEqual(PostPiqueError.authenticationFailed("Auth fail").errorDescription, "Auth fail")
    }
}