import XCTest
@testable import PostPique

/// Basic tests that should reliably pass
/// Add this file to your PostPiqueTests target in Xcode
class BasicPostPiqueTests: XCTestCase {
    
    // MARK: - Simple Model Tests
    
    func testPostContentBasics() {
        let postContent = PostContent(
            quotation: "Test quotation",
            pageTitle: "Test Article",
            thoughts: "Test thoughts",
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        XCTAssertEqual(postContent.quotation, "Test quotation")
        XCTAssertEqual(postContent.pageTitle, "Test Article")
        XCTAssertEqual(postContent.thoughts, "Test thoughts")
        XCTAssertEqual(postContent.sourceURL, "https://example.com")
        XCTAssertEqual(postContent.truncatedTitle, "Test Article")
    }
    
    func testPostContentTitleTruncation() {
        let postContent = PostContent(
            quotation: "Test",
            pageTitle: "Article Title - Site Name",
            thoughts: "Test",
            timestamp: Date(),
            sourceURL: nil
        )
        
        XCTAssertEqual(postContent.truncatedTitle, "Article Title")
    }
    
    func testPostContentMarkdownContainsExpectedContent() {
        let postContent = PostContent(
            quotation: "This is a test quote.",
            pageTitle: "Test Article",
            thoughts: "These are my thoughts.",
            timestamp: Date(),
            sourceURL: "https://example.com"
        )
        
        let markdown = postContent.markdownContent
        
        XCTAssertTrue(markdown.contains("Test Article"))
        XCTAssertTrue(markdown.contains("These are my thoughts."))
        XCTAssertTrue(markdown.contains("This is a test quote."))
        XCTAssertTrue(markdown.contains("https://example.com"))
    }
    
    func testPostContentFilenameFormat() {
        let date = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let postContent = PostContent(
            quotation: "Test",
            pageTitle: "Test Article",
            thoughts: "Test",
            timestamp: date,
            sourceURL: nil
        )
        
        let filename = postContent.filename
        XCTAssertTrue(filename.hasPrefix("2022-01-01-"))
        XCTAssertTrue(filename.hasSuffix(".md"))
    }
    
    // MARK: - Error Tests
    
    func testPostPiqueErrorEquality() {
        XCTAssertEqual(PostPiqueError.noAccessToken, PostPiqueError.noAccessToken)
        XCTAssertEqual(PostPiqueError.invalidURL, PostPiqueError.invalidURL)
        XCTAssertEqual(PostPiqueError.decodingError, PostPiqueError.decodingError)
        XCTAssertEqual(PostPiqueError.requestFailed("test"), PostPiqueError.requestFailed("test"))
        
        XCTAssertNotEqual(PostPiqueError.noAccessToken, PostPiqueError.invalidURL)
        XCTAssertNotEqual(PostPiqueError.requestFailed("test1"), PostPiqueError.requestFailed("test2"))
    }
    
    func testPostPiqueErrorDescriptions() {
        XCTAssertEqual(PostPiqueError.noAccessToken.errorDescription, "Please sign in again")
        XCTAssertEqual(PostPiqueError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(PostPiqueError.decodingError.errorDescription, "Failed to decode response")
        XCTAssertEqual(PostPiqueError.requestFailed("Test error").errorDescription, "Test error")
    }
    
    // MARK: - JSON Decoding Tests
    
    func testGitHubUserDecoding() throws {
        let json = """
        {
            "id": 12345,
            "login": "testuser",
            "avatar_url": "https://avatars.githubusercontent.com/u/12345",
            "name": "Test User",
            "email": "test@example.com"
        }
        """.data(using: .utf8)!
        
        let user = try JSONDecoder().decode(GitHubUser.self, from: json)
        
        XCTAssertEqual(user.id, 12345)
        XCTAssertEqual(user.login, "testuser")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
    }
    
    func testGitHubRepositoryDecoding() throws {
        let json = """
        {
            "id": 98765,
            "name": "test-repo",
            "full_name": "testuser/test-repo",
            "owner": {
                "login": "testuser",
                "avatar_url": "https://avatars.githubusercontent.com/u/12345"
            },
            "default_branch": "main",
            "html_url": "https://github.com/testuser/test-repo",
            "private": false
        }
        """.data(using: .utf8)!
        
        let repo = try JSONDecoder().decode(GitHubRepository.self, from: json)
        
        XCTAssertEqual(repo.id, 98765)
        XCTAssertEqual(repo.name, "test-repo")
        XCTAssertEqual(repo.fullName, "testuser/test-repo")
        XCTAssertEqual(repo.owner.login, "testuser")
        XCTAssertFalse(repo.isPrivate)
    }
}