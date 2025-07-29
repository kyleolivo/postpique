//
//  ContentView.swift
//  PostPique
//
//  Created by Kyle Olivo on 7/26/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: GitHubAuthManager
    
    var body: some View {
        NavigationStack {
            Group {
                if authManager.isAuthenticated {
                    AuthenticatedView()
                } else {
                    UnauthenticatedView()
                }
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .alert("Authentication Error", isPresented: .constant(authManager.authError != nil)) {
                Button("OK") {
                    authManager.authError = nil
                }
            } message: {
                if let error = authManager.authError {
                    Text(error)
                }
            }
        }
#if os(macOS)
        .frame(width: 480, height: 680)
#else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
#endif
    }
}

struct UnauthenticatedView: View {
    @EnvironmentObject var authManager: GitHubAuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            if authManager.isAuthenticating {
                AuthenticatingView()
            } else {
                WelcomeView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func WelcomeView() -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                // App Icon with background
                VStack(spacing: 0) {
#if os(macOS)
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 96))
                            .foregroundColor(.blue)
                            .frame(width: 96, height: 96)
                    }
#else
                    // On iOS, try multiple approaches to load the app icon
                    if let appIcon = UIImage(named: "AppIcon60x60") ?? UIImage(named: "AppIcon") {
                        Image(uiImage: appIcon)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    } else {
                        // Create a placeholder app icon that looks like the real one
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [Color.orange.opacity(0.8), Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
#endif
                }
                .padding(.bottom, 8)
                
                // Title and description
                VStack(spacing: 10) {
                    Text("Welcome to PostPique")
#if os(iOS)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
#else
                        .font(.system(size: 28, weight: .bold, design: .rounded))
#endif
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Share quotes and thoughts\ndirectly to your GitHub Pages")
#if os(iOS)
                        .font(.system(size: 15))
#else
                        .font(.system(size: 16))
#endif
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            Spacer()
            
            // Sign in button
            VStack(spacing: 12) {
                Button {
                    Task {
                        await authManager.authenticateWithDeviceFlow()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Sign in with GitHub")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
#if os(iOS)
                    .padding(.vertical, 14)
#else
                    .padding(.vertical, 16)
#endif
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.gradient)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text("Secure authentication via GitHub")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private func AuthenticatingView() -> some View {
        if let userCode = authManager.userCode {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Enter this code on GitHub:")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(userCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                    
                    Text("Waiting for authorization...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Button("Cancel") {
                    authManager.cancelAuthentication()
                }
                .font(.body)
                .foregroundStyle(.red)
            }
        } else {
            ProgressView("Starting authentication...")
        }
    }
}

struct AuthenticatedView: View {
    @EnvironmentObject var authManager: GitHubAuthManager
    @State private var showingRepositoryPicker = false
    @State private var showingDonation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with user profile
            if let user = authManager.currentUser {
                UserProfileView(user: user)
#if os(iOS)
                    .padding(.horizontal, 32)
#else
                    .padding(.horizontal, 24)
#endif
                    .padding(.top, 20)
                    .padding(.bottom, 12)
            }
            
            VStack(spacing: 24) {
                // Repository Selection Section
                RepositorySelectionView(
                    selectedRepository: authManager.selectedRepository,
                    showingPicker: $showingRepositoryPicker
                )
#if os(iOS)
                .padding(.horizontal, 32)
#else
                .padding(.horizontal, 24)
#endif
                
                // Instructions Section
                InstructionsView()
#if os(iOS)
                    .padding(.horizontal, 32)
#else
                    .padding(.horizontal, 24)
#endif
                
                Spacer()
            }
            .padding(.top, 12)
            
            // Bottom section with donation and sign out
            VStack(spacing: 0) {
                Button(action: {
                    showingDonation = true
                }) {
                    HStack {
                        Text("Buy me a ☕")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.2, green: 0.8, blue: 0.8))
                    .cornerRadius(25)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Divider()
                
                Button("Sign Out") {
                    authManager.signOut()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showingRepositoryPicker) {
            RepositoryPickerView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingDonation) {
            DonationView()
#if os(macOS)
                .frame(width: 480, height: 620)
#endif
        }
        .task {
            await authManager.loadRepositories()
        }
    }
}

struct UserProfileView: View {
    let user: GitHubUser
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.quaternary)
            }
#if os(iOS)
            .frame(width: 44, height: 44)
#else
            .frame(width: 52, height: 52)
#endif
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name ?? user.login)
#if os(iOS)
                    .font(.system(size: 16, weight: .semibold))
#else
                    .font(.system(size: 18, weight: .semibold))
#endif
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("@\(user.login)")
#if os(iOS)
                    .font(.system(size: 12, weight: .medium))
#else
                    .font(.system(size: 14, weight: .medium))
#endif
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let email = user.email {
                    Text(email)
#if os(iOS)
                        .font(.system(size: 10))
#else
                        .font(.system(size: 12))
#endif
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            // Status indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(.green)
#if os(iOS)
                    .frame(width: 6, height: 6)
#else
                    .frame(width: 8, height: 8)
#endif
                Text("Connected")
#if os(iOS)
                    .font(.system(size: 10, weight: .medium))
#else
                    .font(.system(size: 12, weight: .medium))
#endif
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct RepositorySelectionView: View {
    let selectedRepository: GitHubRepository?
    @Binding var showingPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
                Text("Repository")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            if let repo = selectedRepository {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(repo.name)
#if os(iOS)
                                .font(.system(size: 15, weight: .semibold))
#else
                                .font(.system(size: 16, weight: .semibold))
#endif
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            if repo.isPrivate {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Text(repo.owner.login)
#if os(iOS)
                            .font(.system(size: 13))
#else
                            .font(.system(size: 14))
#endif
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingPicker = true
                    }
#if os(iOS)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
#else
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
#endif
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.06))
                        .stroke(.green.opacity(0.2), lineWidth: 1)
                )
            } else {
                Button {
                    showingPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Select Repository")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.gradient)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
}

struct InstructionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.orange)
                Text("How to Use")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionStepView(step: "1", text: "Select a GitHub Pages repository")
                InstructionStepView(step: "2", text: "Open the share sheet on any webpage")
                InstructionStepView(step: "3", text: "Choose PostPique")
                InstructionStepView(step: "4", text: "Add a quote and your thoughts")
                InstructionStepView(step: "5", text: "Post to GitHub Pages")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct InstructionStepView: View {
    let step: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(step)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(.blue.gradient)
                )
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

struct RepositoryPickerView: View {
    @EnvironmentObject var authManager: GitHubAuthManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if authManager.isLoadingRepositories {
                    Spacer()
                    ProgressView("Loading repositories...")
                    Spacer()
                } else if authManager.repositories.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Repositories")
                            .font(.headline)
                        Text("You don't have any repositories yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Refresh") {
                            Task {
                                await authManager.loadRepositories()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(authManager.repositories) { repo in
                                Button(action: {
                                    selectRepository(repo)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(repo.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(repo.owner.login)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if repo.isPrivate {
                                            Image(systemName: "lock.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        if authManager.selectedRepository?.id == repo.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.gray.opacity(0.05))
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Repository")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        Task {
                            await authManager.loadRepositories()
                        }
                    }
                    .disabled(authManager.isLoadingRepositories)
                }
            }
        }
    }
    
    private func selectRepository(_ repo: GitHubRepository) {
        authManager.selectRepository(repo)
        dismiss()
    }
    
}


#Preview {
    ContentView()
        .environmentObject(GitHubAuthManager.shared)
}
