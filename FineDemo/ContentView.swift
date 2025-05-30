//
//  ContentView.swift
//  FineDemo
//
//  Created by m1 on 01/05/2025.
//

import SwiftUI

// Main app navigation coordinator
struct ContentView: View {
    @StateObject private var plateService = PlateService.shared
    @State private var appState: AppState = .splash
    @State private var searchedPlate: String = ""
    
    var body: some View {
        ZStack {
            // App background
            Color("Background")
                .ignoresSafeArea()
            
            // Screen content based on app state
            switch appState {
            case .splash:
                SplashScreen(onComplete: { appState = .home })
            case .home:
                HomeScreen(
                    onSearch: { plate in
                        searchedPlate = plate
                        appState = .loading
                        
                        // Use the PlateService to search for fines
                        plateService.searchForFines(plate: plate) { result in
                            switch result {
                            case .success(_):
                                appState = .results
                            case .failure(let error):
                                // Handle error - return to home with alert
                                appState = .home
                                // Error would be displayed on home screen
                                plateService.errorMessage = error.localizedDescription
                            }
                        }
                    },
                    onSettings: { appState = .settings },
                    onProfile: { 
                        if plateService.authState == .loggedIn {
                            appState = .profile
                        } else {
                            appState = .login
                        }
                    },
                    plateService: plateService
                )
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToRegister"))) { _ in
                    appState = .register
                }
            case .loading:
                LoadingScreen(plate: searchedPlate)
            case .results:
                if let result = plateService.searchResult {
                    ResultsScreen(
                        result: result,
                        onBackToSearch: { appState = .home },
                        onSavePlate: {
                            plateService.savePlate(result.plate)
                        },
                        onViewVehicleDetails: { appState = .vehicleDetails }
                    )
                } else {
                    // Fallback if no result
                    Text("No results available")
                        .onAppear {
                            appState = .home
                        }
                }
            case .settings:
                SettingsScreen(onBack: { appState = .home })
            case .vehicleDetails:
                if let result = plateService.searchResult {
                    VehicleDetailsScreen(
                        vehicle: result.vehicle,
                        plate: result.plate,
                        onBack: { appState = .results }
                    )
                } else {
                    // Fallback if no result
                    Text("No vehicle details available")
                        .onAppear {
                            appState = .home
                        }
                }
            case .profile:
                ProfileScreen(
                    onBack: { appState = .home },
                    onLogout: {
                        plateService.logout()
                        appState = .home
                    }
                )
            case .login:
                LoginScreen(
                    onBack: { appState = .home },
                    onLogin: { appState = .profile },
                    onRegister: { appState = .register }
                )
            case .register:
                RegisterScreen(
                    onBack: { appState = .login },
                    onRegisterSuccess: { appState = .profile }
                )
            }
        }
        .preferredColorScheme(.light) // Default to light mode
    }
}

// App states for navigation
enum AppState {
    case splash
    case home
    case loading
    case results
    case settings
    case vehicleDetails
    case profile
    case login
    case register
}

// MARK: - Splash Screen
struct SplashScreen: View {
    let onComplete: () -> Void
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Background color matching logo's navy blue
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo image
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240)
                    .opacity(opacity)
                    .scaleEffect(scale)
                
                // Tagline
                Text("UK License Plate Fine Checker")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextColor").opacity(0.8))
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Animate logo appearance
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            
            // Transition to home screen after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Home Screen
struct HomeScreen: View {
    let onSearch: (String) -> Void
    let onSettings: () -> Void
    let onProfile: () -> Void
    let plateService: PlateService
    
