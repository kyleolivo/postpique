import Foundation
import SwiftUI

@MainActor
class GitHubAuthManager: ObservableObject {
    static let shared = GitHubAuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: GitHubUser?
    @Published var selectedRepository: GitHubRepository?
    @Published var repositories: [GitHubRepository] = []
    @Published var isLoadingRepositories = false
    @Published var isAuthenticating = false
    @Published var authError: String?
    
    // Device flow specific properties
    @Published var userCode: String?
    
    // OAuth App Client ID with Device Flow enabled
    private let clientID = "Ov23liBHg4b3h8St9NLy"
    
    private let keychainService = KeychainService.shared
    private let apiService = GitHubAPIService.shared
    private var pollTask: Task<Void, Error>?
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        do {
            _ = try keychainService.getAccessToken()
            isAuthenticated = true
            currentUser = keychainService.getUserData()
            selectedRepository = keychainService.getSelectedRepository()
        } catch {
            isAuthenticated = false
            currentUser = nil
            selectedRepository = nil
        }
    }
    
    // MARK: - Device Flow Authentication
    func authenticateWithDeviceFlow() async {
        isAuthenticating = true
        authError = nil
        
        do {
            // Step 1: Request device and user codes
            let deviceCodeResponse = try await requestDeviceCode()
            
            userCode = deviceCodeResponse.userCode
            
            // Step 2: Open browser for user to enter code
            if let url = URL(string: deviceCodeResponse.verificationURI) {
                #if os(iOS)
                await UIApplication.shared.open(url)
                #else
                NSWorkspace.shared.open(url)
                #endif
            }
            
            // Step 3: Poll for access token
            try await pollForAccessToken(
                deviceCode: deviceCodeResponse.deviceCode,
                interval: deviceCodeResponse.interval
            )
            
        } catch {
            // Don't show error if user cancelled
            let errorString = error.localizedDescription.lowercased()
            if error is CancellationError || errorString.contains("cancel") {
                // User cancelled, just reset state
                isAuthenticating = false
                userCode = nil
                authError = nil
            } else {
                // Provide more user-friendly error messages
                if errorString.contains("network") || errorString.contains("internet") {
                    authError = "Network connection error. Please check your internet connection."
                } else if errorString.contains("timeout") {
                    authError = "Request timed out. Please try again."
                } else {
                    authError = "Authentication failed. Please try again."
                }
                isAuthenticating = false
                userCode = nil
            }
        }
    }
    
    private func requestDeviceCode() async throws -> DeviceCodeResponse {
        guard let url = URL(string: "https://github.com/login/device/code") else {
            throw PostPiqueError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "client_id=\(clientID)&scope=repo%20user%20user:email"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PostPiqueError.requestFailed("Failed to get device code")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(DeviceCodeResponse.self, from: data)
    }
    
    private func pollForAccessToken(deviceCode: String, interval: Int) async throws {
        pollTask = Task {
            let pollInterval = TimeInterval(interval)
            
            while !Task.isCancelled {
                do {
                    if let accessToken = try await checkForAccessToken(deviceCode: deviceCode) {
                        // Success! Save token and fetch user data
                        try keychainService.saveAccessToken(accessToken)
                        
                        let user = try await apiService.getCurrentUser()
                        try keychainService.saveUserData(user)
                        
                        await MainActor.run {
                            self.currentUser = user
                            self.isAuthenticated = true
                            self.isAuthenticating = false
                            self.userCode = nil
                        }
                        
                        return
                    }
                } catch PostPiqueError.authenticationFailed(let message) {
                    if message == "authorization_pending" {
                        // User hasn't authorized yet, continue polling
                    } else if message == "slow_down" {
                        // GitHub wants us to slow down
                        try await Task.sleep(nanoseconds: UInt64((pollInterval + 5) * 1_000_000_000))
                        continue
                    } else {
                        // Other errors should stop polling
                        await MainActor.run {
                            self.authError = message
                            self.isAuthenticating = false
                            self.userCode = nil
                        }
                        return
                    }
                } catch {
                    // Don't show error if task was cancelled
                    let errorString = error.localizedDescription.lowercased()
                    if !(error is CancellationError) && !errorString.contains("cancel") {
                        await MainActor.run {
                            // Provide more user-friendly error messages
                            if errorString.contains("network") || errorString.contains("internet") {
                                self.authError = "Network connection error. Please check your internet connection."
                            } else if errorString.contains("timeout") {
                                self.authError = "Request timed out. Please try again."
                            } else {
                                self.authError = "Authentication failed. Please try again."
                            }
                            self.isAuthenticating = false
                            self.userCode = nil
                        }
                    }
                    return
                }
                
                try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            }
        }
        
        try await pollTask?.value
    }
    
    private func checkForAccessToken(deviceCode: String) async throws -> String? {
        guard let url = URL(string: "https://github.com/login/oauth/access_token") else {
            throw PostPiqueError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "client_id=\(clientID)&device_code=\(deviceCode)&grant_type=urn:ietf:params:oauth:grant-type:device_code"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PostPiqueError.requestFailed("Token request failed")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PostPiqueError.decodingError
        }
        
        if let error = json["error"] as? String {
            throw PostPiqueError.authenticationFailed(error)
        }
        
        return json["access_token"] as? String
    }
    
    // MARK: - Repository Management
    func loadRepositories() async {
        guard !isLoadingRepositories else { 
            return 
        }
        
        await MainActor.run {
            isLoadingRepositories = true
        }
        
        do {
            let loadedRepos = try await apiService.getUserRepositories()
            await MainActor.run {
                repositories = loadedRepos
                isLoadingRepositories = false
            }
        } catch {
            await MainActor.run {
                authError = "Failed to load repositories: \(error.localizedDescription)"
                isLoadingRepositories = false
            }
        }
    }
    
    func selectRepository(_ repository: GitHubRepository) {
        do {
            try keychainService.saveSelectedRepository(repository)
            selectedRepository = repository
        } catch {
            authError = "Failed to save repository selection: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        pollTask?.cancel()
        keychainService.clearAllData()
        isAuthenticated = false
        currentUser = nil
        selectedRepository = nil
        repositories = []
        isLoadingRepositories = false
        userCode = nil
    }
    
    // MARK: - Cancel Authentication
    func cancelAuthentication() {
        pollTask?.cancel()
        isAuthenticating = false
        userCode = nil
    }
}
