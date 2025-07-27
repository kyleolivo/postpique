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
            .navigationTitle("PostPique")
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
        .frame(width: 480, height: 620)
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
            
            VStack(spacing: 24) {
                // App Icon with background
                VStack(spacing: 0) {
                    Image(nsImage: NSImage(named: "AppIcon")!)
                        .resizable()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 8)
                
                // Title and description
                VStack(spacing: 12) {
                    Text("Welcome to PostPique")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Share quotes and thoughts\ndirectly to your GitHub Pages")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            Spacer()
            Spacer()
            
            // Sign in button
            VStack(spacing: 16) {
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
                    .padding(.vertical, 16)
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with user profile
            if let user = authManager.currentUser {
                UserProfileView(user: user)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
            }
            
            VStack(spacing: 24) {
                // Repository Selection Section
                RepositorySelectionView(
                    selectedRepository: authManager.selectedRepository,
                    showingPicker: $showingRepositoryPicker
                )
                .padding(.horizontal, 24)
                
                // Instructions Section
                InstructionsView()
                    .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(.top, 12)
            
            // Bottom section with sign out
            VStack(spacing: 0) {
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
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(user.name ?? user.login)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("@\(user.login)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                if let email = user.email {
                    Text(email)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Connected")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
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
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            if repo.isPrivate {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Text(repo.owner.login)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingPicker = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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