    @State private var licensePlate: String = ""
    @State private var showValidationAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var isInputFocused: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradients
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Background"),
                        Color("Background"),
                        Color("SecondaryColor").opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Background decorative elements
                GeometryReader { geo in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.1)
                        .blur(radius: 50)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.8)
                        .blur(radius: 50)
                }
                
                VStack(spacing: 0) {
                    // Fixed prominent logo header
                    VStack(spacing: 15) {
                        // Large prominent logo
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 240, height: 120)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        // App tagline
                        Text("UK License Plate Fine Checker")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color("TextColor").opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 25)
                    .padding(.horizontal)
                    .background(
                        // Subtle background for the header
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("Background").opacity(0.95),
                                        Color("Background").opacity(0.8)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    
                    // Main scrollable content
                    ScrollView {
                        VStack(spacing: 35) {
                            // Search section
                            VStack(spacing: 20) {
                                Text("Enter your license plate below")
                                    .font(.headline)
                                    .foregroundColor(Color("TextColor"))
                                
                                // License plate input
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "rectangle.and.text.magnifyingglass")
                                            .foregroundColor(isInputFocused ? Color("PrimaryColor") : Color.gray.opacity(0.6))
                                            .font(.system(size: 22))
                                            .padding(.leading, 16)
                                        
                                        TextField("AB12 CDE", text: $licensePlate)
                                            .font(.system(size: 22, weight: .medium))
                                            .padding(16)
                                            .foregroundColor(Color("SecondaryColor"))
                                            .onChange(of: licensePlate) { newValue in
                                                // Format and validate as user types
                                                licensePlate = newValue.uppercased()
                                            }
                                            .autocapitalization(.allCharacters)
                                            .disableAutocorrection(true)
                                            .onTapGesture {
                                                isInputFocused = true
                                            }
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.9))
                                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(isInputFocused ? Color("PrimaryColor") : Color.clear, lineWidth: 2)
                                    )
                                    
                                    Text("UK format only, e.g. AB12 CDE")
                                        .font(.caption)
                                        .foregroundColor(Color("TextColor").opacity(0.8))
                                        .padding(.leading, 5)
                                }
                                .padding(.horizontal, 20)
                                
                                // Search button
                                Button(action: {
                                    isInputFocused = false
                                    if plateService.isValidUKPlate(licensePlate) {
                                        onSearch(licensePlate)
                                    } else {
                                        showValidationAlert = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 18, weight: .bold))
                                        Text("Check for Fines")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(15)
                                    .shadow(color: Color("PrimaryColor").opacity(0.4), radius: 8, x: 0, y: 5)
                                }
                                .disabled(!plateService.isValidUKPlate(licensePlate))
                                .opacity(plateService.isValidUKPlate(licensePlate) ? 1.0 : 0.7)
                                .padding(.horizontal, 20)
                                .alert(isPresented: $showValidationAlert) {
                                    Alert(
                                        title: Text("Invalid License Plate"),
                                        message: Text("Please enter a valid UK license plate format."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color("SecondaryColor").opacity(0.2))
                                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                            )
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Account section for non-logged in users
                            if plateService.authState == .loggedOut {
                                VStack(spacing: 15) {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color("PrimaryColor"))
                                            )
                                        
                                        Text("Save Your Searches")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color("TextColor"))
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    Text("Create an account to save your license plates and access them from any device")
                                        .font(.subheadline)
                                        .foregroundColor(Color("TextColor").opacity(0.8))
                                        .multilineTextAlignment(.leading)
                                        .padding(.horizontal)
                                    
                                    Button(action: {
                                        // Direct to register screen instead of profile/login
                                        NotificationCenter.default.post(name: Notification.Name("NavigateToRegister"), object: nil)
                                    }) {
                                        HStack {
                                            Image(systemName: "person.crop.circle.badge.plus")
                                            Text("Create Account")
                                        }
                                        .font(.headline)
                                        .foregroundColor(Color("PrimaryColor"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color("SecondaryColor").opacity(0.2))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color("PrimaryColor"), lineWidth: 1)
                                        )
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                }
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color("SecondaryColor").opacity(0.2))
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                                .padding(.horizontal)
                            }
                            
                            // Saved plates section
                            if !plateService.savedPlates.isEmpty {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Text("Recent Searches")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color("TextColor"))
                                        
                                        Spacer()
                                        
                                        Text("\(plateService.savedPlates.count)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 5)
                                            .background(Color("PrimaryColor"))
                                            .clipShape(Capsule())
                                    }
                                    .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(plateService.savedPlates, id: \.self) { plate in
                                                Button(action: {
                                                    licensePlate = plate
                                                }) {
                                                    VStack(spacing: 8) {
                                                        Text(plate)
                                                            .font(.system(size: 18, weight: .bold))
                                                            .foregroundColor(Color("TextColor"))
                                                            .padding(.horizontal, 15)
                                                            .padding(.vertical, 8)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .fill(Color("SecondaryColor"))
                                                            )
                                                        
                                                        Text("Tap to search")
                                                            .font(.caption)
                                                            .foregroundColor(Color("TextColor").opacity(0.8))
                                                    }
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 15)
                                                            .fill(Color("SecondaryColor").opacity(0.3))
                                                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                                    )
                                                }
                                                .contextMenu {
                                                    Button(role: .destructive, action: {
                                                        plateService.removeSavedPlate(plate)
                                                    }) {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 5)
                                    }
                                }
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color("SecondaryColor").opacity(0.2))
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                                .padding(.horizontal)
                            }
                            
                            // App info card
                            HomeInfoCard()
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 50)
                    }
                }
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: onProfile) {
                        HStack(spacing: 8) {
                            Image(systemName: plateService.currentUser?.profileImageName ?? "person.circle")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PrimaryColor"))
                            
                            if plateService.authState == .loggedIn {
                                Text(plateService.currentUser?.name.components(separatedBy: " ").first ?? "Profile")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color("TextColor"))
                            }
                        }
                        .padding(6)
                        .background(
                            Capsule()
                                .fill(Color("SecondaryColor").opacity(0.3))
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                    },
                    trailing: Button(action: onSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color("SecondaryColor").opacity(0.3))
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                            )
                    }
                )
                .alert(isPresented: Binding<Bool>(
                    get: { plateService.errorMessage != nil },
                    set: { if !$0 { plateService.errorMessage = nil } }
                )) {
                    Alert(
                        title: Text("Error"),
                        message: Text(plateService.errorMessage ?? "Unknown error"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
}

// Info card component for home screen (redesigned)
struct HomeInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("PrimaryColor"))
                
                Text("About ClearFine")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextColor"))
            }
            
            Text("Quickly check if your vehicle has any outstanding fines or penalties registered in the UK system.")
                .font(.subheadline)
                .foregroundColor(Color("TextColor").opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 30) {
                VStack(spacing: 5) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("PrimaryColor"))
                    Text("Fast Results")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("TextColor"))
                }
                
                VStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("PrimaryColor"))
                    Text("Secure")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("TextColor"))
                }
                
                VStack(spacing: 5) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("PrimaryColor"))
                    Text("Reliable")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("TextColor"))
                }
            }
            .padding(.top, 5)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color("SecondaryColor").opacity(0.2))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Loading Screen
