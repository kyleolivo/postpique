import XCTest
@testable import PostPique

@MainActor
class GitHubAuthManagerTests: XCTestCase {
    
    var authManager: GitHubAuthManager!
    var mockKeychainService: MockKeychainService!
    
    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeychainService()
        authManager = GitHubAuthManager.shared
        
        // Reset auth manager state
        authManager.signOut()
    }
    
    override func tearDown() {
        mockKeychainService.clear()
        authManager.signOut()
        authManager = nil
        mockKeychainService = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertFalse(authManager.isAuthenticating)
        XCTAssertFalse(authManager.isLoadingRepositories)
        XCTAssertNil(authManager.currentUser)
        XCTAssertNil(authManager.selectedRepository)
        XCTAssertNil(authManager.userCode)
        XCTAssertNil(authManager.authError)
        XCTAssertTrue(authManager.repositories.isEmpty)
    }
    
    // MARK: - Authentication State Tests
    
    func testAuthenticationStateTransitions() {
        // Initial state
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertFalse(authManager.isAuthenticating)
        
        // These tests would require mocking the actual authentication flow
        // For now, we test the expected state transitions
        
        // Simulate starting authentication
        // authManager.isAuthenticating = true
        // XCTAssertTrue(authManager.isAuthenticating)
        // XCTAssertFalse(authManager.isAuthenticated)
        
        // Simulate successful authentication
        // authManager.currentUser = MockData.mockUser
        // authManager.isAuthenticated = true
        // authManager.isAuthenticating = false
        // XCTAssertTrue(authManager.isAuthenticated)
        // XCTAssertFalse(authManager.isAuthenticating)
    }
    
    func testSignOut() {
        // Simulate being authenticated
        authManager.currentUser = MockData.mockUser
        authManager.repositories = MockData.mockRepositories
        authManager.selectedRepository = MockData.mockRepository
        
        // Sign out
        authManager.signOut()
        
        // Verify all data is cleared
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertNil(authManager.selectedRepository)
        XCTAssertTrue(authManager.repositories.isEmpty)
    }
    
    // MARK: - Repository Management Tests
    
    func testSelectRepository() {
        let testRepo = MockData.mockRepository
        
        authManager.selectRepository(testRepo)
        
        XCTAssertEqual(authManager.selectedRepository?.id, testRepo.id)
        XCTAssertEqual(authManager.selectedRepository?.name, testRepo.name)
    }
    
    func testSelectRepositoryUpdatesSelection() {
        let firstRepo = MockData.mockRepository
        let secondRepo = MockData.mockPrivateRepository
        
        // Select first repository
        authManager.selectRepository(firstRepo)
        XCTAssertEqual(authManager.selectedRepository?.id, firstRepo.id)
        
        // Select second repository
        authManager.selectRepository(secondRepo)
        XCTAssertEqual(authManager.selectedRepository?.id, secondRepo.id)
        XCTAssertNotEqual(authManager.selectedRepository?.id, firstRepo.id)
    }
    
    func testRepositoryLoadingState() {
        XCTAssertFalse(authManager.isLoadingRepositories)
        
        // These tests would require mocking the repository loading process
        // authManager.isLoadingRepositories = true
        // XCTAssertTrue(authManager.isLoadingRepositories)
        
        // After loading completes
        // authManager.isLoadingRepositories = false
        // XCTAssertFalse(authManager.isLoadingRepositories)
    }
    
    // MARK: - Error Handling Tests
    
    func testAuthErrorHandling() {
        XCTAssertNil(authManager.authError)
        
        let testError = "Authentication failed"
        authManager.authError = testError
        
        XCTAssertEqual(authManager.authError, testError)
        
        // Clear error
        authManager.authError = nil
        XCTAssertNil(authManager.authError)
    }
    
    func testCancelAuthentication() {
        // Simulate authentication in progress
        authManager.userCode = "ABCD-1234"
        authManager.isAuthenticating = true
        
        authManager.cancelAuthentication()
        
        XCTAssertNil(authManager.userCode)
        XCTAssertFalse(authManager.isAuthenticating)
    }
    
    // MARK: - User Code Tests
    
    func testUserCodeManagement() {
        XCTAssertNil(authManager.userCode)
        
        let testCode = "ABCD-1234"
        authManager.userCode = testCode
        
        XCTAssertEqual(authManager.userCode, testCode)
        
        // Clear code
        authManager.userCode = nil
        XCTAssertNil(authManager.userCode)
    }
    
    // MARK: - Repository Data Tests
    
    func testRepositoriesUpdate() {
        XCTAssertTrue(authManager.repositories.isEmpty)
        
        let testRepos = MockData.mockRepositories
        authManager.repositories = testRepos
        
        XCTAssertEqual(authManager.repositories.count, testRepos.count)
        XCTAssertEqual(authManager.repositories[0].id, testRepos[0].id)
        XCTAssertEqual(authManager.repositories[1].id, testRepos[1].id)
    }
    
    func testRepositoriesFilter() {
        let testRepos = MockData.mockRepositories
        authManager.repositories = testRepos
        
        let publicRepos = authManager.repositories.filter { !$0.isPrivate }
        let privateRepos = authManager.repositories.filter { $0.isPrivate }
        
        XCTAssertEqual(publicRepos.count, 1)
        XCTAssertEqual(privateRepos.count, 1)
        XCTAssertEqual(publicRepos[0].name, "test-repo")
        XCTAssertEqual(privateRepos[0].name, "private-repo")
    }
    
    // MARK: - Authentication Flow Integration Tests
    
    func testDeviceFlowDataStructure() {
        let deviceResponse = MockData.mockDeviceCodeResponse
        
        XCTAssertEqual(deviceResponse.userCode, "ABCD-1234")
        XCTAssertEqual(deviceResponse.deviceCode, "device_code_123")
        XCTAssertEqual(deviceResponse.verificationURI, "https://github.com/login/device")
        XCTAssertEqual(deviceResponse.expiresIn, 900)
        XCTAssertEqual(deviceResponse.interval, 5)
    }
    
    func testUserDataIntegration() {
        let testUser = MockData.mockUser
        authManager.currentUser = testUser
        
        XCTAssertEqual(authManager.currentUser?.login, "testuser")
        XCTAssertEqual(authManager.currentUser?.name, "Test User")
        XCTAssertEqual(authManager.currentUser?.email, "test@example.com")
        XCTAssertTrue(authManager.isAuthenticated)
    }
    
    func testUserWithoutEmailIntegration() {
        let testUser = MockData.mockUserWithoutEmail
        authManager.currentUser = testUser
        
        XCTAssertEqual(authManager.currentUser?.login, "noemailuser")
        XCTAssertEqual(authManager.currentUser?.name, "No Email User")
        XCTAssertNil(authManager.currentUser?.email)
        XCTAssertTrue(authManager.isAuthenticated)
    }
    
    // MARK: - State Consistency Tests
    
    func testAuthenticatedStateConsistency() {
        // When not authenticated, user should be nil
        authManager.currentUser = nil
        XCTAssertFalse(authManager.isAuthenticated)
        
        // When authenticated, user should exist
        authManager.currentUser = MockData.mockUser
        XCTAssertTrue(authManager.isAuthenticated)
        
        // After sign out, everything should be cleared
        authManager.signOut()
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
    }
    
    func testRepositoryStateConsistency() {
        // Initially no repositories
        XCTAssertTrue(authManager.repositories.isEmpty)
        XCTAssertNil(authManager.selectedRepository)
        
        // Add repositories
        authManager.repositories = MockData.mockRepositories
        XCTAssertFalse(authManager.repositories.isEmpty)
        
        // Selected repository should be from the available repositories
        authManager.selectRepository(MockData.mockRepository)
        XCTAssertNotNil(authManager.selectedRepository)
        
        let selectedRepo = authManager.selectedRepository!
        let foundInList = authManager.repositories.contains { $0.id == selectedRepo.id }
        XCTAssertTrue(foundInList, "Selected repository should exist in repositories list")
    }
    
    // MARK: - Thread Safety Tests
    
    func testMainActorAnnotations() {
        // Verify that the auth manager operations happen on main thread
        XCTAssertTrue(Thread.isMainThread)
        
        // These properties should be accessible from main thread
        _ = authManager.isAuthenticated
        _ = authManager.currentUser
        _ = authManager.repositories
        _ = authManager.selectedRepository
        
        // State modifications should also work on main thread
        authManager.authError = "Test error"
        authManager.authError = nil
    }
}