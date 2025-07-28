import Foundation
import XCTest
@testable import PostPique

/// Test configuration and utilities for PostPique test suite
struct TestConfiguration {
    
    // MARK: - Test Environment Settings
    
    static let isCI = ProcessInfo.processInfo.environment["CI"] != nil
    static let isDebugging = ProcessInfo.processInfo.environment["TEST_DEBUG"] != nil
    static let testTimeout: TimeInterval = isCI ? 30.0 : 10.0
    
    // MARK: - Test Data Configuration
    
    struct TestData {
        static let mockUserID = 12345
        static let mockUserLogin = "testuser"
        static let mockUserName = "Test User"
        static let mockUserEmail = "test@example.com"
        static let mockRepoID = 98765
        static let mockRepoName = "test-repo"
        static let mockRepoFullName = "testuser/test-repo"
        static let mockAccessToken = "test_access_token_123"
        static let mockDeviceCode = "device_code_123"
        static let mockUserCode = "ABCD-1234"
    }
    
    // MARK: - Test Utilities
    
    /// Creates a clean test environment
    static func setUp() {
        // Clear any existing keychain data
        clearTestKeychain()
        
        // Reset GitHubAuthManager state
        GitHubAuthManager.shared.signOut()
        
        if isDebugging {
            print("🧪 Test environment initialized")
        }
    }
    
    /// Cleans up after tests
    static func tearDown() {
        clearTestKeychain()
        GitHubAuthManager.shared.signOut()
        
        if isDebugging {
            print("🧹 Test environment cleaned up")
        }
    }
    
    /// Clears test keychain data
    private static func clearTestKeychain() {
        // In a real implementation, this would clear test keychain items
        // For now, we'll use this as a placeholder
    }
    
    // MARK: - Test Assertion Helpers
    
    /// Asserts that an async operation completes within the timeout
    static func assertAsyncCompletion<T>(
        timeout: TimeInterval = testTimeout,
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        return try await withTimeout(timeout, operation: operation)
    }
    
    /// Executes an async operation with a timeout
    private static func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Mock Network Responses
    
    struct MockResponses {
        static let successfulUserResponse = """
        {
            "id": \(TestData.mockUserID),
            "login": "\(TestData.mockUserLogin)",
            "avatar_url": "https://avatars.githubusercontent.com/u/\(TestData.mockUserID)?v=4",
            "name": "\(TestData.mockUserName)",
            "email": "\(TestData.mockUserEmail)"
        }
        """.data(using: .utf8)!
        
        static let successfulReposResponse = """
        [
            {
                "id": \(TestData.mockRepoID),
                "name": "\(TestData.mockRepoName)",
                "full_name": "\(TestData.mockRepoFullName)",
                "owner": {
                    "login": "\(TestData.mockUserLogin)",
                    "avatar_url": "https://avatars.githubusercontent.com/u/\(TestData.mockUserID)?v=4"
                },
                "default_branch": "main",
                "html_url": "https://github.com/\(TestData.mockRepoFullName)",
                "private": false
            }
        ]
        """.data(using: .utf8)!
        
        static let deviceCodeResponse = """
        {
            "device_code": "\(TestData.mockDeviceCode)",
            "user_code": "\(TestData.mockUserCode)",
            "verification_uri": "https://github.com/login/device",
            "verification_uri_complete": "https://github.com/login/device/continue",
            "expires_in": 900,
            "interval": 5
        }
        """.data(using: .utf8)!
        
        static let tokenResponse = """
        {
            "access_token": "\(TestData.mockAccessToken)",
            "token_type": "bearer",
            "scope": "repo,user"
        }
        """.data(using: .utf8)!
        
        static let unauthorizedResponse = """
        {
            "message": "Bad credentials",
            "documentation_url": "https://docs.github.com/rest"
        }
        """.data(using: .utf8)!
        
        static let notFoundResponse = """
        {
            "message": "Not Found",
            "documentation_url": "https://docs.github.com/rest"
        }
        """.data(using: .utf8)!
    }
    
    // MARK: - Test Performance Helpers
    
    /// Measures the performance of a synchronous operation
    static func measurePerformance<T>(
        identifier: String = "",
        operation: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if isDebugging {
            print("⏱️ \(identifier): \(timeElapsed)s")
        }
        
        return result
    }
    