struct LoadingScreen: View {
    let plate: String
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background with gradients
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("Background"),
                    Color("Background"),
                    Color("SecondaryColor").opacity(0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Background decorative elements
            GeometryReader { geo in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.1)
                    .blur(radius: 50)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                            startPoint: .bottomTrailing,
                            endPoint: .topLeading
                        )
                    )
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.8)
                    .blur(radius: 50)
            }
            
            VStack(spacing: 40) {
                // Logo (smaller version)
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140)
                    .opacity(0.9)
                
                // Animated loading indicator
                ZStack {
                    // Pulse effect circles
                    Circle()
                        .fill(Color("PrimaryColor").opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.2 : 0.6)
                    
                    Circle()
                        .fill(Color("PrimaryColor").opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    // Rotating loading indicator
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    
                    // Center icon
                    Image(systemName: "car.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.8)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
                .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 15, x: 0, y: 5)
                .onAppear {
                    // Start animations
                    withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                    
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }
                
                VStack(spacing: 20) {
                    // License plate display
                    VStack(spacing: 5) {
                        Text("Checking plate")
                            .font(.headline)
                            .foregroundColor(Color("TextColor"))
                        
                        Text(plate)
                            .font(.system(size: 26, weight: .bold))
                            .kerning(1)
                            .foregroundColor(Color("SecondaryColor"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("TextColor"))
                                        
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color("SecondaryColor").opacity(0.5), lineWidth: 1)
                                }
                            )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color("SecondaryColor").opacity(0.2))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    
                    Text("Please wait while we search for penalties")
                        .font(.subheadline)
                        .foregroundColor(Color("TextColor").opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Some additional information to make the screen more engaging
                    VStack(spacing: 15) {
                        Text("Did you know?")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryColor"))
                        
                        Text("You can save license plates in ClearFine for quick and easy checking in the future.")
                            .font(.caption)
                            .foregroundColor(Color("TextColor").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color("SecondaryColor").opacity(0.2))
                    )
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
            }
        }
    }
}

// MARK: - Results Screen
struct ResultsScreen: View {
    let result: SearchResult
    let onBackToSearch: () -> Void
    let onSavePlate: () -> Void
    let onViewVehicleDetails: () -> Void
    
    @State private var isAnimating = false
    @State private var showSavedConfirmation = false
    
