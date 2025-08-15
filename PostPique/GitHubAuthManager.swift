import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
class GitHubAuthManager: NSObject, ObservableObject {
    static let shared = GitHubAuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: GitHubUser?
    @Published var selectedRepository: GitHubRepository?
    @Published var repositories: [GitHubRepository] = []
    @Published var isLoadingRepositories = false
    @Published var isAuthenticating = false
    @Published var authError: String?
    @Published var userCode: String?
    @Published var showWebSession = false
    
    // OAuth App Client ID
    private let clientID = "Ov23liBHg4b3h8St9NLy"
    
    private let keychainService = KeychainService.shared
    private let apiService = GitHubAPIService.shared
    private var webAuthSession: ASWebAuthenticationSession?
    private var pollTask: Task<Void, Error>?
    
    private override init() {
        super.init()
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
    
    // MARK: - Device Flow Authentication with ASWebAuthenticationSession
    func authenticateWithDeviceFlow() async {
        isAuthenticating = true
        authError = nil
        
        do {
            // Step 1: Request device and user codes
            let deviceCodeResponse = try await requestDeviceCode()
            
            userCode = deviceCodeResponse.userCode
            
            // Step 2: Don't open web session yet - let user see the code first
            // The web session will be opened when user taps "Continue"
            
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
    
    private func openDeviceCodePage(verificationURI: String) async {
        guard let url = URL(string: verificationURI) else { return }
        
        // Cancel any existing session first
        webAuthSession?.cancel()
        webAuthSession = nil
        
        await MainActor.run {
            webAuthSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "postpique"
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    // For device flow, we don't need the callback URL
                    // The user just needs to enter the code in the web view
                    if let error = error {
                        if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            // User cancelled, stop polling
                            self?.pollTask?.cancel()
                        }
                    }
                }
            }
            
            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = true
            
            guard let session = webAuthSession else {
                self.authError = "Failed to create authentication session"
                self.isAuthenticating = false
                return
            }
            
            if !session.start() {
                self.authError = "Failed to start authentication"
                self.isAuthenticating = false
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
        webAuthSession?.cancel()
        webAuthSession = nil
        keychainService.clearAllData()
        isAuthenticated = false
        currentUser = nil
        selectedRepository = nil
        repositories = []
        isLoadingRepositories = false
        userCode = nil
        authError = nil
    }
    
    // MARK: - Cancel Authentication
    func cancelAuthentication() {
        pollTask?.cancel()
        webAuthSession?.cancel()
        webAuthSession = nil
        isAuthenticating = false
        userCode = nil
        authError = nil
        showWebSession = false
    }
    
    func openWebSession() async {
        guard userCode != nil else { return }
        
        // Get the verification URI from the device code response
        let verificationURI = "https://github.com/login/device"
        
        await openDeviceCodePage(verificationURI: verificationURI)
        showWebSession = true
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension GitHubAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for authentication")
        }
        return window
        #else
        guard let window = NSApplication.shared.windows.first else {
            fatalError("No window available for authentication")
        }
        return window
        #endif
    }
}
