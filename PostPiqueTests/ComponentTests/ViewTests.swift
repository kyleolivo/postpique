import XCTest
import SwiftUI
@testable import PostPique

@MainActor
class ViewTests: XCTestCase {
    
    var authManager: GitHubAuthManager!
    
    override func setUp() {
        super.setUp()
        authManager = GitHubAuthManager.shared
        authManager.signOut() // Reset state
    }
    
    override func tearDown() {
        authManager.signOut()
        authManager = nil
        super.tearDown()
    }
    
    // MARK: - UserProfileView Tests
    
    func testUserProfileViewWithCompleteUser() {
        let user = MockData.mockUser
        let view = UserProfileView(user: user)
        
        // Test that view can be created without crashing
        XCTAssertNotNil(view)
        
        // Test user data properties
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.login, "testuser")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertTrue(user.avatarUrl.contains("avatars.githubusercontent.com"))
    }
    
    func testUserProfileViewWithUserWithoutEmail() {
        let user = MockData.mockUserWithoutEmail
        let view = UserProfileView(user: user)
        
        XCTAssertNotNil(view)
        XCTAssertNil(user.email)
        XCTAssertEqual(user.name, "No Email User")
    }
    
    func testUserProfileViewAvatarURL() {
        let user = MockData.mockUser
        let avatarURL = URL(string: user.avatarUrl)
        
        XCTAssertNotNil(avatarURL)
        XCTAssertEqual(avatarURL?.scheme, "https")
        XCTAssertEqual(avatarURL?.host, "avatars.githubusercontent.com")
    }
    
    // MARK: - RepositorySelectionView Tests
    
    func testRepositorySelectionViewWithRepository() {
        let repository = MockData.mockRepository
        let showingPicker = Binding.constant(false)
        let view = RepositorySelectionView(
            selectedRepository: repository,
            showingPicker: showingPicker
        )
        
        XCTAssertNotNil(view)
        XCTAssertEqual(repository.name, "test-repo")
        XCTAssertEqual(repository.owner.login, "testuser")
        XCTAssertFalse(repository.isPrivate)
    }
    
    func testRepositorySelectionViewWithoutRepository() {
        let showingPicker = Binding.constant(false)
        let view = RepositorySelectionView(
            selectedRepository: nil,
            showingPicker: showingPicker
        )
        
        XCTAssertNotNil(view)
    }
    
    func testRepositorySelectionViewWithPrivateRepository() {
        let repository = MockData.mockPrivateRepository
        let showingPicker = Binding.constant(false)
        let view = RepositorySelectionView(
            selectedRepository: repository,
            showingPicker: showingPicker
        )
        
        XCTAssertNotNil(view)
        XCTAssertTrue(repository.isPrivate)
        XCTAssertEqual(repository.name, "private-repo")
    }
    
    // MARK: - InstructionsView Tests
    
    func testInstructionsView() {
        let view = InstructionsView()
        XCTAssertNotNil(view)
    }
    
    func testInstructionStepView() {
        let view = InstructionStepView(step: "1", text: "Test instruction")
        XCTAssertNotNil(view)
    }
    
    // MARK: - ContentView State Tests
    
    func testContentViewUnauthenticatedState() {
        authManager.currentUser = nil
        let view = ContentView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertFalse(authManager.isAuthenticated)
    }
    
    func testContentViewAuthenticatedState() {
        authManager.currentUser = MockData.mockUser
        let view = ContentView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertTrue(authManager.isAuthenticated)
    }
    
    // MARK: - UnauthenticatedView Tests
    
    func testUnauthenticatedViewNormalState() {
        authManager.isAuthenticating = false
        let view = UnauthenticatedView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertFalse(authManager.isAuthenticating)
    }
    
    func testUnauthenticatedViewAuthenticatingState() {
        authManager.isAuthenticating = true
        authManager.userCode = "ABCD-1234"
        let view = UnauthenticatedView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertTrue(authManager.isAuthenticating)
        XCTAssertEqual(authManager.userCode, "ABCD-1234")
    }
    
    // MARK: - AuthenticatedView Tests
    
    func testAuthenticatedViewWithUser() {
        authManager.currentUser = MockData.mockUser
        authManager.repositories = MockData.mockRepositories
        let view = AuthenticatedView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertNotNil(authManager.currentUser)
        XCTAssertFalse(authManager.repositories.isEmpty)
    }
    
    func testAuthenticatedViewWithSelectedRepository() {
        authManager.currentUser = MockData.mockUser
        authManager.repositories = MockData.mockRepositories
        authManager.selectedRepository = MockData.mockRepository
        let view = AuthenticatedView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertNotNil(authManager.selectedRepository)
        XCTAssertEqual(authManager.selectedRepository?.name, "test-repo")
    }
    
    // MARK: - RepositoryPickerView Tests
    
    func testRepositoryPickerViewWithRepositories() {
        authManager.repositories = MockData.mockRepositories
        authManager.isLoadingRepositories = false
        let view = RepositoryPickerView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertEqual(authManager.repositories.count, 2)
        XCTAssertFalse(authManager.isLoadingRepositories)
    }
    
    func testRepositoryPickerViewLoading() {
        authManager.repositories = []
        authManager.isLoadingRepositories = true
        let view = RepositoryPickerView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertTrue(authManager.repositories.isEmpty)
        XCTAssertTrue(authManager.isLoadingRepositories)
    }
    
    func testRepositoryPickerViewEmpty() {
        authManager.repositories = []
        authManager.isLoadingRepositories = false
        let view = RepositoryPickerView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertTrue(authManager.repositories.isEmpty)
        XCTAssertFalse(authManager.isLoadingRepositories)
    }
    
    // MARK: - View Data Binding Tests
    
    func testRepositorySelectionBinding() {
        var showingPicker = false
        let binding = Binding(
            get: { showingPicker },
            set: { showingPicker = $0 }
        )
        
        XCTAssertFalse(binding.wrappedValue)
        
        binding.wrappedValue = true
        XCTAssertTrue(showingPicker)
        XCTAssertTrue(binding.wrappedValue)
    }
    
    // MARK: - View State Consistency Tests
    
    func testViewStateConsistencyWithAuthManager() {
        // Test that view state reflects auth manager state
        
        // Initially unauthenticated
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        
        // Authenticate
        authManager.currentUser = MockData.mockUser
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
        
        // Add repositories
        authManager.repositories = MockData.mockRepositories
        XCTAssertEqual(authManager.repositories.count, 2)
        
        // Select repository
        authManager.selectRepository(MockData.mockRepository)
        XCTAssertNotNil(authManager.selectedRepository)
        XCTAssertEqual(authManager.selectedRepository?.id, MockData.mockRepository.id)
        
        // Sign out
        authManager.signOut()
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertNil(authManager.selectedRepository)
        XCTAssertTrue(authManager.repositories.isEmpty)
    }
    
    // MARK: - Cross-Platform View Tests
    
    func testViewCompatibility() {
        // Test that views work on both platforms
        
        let user = MockData.mockUser
        let repository = MockData.mockRepository
        
        // These should compile and work on both iOS and macOS
        let userProfileView = UserProfileView(user: user)
        let repositoryView = RepositorySelectionView(
            selectedRepository: repository,
            showingPicker: .constant(false)
        )
        let instructionsView = InstructionsView()
        
        XCTAssertNotNil(userProfileView)
        XCTAssertNotNil(repositoryView)
        XCTAssertNotNil(instructionsView)
    }
    
    // MARK: - Error State Tests
    
    func testViewWithAuthError() {
        authManager.authError = "Test authentication error"
        let view = ContentView().environmentObject(authManager)
        
        XCTAssertNotNil(view)
        XCTAssertEqual(authManager.authError, "Test authentication error")
        
        // Clear error
        authManager.authError = nil
        XCTAssertNil(authManager.authError)
    }
    
    // MARK: - Performance Tests
    
    func testViewCreationPerformance() {
        measure {
            for _ in 0..<100 {
                let view = ContentView().environmentObject(authManager)
                _ = view
            }
        }
    }
    
    func testRepositoryListPerformance() {
        // Create a large number of repositories
        var repositories: [GitHubRepository] = []
        for i in 0..<1000 {
            let repo = GitHubRepository(
                id: i,
                name: "repo-\(i)",
                fullName: "user/repo-\(i)",
                owner: GitHubOwner(login: "user", avatarUrl: "https://example.com/avatar.png"),
                defaultBranch: "main",
                htmlUrl: "https://github.com/user/repo-\(i)",
                isPrivate: i % 2 == 0
            )
            repositories.append(repo)
        }
        
        measure {
            authManager.repositories = repositories
            let view = RepositoryPickerView().environmentObject(authManager)
            _ = view
        }
    }
}