    var body: some View {
        ZStack {
            // Background with gradients and decorative elements
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("Background"),
                    Color("Background"),
                    Color("SecondaryColor").opacity(0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Background decorative elements - matching home page style
            GeometryReader { geo in
                // Top right circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                result.hasFines ? Color.red.opacity(0.3) : Color("PrimaryColor").opacity(0.3),
                                result.hasFines ? Color.red.opacity(0.1) : Color("PrimaryColor").opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.05)
                    .blur(radius: 50)
                
                // Bottom left circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                result.hasFines ? Color.orange.opacity(0.3) : Color("PrimaryColor").opacity(0.3),
                                result.hasFines ? Color.orange.opacity(0.1) : Color("PrimaryColor").opacity(0.1)
                            ]),
                            startPoint: .bottomTrailing,
                            endPoint: .topLeading
                        )
                    )
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.85)
                    .blur(radius: 50)
            }
            
            ScrollView {
                VStack(spacing: 25) {
                    // Logo (small version)
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .padding(.top, 20)
                    
                    // Result header
                    VStack(spacing: 20) {
                        // License plate display
                        VStack(spacing: 5) {
                            Text("UK License Plate")
                                .font(.subheadline)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                            
                            Text(result.plate)
                                .font(.system(size: 32, weight: .bold))
                                .kerning(2)
                                .foregroundColor(Color("SecondaryColor"))
                                .padding(.horizontal, 25)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color("TextColor"))
                                            
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("SecondaryColor").opacity(0.5), lineWidth: 2)
                                    }
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("SecondaryColor").opacity(0.2))
                                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
                        )
                        .padding(.horizontal, 30)

                        // Results status
                        ZStack {
                            // Background circles
                            Circle()
                                .fill(result.hasFines ? Color.red.opacity(0.1) : Color("PrimaryColor").opacity(0.1))
                                .frame(width: 130, height: 130)
                            
                            Circle()
                                .fill(result.hasFines ? Color.red.opacity(0.2) : Color("PrimaryColor").opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            // Icon
                            Image(systemName: result.hasFines ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(result.hasFines ? .red : Color("PrimaryColor"))
                                .opacity(isAnimating ? 1 : 0)
                                .scaleEffect(isAnimating ? 1 : 0.5)
                                .shadow(color: (result.hasFines ? Color.red : Color("PrimaryColor")).opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.top, 10)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                isAnimating = true
                            }
                        }
                        
                        // Result status text
                        Text(result.hasFines ? "Penalties Found" : "All Clear")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(result.hasFines ? .red : Color("PrimaryColor"))
                            .shadow(color: (result.hasFines ? Color.red : Color("PrimaryColor")).opacity(0.2), radius: 2, x: 0, y: 1)

                        // Summary line
                        Text(result.hasFines ? "You have \(result.fines.count) outstanding fine\(result.fines.count > 1 ? "s" : "")" : "No registered penalties found")
                            .font(.headline)
                            .foregroundColor(Color("TextColor"))
                            .padding(.top, -10)
                            .padding(.bottom, 10)
                    }
                    .padding(.vertical, 20)
                    
                    // Results details
                    if result.hasFines {
                        FineDetailsList(fines: result.fines)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 25) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("PrimaryColor"))
                                .padding(25)
                                .background(
                                    Circle()
                                        .fill(Color("PrimaryColor").opacity(0.1))
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 15) {
                                Text("Things are looking good :)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("TextColor"))
                                
                                Text("No Current registered Penalties for your vehicle")
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextColor").opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color("SecondaryColor").opacity(0.2))
                                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Vehicle summary card
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "car.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color("PrimaryColor"))
                                )
                            
                            Text("Vehicle Information")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color("TextColor"))
                            
                            Spacer()
                            
                            Button(action: onViewVehicleDetails) {
                                Text("View Details")
                                    .font(.subheadline)
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                        }
                        
                        // Basic vehicle info preview
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(result.vehicle.year) \(result.vehicle.make)")
                                    .font(.headline)
                                    .foregroundColor(Color("TextColor"))
                                
                                Text("\(result.vehicle.model) • \(result.vehicle.color)")
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextColor").opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("PrimaryColor"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                        )
                        .onTapGesture {
                            onViewVehicleDetails()
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color("SecondaryColor").opacity(0.2))
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
                    )
                    .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        Button(action: onBackToSearch) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Check Another Plate")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: Color("PrimaryColor").opacity(0.4), radius: 8, x: 0, y: 5)
                        }
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                onSavePlate()
                                showSavedConfirmation = true
                                
                                // Hide confirmation after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showSavedConfirmation = false
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Save Plate")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.2))
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("PrimaryColor"), lineWidth: 2)
                                )
                            }
                            
                            Button(action: onViewVehicleDetails) {
                                HStack(spacing: 12) {
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Vehicle Details")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.2))
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("PrimaryColor"), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 15)
                    .padding(.bottom, 30)
                }
            }
            
            // Saved confirmation toast
            if showSavedConfirmation {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("License plate saved!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color("PrimaryColor"))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showSavedConfirmation)
                }
            }
        }
        .navigationBarTitle("Results", displayMode: .inline)
    }
}

// Fines list component for results screen
struct FineDetailsList: View {
    let fines: [Fine]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Text("Penalty Details")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                Text("\(fines.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 5)
            
            VStack(spacing: 20) {
                ForEach(fines) { fine in
                    FineItem(fine: fine)
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color("SecondaryColor").opacity(0.2))
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
    }
}

// Fine item component
struct FineItem: View {
    let fine: Fine
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { 
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    // Fine type icon
                    Image(systemName: getFineIcon(for: fine.type))
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getFineColor(for: fine.type))
                        )
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(fine.type)
                            .font(.headline)
                            .foregroundColor(Color("TextColor"))
                        
