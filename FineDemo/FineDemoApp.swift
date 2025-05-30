//
//  FineDemoApp.swift
//  FineDemo
//
//  Created by m1 on 01/05/2025.
//

import SwiftUI

@main
struct FineDemoApp: App {
    // State object for the plate service that will be shared throughout the app
    @StateObject private var plateService = PlateService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(Color("PrimaryColor")) // Set app's accent color
                .onAppear {
                    // Configure UI appearance
                    configureAppearance()
                }
        }
    }
    
    /// Configure the app's UI appearance
    private func configureAppearance() {
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("PrimaryColor"))
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set back button appearance
        UINavigationBar.appearance().tintColor = .white
    }
}
