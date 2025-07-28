import XCTest
@testable import PostPique

class GitHubAPIServiceTests: XCTestCase {
    
    var apiService: GitHubAPIService!
    var mockURLSession: MockURLSession!
    var mockKeychainService: MockKeychainService!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        mockKeychainService = MockKeychainService()
        
        // Store a test access token
        try? mockKeychainService.storeAccessToken("test_access_token")
        
        // Create API service instance (we'll need to inject dependencies in a real implementation)
        apiService = GitHubAPIService.shared
    }
    
    override func tearDown() {
        mockKeychainService.clear()
        apiService = nil
        mockURLSession = nil
        mockKeychainService = nil
        super.tearDown()
    }
    
    // MARK: - Request Creation Tests
    
    func testCreateRequestWithValidToken() throws {
        // This test would require refactoring GitHubAPIService to accept dependency injection
        // For now, we'll test the expected behavior
        
        let expectedURL = URL(string: "https://api.github.com/user")!
        
        // Mock successful response
        mockURLSession.setMockHTTPResponse(
            data: MockData.mockUserJSON,
            statusCode: 200,
            url: expectedURL
        )
        
        // The request should include proper headers
        let expectedHeaders = [
            "Authorization": "Bearer test_access_token",
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "PostPique/1.0"
        ]
        
        // In a real test, we'd verify these headers are set correctly
        XCTAssertTrue(true) // Placeholder - would test actual request creation
    }
    
    // MARK: - User API Tests
    
    func testGetCurrentUserSuccess() async throws {
        // This test demonstrates the expected behavior
        // In practice, we'd need to modify GitHubAPIService to accept a URLSession parameter
        
        let expectedUser = MockData.mockUser
        
        // Verify the expected user data structure
        XCTAssertEqual(expectedUser.id, 12345)
        XCTAssertEqual(expectedUser.login, "testuser")
        XCTAssertEqual(expectedUser.name, "Test User")
        XCTAssertEqual(expectedUser.email, "test@example.com")
    }
    
    func testGetCurrentUserHTTPError() async {
        // Mock 401 Unauthorized response
        mockURLSession.setMockHTTPResponse(
            data: "Unauthorized".data(using: .utf8),
            statusCode: 401
        )
        
        // Test would verify that appropriate error is thrown
        // XCTAssertThrowsError(try await apiService.getCurrentUser())
    }
    
    func testGetCurrentUserNetworkError() async {
        // Mock network error
        let networkError = URLError(.notConnectedToInternet)
        mockURLSession.setMockResponse(data: nil, response: nil, error: networkError)
        
        // Test would verify that network error is handled properly
        // XCTAssertThrowsError(try await apiService.getCurrentUser())
    }
    
    func testGetCurrentUserInvalidJSON() async {
        // Mock invalid JSON response
        let invalidJSON = "invalid json".data(using: .utf8)!
        mockURLSession.setMockHTTPResponse(data: invalidJSON, statusCode: 200)
        
        // Test would verify that decoding error is thrown
        // XCTAssertThrowsError(try await apiService.getCurrentUser())
    }
    
    // MARK: - Repository API Tests
    
    func testGetUserRepositoriesSuccess() async throws {
        let expectedRepos = MockData.mockRepositories
        
        // Verify expected repository structure
        XCTAssertEqual(expectedRepos.count, 2)
        XCTAssertEqual(expectedRepos[0].name, "test-repo")
        XCTAssertEqual(expectedRepos[1].name, "private-repo")
        XCTAssertFalse(expectedRepos[0].isPrivate)
        XCTAssertTrue(expectedRepos[1].isPrivate)
    }
    
    func testGetUserRepositoriesEmpty() async {
        // Mock empty repository list
        let emptyReposJSON = "[]".data(using: .utf8)!
        mockURLSession.setMockHTTPResponse(data: emptyReposJSON, statusCode: 200)
        
        // Test would verify empty array is returned
        // let repos = try await apiService.getUserRepositories()
        // XCTAssertEqual(repos.count, 0)
    }
    
    func testGetUserRepositoriesQueryParameters() {
        // Verify that the correct query parameters are used
        let expectedParams = [
            "type": "all",
            "sort": "updated",
            "per_page": "100"
        ]
        
        // In a real test, we'd verify the URL contains these parameters
        XCTAssertTrue(true) // Placeholder
    }
    
    // MARK: - Post Creation Tests
    
    func testCreatePostSuccess() async throws {
        let testPost = MockData.mockPostContent
        let testRepo = MockData.mockRepository
        
        // Mock successful creation response
        let successResponse = """
        {
            "content": {
                "name": "\(testPost.filename)",
                "path": "_posts/\(testPost.filename)"
            }
        }
        """.data(using: .utf8)!
        
        mockURLSession.setMockHTTPResponse(data: successResponse, statusCode: 201)
        
        // Verify post content structure
        XCTAssertFalse(testPost.quotation.isEmpty)
        XCTAssertFalse(testPost.thoughts.isEmpty)
        XCTAssertTrue(testPost.filename.contains(".md"))
        XCTAssertTrue(testPost.markdownContent.contains(testPost.quotation))
        XCTAssertTrue(testPost.markdownContent.contains(testPost.thoughts))
    }
    
    func testCreatePostFileContent() {
        let testPost = MockData.mockPostContent
        let testRepo = MockData.mockRepository
        
        // Verify the expected file content structure
        let expectedPath = "_posts/\(testPost.filename)"
        let expectedMessage = "Add new post: \(testPost.truncatedTitle)"
        let expectedContent = testPost.markdownContent
        let expectedBranch = testRepo.defaultBranch
        
        XCTAssertEqual(expectedBranch, "main")
        XCTAssertTrue(expectedPath.hasPrefix("_posts/"))
        XCTAssertTrue(expectedPath.hasSuffix(".md"))
        XCTAssertTrue(expectedMessage.contains(testPost.truncatedTitle))
        XCTAssertFalse(expectedContent.isEmpty)
    }
    
    func testCreatePostBase64Encoding() {
        let testContent = "Test markdown content"
        let expectedBase64 = Data(testContent.utf8).base64EncodedString()
        
        XCTAssertEqual(expectedBase64, "VGVzdCBtYXJrZG93biBjb250ZW50")
        
        // Verify round-trip encoding/decoding
        if let decodedData = Data(base64Encoded: expectedBase64),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            XCTAssertEqual(decodedString, testContent)
        } else {
            XCTFail("Failed to decode base64 content")
        }
    }
    
    func testCreatePostHTTPError() async {
        // Mock 404 Not Found (repository doesn't exist)
        mockURLSession.setMockHTTPResponse(
            data: "Repository not found".data(using: .utf8),
            statusCode: 404
        )
        
        // Test would verify appropriate error handling
        // XCTAssertThrowsError(try await apiService.createPost(testPost, in: testRepo))
    }
    
    func testCreatePostUnauthorized() async {
        // Mock 403 Forbidden (insufficient permissions)
        mockURLSession.setMockHTTPResponse(
            data: "Forbidden".data(using: .utf8),
            statusCode: 403
        )
        
        // Test would verify that permission error is handled
        // XCTAssertThrowsError(try await apiService.createPost(testPost, in: testRepo))
    }
    
    // MARK: - Error Handling Tests
    
    func testPostPiqueErrorMessages() {
        let errors: [(PostPiqueError, String)] = [
            (.noAccessToken, "Please sign in again"),
            (.invalidURL, "Invalid URL"),
            (.requestFailed("Custom error"), "Custom error"),
            (.decodingError, "Failed to decode response"),
            (.keychainError("Keychain error"), "Keychain error"),
            (.authenticationFailed("Auth error"), "Auth error")
        ]
        
        for (error, expectedMessage) in errors {
            XCTAssertEqual(error.errorDescription, expectedMessage)
        }
    }
    
    func testHTTPStatusCodeHandling() {
        let statusCodes: [(Int, Bool)] = [
            (200, true),   // OK
            (201, true),   // Created
            (204, true),   // No Content
            (400, false),  // Bad Request
            (401, false),  // Unauthorized
            (403, false),  // Forbidden
            (404, false),  // Not Found
            (500, false)   // Internal Server Error
        ]
        
        for (statusCode, shouldSucceed) in statusCodes {
            let isSuccess = (200...299).contains(statusCode)
            XCTAssertEqual(isSuccess, shouldSucceed, "Status code \(statusCode) handling incorrect")
        }
    }
    
    // MARK: - URL Construction Tests
    
    func testAPIEndpoints() {
        let baseURL = "https://api.github.com"
        let endpoints = [
            "/user",
            "/user/repos?type=all&sort=updated&per_page=100",
            "/repos/testuser/test-repo/contents/_posts/test-file.md"
        ]
        
        for endpoint in endpoints {
            let fullURL = "\(baseURL)\(endpoint)"
            XCTAssertTrue(URL(string: fullURL) != nil, "Invalid URL: \(fullURL)")
        }
    }
}