                        Text(fine.date)
                            .font(.subheadline)
                            .foregroundColor(Color("TextColor").opacity(0.7))
                    }
                    .padding(.leading, 5)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("£\(Int(fine.amount))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.red)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color("TextColor").opacity(0.5))
                            .padding(5)
                    }
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    Divider()
                        .background(Color("SecondaryColor"))
                        .padding(.vertical, 5)
                    
                    HStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(icon: "mappin.circle.fill", title: "Location", value: fine.location)
                            DetailRow(icon: "clock.fill", title: "Status", value: fine.status.rawValue, valueColor: fine.status == .unpaid ? .red : .orange)
                        }
                    }
                    
                    HStack(spacing: 25) {
                        DetailRow(icon: "number", title: "Reference", value: fine.reference)
                        DetailRow(icon: "calendar", title: "Issued", value: fine.date)
                    }
                    
                    HStack(spacing: 15) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("View Details")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("PrimaryColor"), lineWidth: 1)
                            )
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("Pay Now")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("PrimaryColor"))
                            )
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.top, 5)
                .padding(.horizontal, 5)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("SecondaryColor").opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("SecondaryColor").opacity(0.15))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
    }
    
    // Helper to get icon for fine type
    private func getFineIcon(for type: String) -> String {
        switch type.lowercased() {
        case _ where type.contains("parking"):
            return "p.square.fill"
        case _ where type.contains("congestion"):
            return "c.square.fill"
        case _ where type.contains("speed"):
            return "speedometer"
        case _ where type.contains("red light"):
            return "light.beacon.max.fill"
        case _ where type.contains("bus lane"):
            return "bus.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    // Helper to get color for fine type
    private func getFineColor(for type: String) -> Color {
        switch type.lowercased() {
        case _ where type.contains("parking"):
            return Color.blue
        case _ where type.contains("congestion"):
            return Color.purple
        case _ where type.contains("speed"):
            return Color.red
        case _ where type.contains("red light"):
            return Color.orange
        case _ where type.contains("bus lane"):
            return Color.green
        default:
            return Color.gray
        }
    }
}

// Helper component for fine details
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = Color("TextColor")
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("PrimaryColor"))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color("SecondaryColor"))
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(valueColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Screen
struct SettingsScreen: View {
    let onBack: () -> Void
    @State private var isDarkMode = false
    @State private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Background"),
                        Color("Background"),
                        Color("SecondaryColor").opacity(0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Background decorative elements
                GeometryReader { geo in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.05)
                        .blur(radius: 50)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.85)
                        .blur(radius: 50)
                }
                
                // Settings content
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120)
                            .padding(.top, 20)
                        
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Settings")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("TextColor"))
                                
                                Text("Customize your app experience")
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextColor").opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "gearshape.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Appearance section
                        SettingsSection(title: "Appearance", icon: "paintbrush.fill", iconColor: Color("PrimaryColor")) {
                            Toggle("Dark Mode", isOn: $isDarkMode)
                                .padding()
                                .background(Color("SecondaryColor").opacity(0.2))
                                .cornerRadius(15)
                                .onChange(of: isDarkMode) { _ in
                                    // In a real app, this would change the app theme
                                }
                            
                            ColorThemeSelector()
                                .padding()
                                .background(Color("SecondaryColor").opacity(0.2))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        // Notifications section
                        SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: Color("PrimaryColor")) {
                            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                                .padding()
                                .background(Color("SecondaryColor").opacity(0.2))
                                .cornerRadius(15)
                            
                            if notificationsEnabled {
                                NavigationLink(destination: NotificationPreferencesView()) {
                                    HStack {
                                        Text("Notification Preferences")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.gray.opacity(0.5))
                                    }
                                    .padding()
                                    .background(Color("SecondaryColor").opacity(0.2))
                                    .cornerRadius(15)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // About section
                        SettingsSection(title: "About", icon: "info.circle.fill", iconColor: Color("PrimaryColor")) {
                            NavigationLink(destination: PrivacyPolicyView()) {
                                SettingsRow(title: "Privacy Policy", icon: "lock.shield.fill")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: TermsOfServiceView()) {
                                SettingsRow(title: "Terms of Service", icon: "doc.text.fill")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: ContactSupportView()) {
                                SettingsRow(title: "Contact Support", icon: "bubble.left.fill")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            HStack {
                                Text("App Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color("SecondaryColor").opacity(0.2))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        // App credits
                        VStack(spacing: 10) {
                            Text("ClearFine")
                                .font(.headline)
                                .foregroundColor(Color("TextColor"))
                            
                            Text("UK License Plate Fine Checker")
                                .font(.caption)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                            
                            Image(systemName: "car.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color("PrimaryColor"))
                                .padding(.top, 5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("SecondaryColor").opacity(0.2))
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color("PrimaryColor"))
                .padding(10)
                .background(
                    Capsule()
                        .fill(Color("SecondaryColor").opacity(0.3))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            })
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
        }
        .accentColor(Color("PrimaryColor"))
    }
}

// Settings section component
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor)
                    )
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextColor"))
            }
            
            VStack(spacing: 15) {
                content
            }
        }
        .padding(.vertical, 15)
    }
}

// Settings row component
struct SettingsRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("PrimaryColor"))
                .frame(width: 25)
            
            Text(title)
                .foregroundColor(Color("TextColor"))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding()
        .background(Color("SecondaryColor").opacity(0.2))
        .cornerRadius(15)
    }
}

// Color theme selector component
struct ColorThemeSelector: View {
    let themes: [(name: String, color: Color)] = [
        ("Green", Color("PrimaryColor")),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Orange", .orange),
        ("Red", .red)
    ]
    
    @State private var selectedTheme = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color Theme")
                .foregroundColor(Color("TextColor"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(0..<themes.count, id: \.self) { index in
                        Circle()
                            .fill(themes[index].color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color("TextColor"), lineWidth: 2)
                                    .padding(2)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(selectedTheme == index ? 1 : 0)
                            )
                            .onTapGesture {
                                selectedTheme = index
                            }
                    }
                }
                .padding(.vertical, 5)
            }
        }
    }
}

