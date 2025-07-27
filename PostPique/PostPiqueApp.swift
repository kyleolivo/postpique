//
//  PostPiqueApp.swift
//  PostPique
//
//  Created by Kyle Olivo on 7/26/25.
//

import SwiftUI

@main
struct PostPiqueApp: App {
    @StateObject private var authManager = GitHubAuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
        .windowResizability(.contentSize)
    }
}