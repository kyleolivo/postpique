import Foundation

class KeychainService {
    static let shared = KeychainService()
    
    private let accessTokenKey = "github_access_token"
    private let userDataKey = "github_user"
    private let selectedRepoKey = "selected_repository"
    private let appGroup = "group.com.postpique.shared"
    
    private init() {}
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }
    
    // MARK: - Access Token
    func saveAccessToken(_ token: String) throws {
        guard let defaults = sharedDefaults else {
            throw PostPiqueError.keychainError("Cannot access shared UserDefaults")
        }
        defaults.set(token, forKey: accessTokenKey)
    }
    
    func getAccessToken() throws -> String {
        guard let defaults = sharedDefaults,
              let token = defaults.string(forKey: accessTokenKey) else {
            throw PostPiqueError.noAccessToken
        }
        return token
    }
    
    // MARK: - User Data
    
    func saveUserData(_ user: GitHubUser) throws {
        guard let defaults = sharedDefaults else {
            throw PostPiqueError.keychainError("Cannot access shared UserDefaults")
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        defaults.set(data, forKey: userDataKey)
    }
    
    func getUserData() -> GitHubUser? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: userDataKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(GitHubUser.self, from: data)
    }
    
    
    // MARK: - Repository Management
    func saveSelectedRepository(_ repo: GitHubRepository) throws {
        guard let defaults = sharedDefaults else {
            throw PostPiqueError.keychainError("Cannot access shared UserDefaults")
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(repo)
        defaults.set(data, forKey: selectedRepoKey)
    }
    
    func getSelectedRepository() -> GitHubRepository? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: selectedRepoKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(GitHubRepository.self, from: data)
    }
    
    
    // MARK: - Clear All Data
    func clearAllData() {
        sharedDefaults?.removeObject(forKey: accessTokenKey)
        sharedDefaults?.removeObject(forKey: userDataKey)
        sharedDefaults?.removeObject(forKey: selectedRepoKey)
    }
}