// Placeholder views for navigation
struct NotificationPreferencesView: View {
    var body: some View {
        Text("Notification Preferences")
            .navigationBarTitle("Notifications", displayMode: .inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("Terms of Service")
            .navigationBarTitle("Terms of Service", displayMode: .inline)
    }
}

struct ContactSupportView: View {
    var body: some View {
        Text("Contact Support")
            .navigationBarTitle("Contact Support", displayMode: .inline)
    }
}

// MARK: - Vehicle Details Screen
struct VehicleDetailsScreen: View {
    let vehicle: Vehicle
    let plate: String
    let onBack: () -> Void
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background with gradients
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("Background"),
                    Color("Background"),
                    Color("SecondaryColor").opacity(0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Background decorative elements
            GeometryReader { geo in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.05)
                    .blur(radius: 50)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                            startPoint: .bottomTrailing,
                            endPoint: .topLeading
                        )
                    )
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.85)
                    .blur(radius: 50)
            }
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(10)
                        .background(
                            Capsule()
                                .fill(Color("SecondaryColor").opacity(0.3))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    }
                    
                    Spacer()
                    
                    // Logo (small version)
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                }
                .padding(.horizontal)
                .padding(.top, 15)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // License plate display
                        VStack(spacing: 5) {
                            Text("UK License Plate")
                                .font(.subheadline)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                            
                            Text(plate)
                                .font(.system(size: 32, weight: .bold))
                                .kerning(2)
                                .foregroundColor(Color("SecondaryColor"))
                                .padding(.horizontal, 25)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color("TextColor"))
                                            
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("SecondaryColor").opacity(0.5), lineWidth: 2)
                                    }
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("SecondaryColor").opacity(0.2))
                                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
                        )
                        .padding(.horizontal, 30)
                        
                        // Vehicle title
                        VStack(spacing: 5) {
                            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color("TextColor"))
                                .multilineTextAlignment(.center)
                            
                            Text(vehicle.color)
                                .font(.headline)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                        }
                        .padding(.top, 10)
                        
                        // Vehicle illustration
                        ZStack {
                            Circle()
                                .fill(Color("PrimaryColor").opacity(0.1))
                                .frame(width: 200, height: 200)
                            
                            Image(systemName: "car.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120)
                                .foregroundColor(Color("PrimaryColor"))
                                .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.vertical, 20)
                        
                        // Vehicle information tabs
                        VStack(spacing: 20) {
                            // Tab selector
                            HStack(spacing: 0) {
                                TabButton(title: "Details", isSelected: selectedTab == 0) {
                                    withAnimation { selectedTab = 0 }
                                }
                                
                                TabButton(title: "Status", isSelected: selectedTab == 1) {
                                    withAnimation { selectedTab = 1 }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color("SecondaryColor").opacity(0.2))
                            )
                            .padding(.horizontal)
                            
                            // Tab content
                            if selectedTab == 0 {
                                // Vehicle details tab
                                VStack(spacing: 15) {
                                    InfoRow(title: "Make", value: vehicle.make)
                                    InfoRow(title: "Model", value: vehicle.model)
                                    InfoRow(title: "Year", value: "\(vehicle.year)")
                                    InfoRow(title: "Color", value: vehicle.color)
                                    InfoRow(title: "Registration Date", value: vehicle.registrationDate)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                                .padding(.horizontal)
                            } else {
                                // Vehicle status tab
                                VStack(spacing: 20) {
                                    StatusCard(
                                        title: "Tax Status",
                                        status: vehicle.taxStatus,
                                        icon: "doc.text.fill",
                                        isValid: vehicle.taxStatus == "Valid"
                                    )
                                    
                                    StatusCard(
                                        title: "MOT Status",
                                        status: vehicle.motStatus,
                                        icon: "checkmark.shield.fill",
                                        isValid: vehicle.motStatus == "Valid",
                                        subtitle: "Expires: \(vehicle.motExpiryDate)"
                                    )
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Actions section
                        VStack(spacing: 15) {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "printer.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Export Vehicle Report")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(color: Color("PrimaryColor").opacity(0.4), radius: 8, x: 0, y: 5)
                            }
                            
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Set MOT/Tax Reminders")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.2))
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("PrimaryColor"), lineWidth: 2)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 15)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }
}

// Tab button component for vehicle details screen
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color("TextColor").opacity(0.7))
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
                .background(
                    isSelected ?
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color("PrimaryColor"))
                        .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 5, x: 0, y: 3)
                    : nil
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Info row component for vehicle details
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color("TextColor").opacity(0.7))
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
    }
}

// Status card component for vehicle status
struct StatusCard: View {
    let title: String
    let status: String
    let icon: String
    let isValid: Bool
    var subtitle: String? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    Circle()
                        .fill(isValid ? Color("PrimaryColor") : Color.red)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))
                
                Text(status)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? Color("PrimaryColor") : Color.red)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color("TextColor").opacity(0.7))
                }
            }
            
            Spacer()
            
            // Status indicator
            Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isValid ? Color("PrimaryColor") : Color.red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isValid ? Color("PrimaryColor").opacity(0.1) : Color.red.opacity(0.1))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
    }
}