    /// Measures the performance of an asynchronous operation
    static func measureAsyncPerformance<T>(
        identifier: String = "",
        operation: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if isDebugging {
            print("⏱️ \(identifier): \(timeElapsed)s")
        }
        
        return result
    }
    
    // MARK: - Test Data Generators
    
    /// Generates a unique test post content
    static func generateTestPostContent(suffix: String = "") -> PostContent {
        let timestamp = Date()
        let uniqueID = Int(timestamp.timeIntervalSince1970)
        
        return PostContent(
            quotation: "Test quotation \(uniqueID)\(suffix)",
            pageTitle: "Test Article \(uniqueID)\(suffix)",
            thoughts: "Test thoughts \(uniqueID)\(suffix)",
            timestamp: timestamp,
            sourceURL: "https://example.com/article-\(uniqueID)"
        )
    }
    
    /// Generates a unique test repository
    static func generateTestRepository(suffix: String = "") -> GitHubRepository {
        let uniqueID = Int(Date().timeIntervalSince1970)
        
        return GitHubRepository(
            id: uniqueID,
            name: "test-repo-\(uniqueID)\(suffix)",
            fullName: "testuser/test-repo-\(uniqueID)\(suffix)",
            owner: GitHubOwner(
                login: "testuser",
                avatarUrl: "https://avatars.githubusercontent.com/u/\(TestData.mockUserID)?v=4"
            ),
            defaultBranch: "main",
            htmlUrl: "https://github.com/testuser/test-repo-\(uniqueID)\(suffix)",
            isPrivate: false
        )
    }
    
    // MARK: - Test Validation Helpers
    
    /// Validates that a string is a valid GitHub access token format
    static func isValidAccessTokenFormat(_ token: String) -> Bool {
        // GitHub personal access tokens are typically 40 characters
        // OAuth tokens can be different lengths
        return token.count >= 20 && token.allSatisfy { $0.isASCII }
    }
    
    /// Validates that a string is a valid repository name
    static func isValidRepositoryName(_ name: String) -> Bool {
        let pattern = "^[a-zA-Z0-9._-]+$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: name.utf16.count)
        return regex.firstMatch(in: name, options: [], range: range) != nil
    }
    
    /// Validates that a URL string is properly formatted
    static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    // MARK: - Test Debugging Helpers
    
    /// Prints debug information about test state
    static func debugTestState(
        authManager: GitHubAuthManager? = nil,
        message: String = ""
    ) {
        guard isDebugging else { return }
        
        print("\n🔍 Test Debug State: \(message)")
        
        if let authManager = authManager {
            print("   - Authenticated: \(authManager.isAuthenticated)")
            print("   - Current User: \(authManager.currentUser?.login ?? "nil")")
            print("   - Repositories: \(authManager.repositories.count)")
            print("   - Selected Repo: \(authManager.selectedRepository?.name ?? "nil")")
            print("   - Authenticating: \(authManager.isAuthenticating)")
            print("   - Loading Repos: \(authManager.isLoadingRepositories)")
            print("   - Auth Error: \(authManager.authError ?? "nil")")
        }
        
        print("")
    }
}

// MARK: - Test Error Types

enum TestError: Error, LocalizedError {
    case timeout
    case mockSetupFailed
    case assertionFailed(String)
    case networkMockFailed
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Test operation timed out"
        case .mockSetupFailed:
            return "Failed to set up mock objects"
        case .assertionFailed(let message):
            return "Test assertion failed: \(message)"
        case .networkMockFailed:
            return "Network mock setup failed"
        }
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    /// Sets up test environment before each test
    func setUpTestEnvironment() {
        TestConfiguration.setUp()
    }
    
    /// Cleans up test environment after each test
    func tearDownTestEnvironment() {
        TestConfiguration.tearDown()
    }
    
    /// Asserts that two dates are approximately equal (within 1 second)
    func assertDatesApproximatelyEqual(
        _ date1: Date,
        _ date2: Date,
        accuracy: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let difference = abs(date1.timeIntervalSince(date2))
        XCTAssertLessThanOrEqual(
            difference,
            accuracy,
            "Dates differ by \(difference)s, expected within \(accuracy)s",
            file: file,
            line: line
        )
    }
    
    /// Waits for an async condition to be met
    func waitForCondition(
        timeout: TimeInterval = TestConfiguration.testTimeout,
        description: String = "Condition",
        condition: @escaping () -> Bool
    ) async throws {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
}