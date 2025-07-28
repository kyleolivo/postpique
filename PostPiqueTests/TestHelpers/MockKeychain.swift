import Foundation
@testable import PostPique

class MockKeychain {
    private var storage: [String: Data] = [:]
    private var shouldFailOperations = false
    
    func setFailureMode(_ shouldFail: Bool) {
        shouldFailOperations = shouldFail
    }
    
    func set(_ data: Data, forKey key: String) throws {
        if shouldFailOperations {
            throw PostPiqueError.keychainError("Mock keychain error")
        }
        storage[key] = data
    }
    
    func get(forKey key: String) throws -> Data? {
        if shouldFailOperations {
            throw PostPiqueError.keychainError("Mock keychain error")
        }
        return storage[key]
    }
    
    func delete(forKey key: String) throws {
        if shouldFailOperations {
            throw PostPiqueError.keychainError("Mock keychain error")
        }
        storage.removeValue(forKey: key)
    }
    
    func clear() {
        storage.removeAll()
    }
}

class MockKeychainService: KeychainService {
    private let mockKeychain = MockKeychain()
    
    override func storeAccessToken(_ token: String) throws {
        try mockKeychain.set(token.data(using: .utf8)!, forKey: "github_access_token")
    }
    
    override func getAccessToken() throws -> String {
        guard let data = try mockKeychain.get(forKey: "github_access_token"),
              let token = String(data: data, encoding: .utf8) else {
            throw PostPiqueError.noAccessToken
        }
        return token
    }
    
    override func removeAccessToken() throws {
        try mockKeychain.delete(forKey: "github_access_token")
    }
    
    override func storeSelectedRepository(_ repository: GitHubRepository) {
        if let data = try? JSONEncoder().encode(repository) {
            try? mockKeychain.set(data, forKey: "selected_repository")
        }
    }
    
    override func getSelectedRepository() -> GitHubRepository? {
        guard let data = try? mockKeychain.get(forKey: "selected_repository"),
              let repository = try? JSONDecoder().decode(GitHubRepository.self, from: data) else {
            return nil
        }
        return repository
    }
    
    override func removeSelectedRepository() {
        try? mockKeychain.delete(forKey: "selected_repository")
    }
    
    func setFailureMode(_ shouldFail: Bool) {
        mockKeychain.setFailureMode(shouldFail)
    }
    
    func clear() {
        mockKeychain.clear()
    }
}