// MARK: - Profile Screen
struct ProfileScreen: View {
    let onBack: () -> Void
    let onLogout: () -> Void
    
    @ObservedObject private var plateService = PlateService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Background"),
                        Color("Background"),
                        Color("SecondaryColor").opacity(0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Background decorative elements
                GeometryReader { geo in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.05)
                        .blur(radius: 50)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.85)
                        .blur(radius: 50)
                }
                
                // Profile content
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120)
                            .padding(.top, 20)
                        
                        // Profile header
                        VStack(spacing: 20) {
                            // Profile image
                            Image(systemName: plateService.currentUser?.profileImageName ?? "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Color("PrimaryColor"))
                                .padding(20)
                                .background(
                                    Circle()
                                        .fill(Color("SecondaryColor").opacity(0.2))
                                )
                            
                            // User info
                            if let user = plateService.currentUser {
                                Text(user.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color("TextColor"))
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextColor").opacity(0.7))
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Saved vehicles section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Saved License Plates")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("TextColor"))
                                
                                Spacer()
                                
                                if let user = plateService.currentUser {
                                    Text("\(user.savedPlates.count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(Color("PrimaryColor"))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                            
                            if let user = plateService.currentUser, !user.savedPlates.isEmpty {
                                ForEach(user.savedPlates, id: \.self) { plate in
                                    SavedPlateRow(plate: plate)
                                }
                            } else {
                                VStack(spacing: 15) {
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color("PrimaryColor").opacity(0.5))
                                        .padding(20)
                                    
                                    Text("No saved license plates")
                                        .font(.headline)
                                        .foregroundColor(Color("TextColor").opacity(0.7))
                                    
                                    Text("When you save a license plate, it will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(Color("TextColor").opacity(0.5))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            }
                        }
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color("SecondaryColor").opacity(0.2))
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        // Account actions
                        VStack(spacing: 15) {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text("Edit Profile")
                                }
                                .font(.headline)
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.2))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("PrimaryColor"), lineWidth: 1)
                                )
                            }
                            
                            Button(action: onLogout) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                    Text("Log Out")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.red.opacity(0.8))
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitle("My Profile", displayMode: .inline)
            .navigationBarItems(leading: Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color("PrimaryColor"))
                .padding(10)
                .background(
                    Capsule()
                        .fill(Color("SecondaryColor").opacity(0.3))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            })
        }
        .accentColor(Color("PrimaryColor"))
    }
}

// Saved plate row component for profile screen
struct SavedPlateRow: View {
    let plate: String
    @ObservedObject private var plateService = PlateService.shared
    
    var body: some View {
        HStack {
            // License plate display
            Text(plate)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("SecondaryColor"))
                )
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 15) {
                Button(action: {
                    // Search for this plate
                    // This would navigate to the search results in a real app
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color("PrimaryColor").opacity(0.2))
                        )
                }
                
                Button(action: {
                    // Remove this plate
                    plateService.removeSavedPlate(plate)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.2))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("SecondaryColor").opacity(0.1))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
}

// MARK: - Login Screen
struct LoginScreen: View {
    let onBack: () -> Void
    let onLogin: () -> Void
    let onRegister: () -> Void
    
    @ObservedObject private var plateService = PlateService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Background"),
                        Color("Background"),
                        Color("SecondaryColor").opacity(0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Background decorative elements
                GeometryReader { geo in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.1)
                        .blur(radius: 50)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.85)
                        .blur(radius: 50)
                }
                
                // Login content
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180)
                            .padding(.top, 50)
                        
                        // Welcome text
                        VStack(spacing: 10) {
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color("TextColor"))
                            
                            Text("Sign in to access your saved license plates")
                                .font(.subheadline)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Login form
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(Color("TextColor").opacity(0.8))
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                        .font(.system(size: 18))
                                        .padding(.leading, 16)
                                    
                                    TextField("Enter your email", text: $email)
                                        .font(.system(size: 16))
                                        .padding(16)
                                        .foregroundColor(Color("TextColor"))
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .disableAutocorrection(true)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.15))
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                )
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(Color("TextColor").opacity(0.8))
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                        .font(.system(size: 18))
                                        .padding(.leading, 16)
                                    
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .font(.system(size: 16))
                                            .padding(16)
                                            .foregroundColor(Color("TextColor"))
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .font(.system(size: 16))
                                            .padding(16)
                                            .foregroundColor(Color("TextColor"))
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(Color("TextColor").opacity(0.6))
                                            .padding(.trailing, 16)
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.15))
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                )
                            }
                            
                            // Error message
                            if let error = plateService.authError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 5)
                            }
                            
                            // Login button
                            Button(action: {
                                plateService.login(email: email, password: password) { success in
                                    if success {
                                        onLogin()
                                    }
                                }
                            }) {
                                HStack {
                                    Text("Sign In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(color: Color("PrimaryColor").opacity(0.4), radius: 8, x: 0, y: 5)
                            }
                            .disabled(plateService.isLoading)
                            .opacity(plateService.isLoading ? 0.7 : 1.0)
                            .overlay(
                                Group {
                                    if plateService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    }
                                }
                            )
                            
                            // Demo login info
                            VStack(spacing: 5) {
                                Text("Demo Credentials")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("TextColor").opacity(0.7))
                                
                                Text("Email: demo@example.com\nPassword: any password will work")
                                    .font(.caption)
                                    .foregroundColor(Color("TextColor").opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        
                        // Register option
                        HStack {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                            
                            Button(action: onRegister) {
                                Text("Register")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color("PrimaryColor"))
                .padding(10)
                .background(
                    Capsule()
                        .fill(Color("SecondaryColor").opacity(0.3))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            })
        }
        .accentColor(Color("PrimaryColor"))
    }
}

