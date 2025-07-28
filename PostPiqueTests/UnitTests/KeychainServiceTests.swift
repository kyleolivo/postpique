import XCTest
@testable import PostPique

class KeychainServiceTests: XCTestCase {
    
    var mockKeychainService: MockKeychainService!
    
    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeychainService()
        mockKeychainService.clear()
    }
    
    override func tearDown() {
        mockKeychainService.clear()
        mockKeychainService = nil
        super.tearDown()
    }
    
    // MARK: - Access Token Tests
    
    func testStoreAndRetrieveAccessToken() throws {
        let testToken = "test_access_token_123"
        
        // Store token
        try mockKeychainService.storeAccessToken(testToken)
        
        // Retrieve token
        let retrievedToken = try mockKeychainService.getAccessToken()
        
        XCTAssertEqual(retrievedToken, testToken)
    }
    
    func testGetAccessTokenWhenNoneStored() {
        XCTAssertThrowsError(try mockKeychainService.getAccessToken()) { error in
            XCTAssertEqual(error as? PostPiqueError, PostPiqueError.noAccessToken)
        }
    }
    
    func testRemoveAccessToken() throws {
        let testToken = "test_access_token_123"
        
        // Store and verify token exists
        try mockKeychainService.storeAccessToken(testToken)
        let retrievedToken = try mockKeychainService.getAccessToken()
        XCTAssertEqual(retrievedToken, testToken)
        
        // Remove token
        try mockKeychainService.removeAccessToken()
        
        // Verify token is gone
        XCTAssertThrowsError(try mockKeychainService.getAccessToken()) { error in
            XCTAssertEqual(error as? PostPiqueError, PostPiqueError.noAccessToken)
        }
    }
    
    func testStoreAccessTokenFailure() {
        mockKeychainService.setFailureMode(true)
        
        XCTAssertThrowsError(try mockKeychainService.storeAccessToken("test_token")) { error in
            XCTAssertTrue(error is PostPiqueError)
        }
    }
    
    func testGetAccessTokenFailure() throws {
        // First store a token successfully
        try mockKeychainService.storeAccessToken("test_token")
        
        // Then enable failure mode
        mockKeychainService.setFailureMode(true)
        
        XCTAssertThrowsError(try mockKeychainService.getAccessToken()) { error in
            XCTAssertTrue(error is PostPiqueError)
        }
    }
    
    func testRemoveAccessTokenFailure() throws {
        // Store token first
        try mockKeychainService.storeAccessToken("test_token")
        
        // Enable failure mode
        mockKeychainService.setFailureMode(true)
        
        XCTAssertThrowsError(try mockKeychainService.removeAccessToken()) { error in
            XCTAssertTrue(error is PostPiqueError)
        }
    }
    
    // MARK: - Repository Tests
    
    func testStoreAndRetrieveRepository() {
        let testRepo = MockData.mockRepository
        
        // Store repository
        mockKeychainService.storeSelectedRepository(testRepo)
        
        // Retrieve repository
        let retrievedRepo = mockKeychainService.getSelectedRepository()
        
        XCTAssertNotNil(retrievedRepo)
        XCTAssertEqual(retrievedRepo?.id, testRepo.id)
        XCTAssertEqual(retrievedRepo?.name, testRepo.name)
        XCTAssertEqual(retrievedRepo?.fullName, testRepo.fullName)
        XCTAssertEqual(retrievedRepo?.owner.login, testRepo.owner.login)
        XCTAssertEqual(retrievedRepo?.defaultBranch, testRepo.defaultBranch)
        XCTAssertEqual(retrievedRepo?.isPrivate, testRepo.isPrivate)
    }
    
    func testGetRepositoryWhenNoneStored() {
        let retrievedRepo = mockKeychainService.getSelectedRepository()
        XCTAssertNil(retrievedRepo)
    }
    
    func testStorePrivateRepository() {
        let privateRepo = MockData.mockPrivateRepository
        
        mockKeychainService.storeSelectedRepository(privateRepo)
        let retrievedRepo = mockKeychainService.getSelectedRepository()
        
        XCTAssertNotNil(retrievedRepo)
        XCTAssertTrue(retrievedRepo!.isPrivate)
        XCTAssertEqual(retrievedRepo?.name, "private-repo")
    }
    
    func testRemoveSelectedRepository() {
        let testRepo = MockData.mockRepository
        
        // Store repository
        mockKeychainService.storeSelectedRepository(testRepo)
        XCTAssertNotNil(mockKeychainService.getSelectedRepository())
        
        // Remove repository
        mockKeychainService.removeSelectedRepository()
        
        // Verify repository is gone
        XCTAssertNil(mockKeychainService.getSelectedRepository())
    }
    
    func testOverwriteRepository() {
        let firstRepo = MockData.mockRepository
        let secondRepo = MockData.mockPrivateRepository
        
        // Store first repository
        mockKeychainService.storeSelectedRepository(firstRepo)
        let retrieved1 = mockKeychainService.getSelectedRepository()
        XCTAssertEqual(retrieved1?.name, "test-repo")
        
        // Store second repository (should overwrite)
        mockKeychainService.storeSelectedRepository(secondRepo)
        let retrieved2 = mockKeychainService.getSelectedRepository()
        XCTAssertEqual(retrieved2?.name, "private-repo")
        XCTAssertNotEqual(retrieved2?.id, firstRepo.id)
    }
    
    // MARK: - Integration Tests
    
    func testTokenAndRepositoryIndependence() throws {
        let testToken = "test_token"
        let testRepo = MockData.mockRepository
        
        // Store both
        try mockKeychainService.storeAccessToken(testToken)
        mockKeychainService.storeSelectedRepository(testRepo)
        
        // Verify both exist
        XCTAssertEqual(try mockKeychainService.getAccessToken(), testToken)
        XCTAssertEqual(mockKeychainService.getSelectedRepository()?.id, testRepo.id)
        
        // Remove token, repository should remain
        try mockKeychainService.removeAccessToken()
        XCTAssertThrowsError(try mockKeychainService.getAccessToken())
        XCTAssertNotNil(mockKeychainService.getSelectedRepository())
        
        // Remove repository, should not affect token operations
        mockKeychainService.removeSelectedRepository()
        XCTAssertNil(mockKeychainService.getSelectedRepository())
    }
    
    func testClearAllData() throws {
        let testToken = "test_token"
        let testRepo = MockData.mockRepository
        
        // Store both
        try mockKeychainService.storeAccessToken(testToken)
        mockKeychainService.storeSelectedRepository(testRepo)
        
        // Verify both exist
        XCTAssertNoThrow(try mockKeychainService.getAccessToken())
        XCTAssertNotNil(mockKeychainService.getSelectedRepository())
        
        // Clear all data
        mockKeychainService.clear()
        
        // Verify both are gone
        XCTAssertThrowsError(try mockKeychainService.getAccessToken())
        XCTAssertNil(mockKeychainService.getSelectedRepository())
    }
}