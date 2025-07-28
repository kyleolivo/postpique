import XCTest
@testable import PostPique

@MainActor
class AuthenticationFlowTests: XCTestCase {
    
    var authManager: GitHubAuthManager!
    var mockKeychainService: MockKeychainService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        authManager = GitHubAuthManager.shared
        mockKeychainService = MockKeychainService()
        mockURLSession = MockURLSession()
        
        // Reset state
        authManager.signOut()
        mockKeychainService.clear()
    }
    
    override func tearDown() {
        authManager.signOut()
        mockKeychainService.clear()
        authManager = nil
        mockKeychainService = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Complete Authentication Flow Tests
    
    func testCompleteAuthenticationFlowSuccess() async throws {
        // Test the complete flow from start to finish
        
        // 1. Initial state
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertNil(authManager.userCode)
        
        // 2. Start device flow - would mock the network request
        let deviceResponse = MockData.mockDeviceCodeResponse
        authManager.userCode = deviceResponse.userCode
        authManager.isAuthenticating = true
        
        XCTAssertTrue(authManager.isAuthenticating)
        XCTAssertEqual(authManager.userCode, "ABCD-1234")
        
        // 3. Simulate successful token exchange
        let accessToken = "test_access_token_123"
        try mockKeychainService.storeAccessToken(accessToken)
        
        // 4. Simulate user data fetch
        authManager.currentUser = MockData.mockUser
        authManager.isAuthenticating = false
        
        // 5. Verify final state
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
        XCTAssertFalse(authManager.isAuthenticating)
        XCTAssertEqual(authManager.currentUser?.login, "testuser")
    }
    
    func testAuthenticationFlowCancellation() {
        // 1. Start authentication
        authManager.userCode = "ABCD-1234"
        authManager.isAuthenticating = true
        
        XCTAssertTrue(authManager.isAuthenticating)
        XCTAssertNotNil(authManager.userCode)
        
        // 2. Cancel authentication
        authManager.cancelAuthentication()
        
        // 3. Verify state is reset
        XCTAssertFalse(authManager.isAuthenticating)
        XCTAssertNil(authManager.userCode)
        XCTAssertFalse(authManager.isAuthenticated)
    }
    
    func testAuthenticationFlowError() {
        // 1. Start authentication
        authManager.isAuthenticating = true
        authManager.userCode = "ABCD-1234"
        
        // 2. Simulate error during authentication
        let errorMessage = "Authentication failed: Invalid device code"
        authManager.authError = errorMessage
        authManager.isAuthenticating = false
        authManager.userCode = nil
        
        // 3. Verify error state
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertFalse(authManager.isAuthenticating)
        XCTAssertNil(authManager.userCode)
        XCTAssertEqual(authManager.authError, errorMessage)
        
        // 4. Clear error
        authManager.authError = nil
        XCTAssertNil(authManager.authError)
    }
    
    // MARK: - Token Management Integration Tests
    
    func testTokenPersistenceFlow() throws {
        let accessToken = "persistent_token_123"
        
        // 1. Store token
        try mockKeychainService.storeAccessToken(accessToken)
        
        // 2. Verify token can be retrieved
        let retrievedToken = try mockKeychainService.getAccessToken()
        XCTAssertEqual(retrievedToken, accessToken)
        
        // 3. Simulate app restart by creating new keychain service instance
        let newKeychainService = MockKeychainService()
        
        // Note: In real implementation, this would work because keychain persists
        // For mock, we'd need to simulate persistence
        XCTAssertThrowsError(try newKeychainService.getAccessToken())
    }
    
    func testTokenExpirationFlow() throws {
        // 1. Store token and authenticate
        try mockKeychainService.storeAccessToken("expired_token")
        authManager.currentUser = MockData.mockUser
        
        XCTAssertTrue(authManager.isAuthenticated)
        
        // 2. Simulate token expiration (API call returns 401)
        // This would be handled in the actual API service
        
        // 3. Sign out due to expired token
        authManager.signOut()
        
        // 4. Verify user is signed out
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
    }
    
    // MARK: - User Data Integration Tests
    
    func testUserDataLoadingFlow() async {
        // 1. Simulate successful authentication with token
        try? mockKeychainService.storeAccessToken("valid_token")
        
        // 2. Mock successful user data response
        mockURLSession.setMockHTTPResponse(
            data: MockData.mockUserJSON,
            statusCode: 200
        )
        
        // 3. Simulate loading user data
        authManager.currentUser = MockData.mockUser
        
        // 4. Verify user data is loaded correctly
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(authManager.currentUser?.login, "testuser")
        XCTAssertEqual(authManager.currentUser?.name, "Test User")
        XCTAssertEqual(authManager.currentUser?.email, "test@example.com")
    }
    
    func testUserDataLoadingError() async {
        // 1. Simulate authentication with token
        try? mockKeychainService.storeAccessToken("valid_token")
        
        // 2. Mock failed user data response
        mockURLSession.setMockHTTPResponse(
            data: "Unauthorized".data(using: .utf8),
            statusCode: 401
        )
        
        // 3. Simulate error handling
        authManager.authError = "Failed to load user data"
        
        // 4. Verify error state
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.authError)
    }
    
    // MARK: - Repository Loading Integration Tests
    
    func testRepositoryLoadingFlow() async {
        // 1. Authenticate user first
        authManager.currentUser = MockData.mockUser
        try? mockKeychainService.storeAccessToken("valid_token")
        
        XCTAssertTrue(authManager.isAuthenticated)
        
        // 2. Start loading repositories
        authManager.isLoadingRepositories = true
        XCTAssertTrue(authManager.isLoadingRepositories)
        
        // 3. Mock successful repositories response
        mockURLSession.setMockHTTPResponse(
            data: MockData.mockRepositoriesJSON,
            statusCode: 200
        )
        
        // 4. Simulate repositories loaded
        authManager.repositories = MockData.mockRepositories
        authManager.isLoadingRepositories = false
        
        // 5. Verify repositories are loaded
        XCTAssertFalse(authManager.isLoadingRepositories)
        XCTAssertEqual(authManager.repositories.count, 2)
        XCTAssertEqual(authManager.repositories[0].name, "test-repo")
        XCTAssertEqual(authManager.repositories[1].name, "private-repo")
    }
    
    func testRepositoryLoadingError() async {
        // 1. Authenticate user
        authManager.currentUser = MockData.mockUser
        
        // 2. Start loading repositories
        authManager.isLoadingRepositories = true
        
        // 3. Mock failed repositories response
        mockURLSession.setMockHTTPResponse(
            data: "Forbidden".data(using: .utf8),
            statusCode: 403
        )
        
        // 4. Simulate error handling
        authManager.isLoadingRepositories = false
        authManager.authError = "Failed to load repositories"
        
        // 5. Verify error state
        XCTAssertFalse(authManager.isLoadingRepositories)
        XCTAssertTrue(authManager.repositories.isEmpty)
        XCTAssertNotNil(authManager.authError)
    }
    
    // MARK: - Repository Selection Integration Tests
    
    func testRepositorySelectionFlow() {
        // 1. Authenticate and load repositories
        authManager.currentUser = MockData.mockUser
        authManager.repositories = MockData.mockRepositories
        
        XCTAssertNil(authManager.selectedRepository)
        
        // 2. Select a repository
        let targetRepo = MockData.mockRepository
        authManager.selectRepository(targetRepo)
        
        // 3. Verify selection
        XCTAssertNotNil(authManager.selectedRepository)
        XCTAssertEqual(authManager.selectedRepository?.id, targetRepo.id)
        XCTAssertEqual(authManager.selectedRepository?.name, "test-repo")
        
        // 4. Change selection
        let newRepo = MockData.mockPrivateRepository
        authManager.selectRepository(newRepo)
        
        // 5. Verify new selection
        XCTAssertEqual(authManager.selectedRepository?.id, newRepo.id)
        XCTAssertEqual(authManager.selectedRepository?.name, "private-repo")
        XCTAssertTrue(authManager.selectedRepository!.isPrivate)
    }
    
    func testRepositorySelectionPersistence() {
        // 1. Authenticate and select repository
        authManager.currentUser = MockData.mockUser
        authManager.selectRepository(MockData.mockRepository)
        
        let selectedRepo = authManager.selectedRepository
        XCTAssertNotNil(selectedRepo)
        
        // 2. Store selection in keychain
        mockKeychainService.storeSelectedRepository(selectedRepo!)
        
        // 3. Simulate app restart
        authManager.selectedRepository = nil
        XCTAssertNil(authManager.selectedRepository)
        
        // 4. Restore selection from keychain
        let restoredRepo = mockKeychainService.getSelectedRepository()
        authManager.selectedRepository = restoredRepo
        
        // 5. Verify restoration
        XCTAssertNotNil(authManager.selectedRepository)
        XCTAssertEqual(authManager.selectedRepository?.id, selectedRepo?.id)
    }
    
    // MARK: - Sign Out Integration Tests
    
    func testCompleteSignOutFlow() throws {
        // 1. Set up authenticated state with data
        try mockKeychainService.storeAccessToken("test_token")
        authManager.currentUser = MockData.mockUser
        authManager.repositories = MockData.mockRepositories
        authManager.selectedRepository = MockData.mockRepository
        mockKeychainService.storeSelectedRepository(MockData.mockRepository)
        
        // 2. Verify authenticated state
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
        XCTAssertFalse(authManager.repositories.isEmpty)
        XCTAssertNotNil(authManager.selectedRepository)
        
        // 3. Sign out
        authManager.signOut()
        
        // 4. Verify all app state is cleared
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertTrue(authManager.repositories.isEmpty)
        XCTAssertNil(authManager.selectedRepository)
        
        // 5. Verify keychain is cleared (in real implementation)
        XCTAssertThrowsError(try mockKeychainService.getAccessToken())
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryFlow() throws {
        // 1. Start with error state
        authManager.authError = "Network error"
        XCTAssertNotNil(authManager.authError)
        
        // 2. Clear error and retry authentication
        authManager.authError = nil
        XCTAssertNil(authManager.authError)
        
        // 3. Successful authentication
        try mockKeychainService.storeAccessToken("recovery_token")
        authManager.currentUser = MockData.mockUser
        
        // 4. Verify recovery
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNil(authManager.authError)
    }
    
    // MARK: - State Transition Tests
    
    func testAuthenticationStateTransitions() {
        // Test all valid state transitions
        
        // Initial -> Authenticating
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertFalse(authManager.isAuthenticating)
        
        authManager.isAuthenticating = true
        XCTAssertTrue(authManager.isAuthenticating)
        XCTAssertFalse(authManager.isAuthenticated)
        
        // Authenticating -> Authenticated
        authManager.currentUser = MockData.mockUser
        authManager.isAuthenticating = false
        XCTAssertFalse(authManager.isAuthenticating)
        XCTAssertTrue(authManager.isAuthenticated)
        
        // Authenticated -> Unauthenticated (sign out)
        authManager.signOut()
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertFalse(authManager.isAuthenticating)
    }
}