// MARK: - Register Screen
struct RegisterScreen: View {
    let onBack: () -> Void
    let onRegisterSuccess: () -> Void
    
    @ObservedObject private var plateService = PlateService.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var passwordError: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Background"),
                        Color("Background"),
                        Color("SecondaryColor").opacity(0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Background decorative elements
                GeometryReader { geo in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.1)
                        .blur(radius: 50)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.1)]),
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.85)
                        .blur(radius: 50)
                }
                
                // Register content
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150)
                            .padding(.top, 30)
                        
                        // Welcome text
                        VStack(spacing: 10) {
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color("TextColor"))
                            
                            Text("Register to save your license plates")
                                .font(.subheadline)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)
                        
                        // Register form
                        VStack(spacing: 20) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.caption)
                                    .foregroundColor(Color("TextColor").opacity(0.8))
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                        .font(.system(size: 18))
                                        .padding(.leading, 16)
                                    
                                    TextField("Enter your name", text: $name)
                                        .font(.system(size: 16))
                                        .padding(16)
                                        .foregroundColor(Color("TextColor"))
                                        .disableAutocorrection(true)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.15))
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                )
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(Color("TextColor").opacity(0.8))
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                        .font(.system(size: 18))
                                        .padding(.leading, 16)
                                    
                                    TextField("Enter your email", text: $email)
                                        .font(.system(size: 16))
                                        .padding(16)
                                        .foregroundColor(Color("TextColor"))
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .disableAutocorrection(true)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.15))
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                )
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(Color("TextColor").opacity(0.8))
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                        .font(.system(size: 18))
                                        .padding(.leading, 16)
                                    
                                    if showPassword {
                                        TextField("Create a password", text: $password)
                                            .font(.system(size: 16))
                                            .padding(16)
                                            .foregroundColor(Color("TextColor"))
                                    } else {
                                        SecureField("Create a password", text: $password)
                                            .font(.system(size: 16))
                                            .padding(16)
                                            .foregroundColor(Color("TextColor"))
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(Color("TextColor").opacity(0.6))
                                            .padding(.trailing, 16)
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.15))
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                )
                            }
                            
                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.caption)
                                    .foregroundColor(Color("TextColor").opacity(0.8))
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                        .font(.system(size: 18))
                                        .padding(.leading, 16)
                                    
                                    if showConfirmPassword {
                                        TextField("Confirm your password", text: $confirmPassword)
                                            .font(.system(size: 16))
                                            .padding(16)
                                            .foregroundColor(Color("TextColor"))
                                    } else {
                                        SecureField("Confirm your password", text: $confirmPassword)
                                            .font(.system(size: 16))
                                            .padding(16)
                                            .foregroundColor(Color("TextColor"))
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(Color("TextColor").opacity(0.6))
                                            .padding(.trailing, 16)
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("SecondaryColor").opacity(0.15))
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                )
                            }
                            
                            // Error messages
                            if let error = plateService.authError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 5)
                            }
                            
                            if let error = passwordError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 5)
                            }
                            
                            // Register button
                            Button(action: {
                                // Validate passwords match
                                if password != confirmPassword {
                                    passwordError = "Passwords do not match"
                                    return
                                }
                                
                                // Clear any previous errors
                                passwordError = nil
                                
                                // Register user
                                plateService.register(email: email, name: name, password: password) { success in
                                    if success {
                                        onRegisterSuccess()
                                    }
                                }
                            }) {
                                HStack {
                                    Text("Create Account")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(color: Color("PrimaryColor").opacity(0.4), radius: 8, x: 0, y: 5)
                            }
                            .disabled(plateService.isLoading || name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                            .opacity((plateService.isLoading || name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) ? 0.7 : 1.0)
                            .overlay(
                                Group {
                                    if plateService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        
                        // Back to login
                        HStack {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundColor(Color("TextColor").opacity(0.7))
                            
                            Button(action: onBack) {
                                Text("Sign In")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color("PrimaryColor"))
                .padding(10)
                .background(
                    Capsule()
                        .fill(Color("SecondaryColor").opacity(0.3))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            })
        }
        .accentColor(Color("PrimaryColor"))
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
