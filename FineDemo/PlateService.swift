import Foundation

// MARK: - Models

/// Model representing a user profile
struct User: Codable, Identifiable {
    let id: String
    var email: String
    var name: String
    var savedPlates: [String]
    var profileImageName: String?
    
    init(id: String = UUID().uuidString, email: String, name: String, savedPlates: [String] = [], profileImageName: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.savedPlates = savedPlates
        self.profileImageName = profileImageName
    }
}

/// Model representing fine details
struct Fine: Identifiable, Codable {
    let id: String
    let date: String
    let type: String
    let amount: Double
    let location: String
    let status: FineStatus
    let reference: String
    
    // For demo purposes, initializer with main properties
    init(id: String, date: String, type: String, amount: Double, location: String, 
         status: FineStatus = .unpaid, reference: String = "") {
        self.id = id
        self.date = date
        self.type = type
        self.amount = amount
        self.location = location
        self.status = status
        self.reference = reference.isEmpty ? "PCN\(id)UK" : reference
    }
}

/// Enum for fine status
enum FineStatus: String, Codable {
    case unpaid = "Unpaid"
    case paid = "Paid"
    case disputed = "Disputed"
    case processing = "Processing"
}

/// Authentication state enum
enum AuthState {
    case loggedOut
    case loggedIn
    case registering
}

/// Model representing vehicle details
struct Vehicle: Codable {
    let make: String
    let model: String
    let color: String
    let year: Int
    let registrationDate: String
    let taxStatus: String
    let motStatus: String
    let motExpiryDate: String
    
    // For demo purposes
    static func sample(for plate: String) -> Vehicle {
        // Generate consistent but seemingly random vehicle details based on the plate string
        // This ensures the same plate always returns the same vehicle
        let hashValue = plate.hash
        
        let makes = ["Ford", "Toyota", "Volkswagen", "BMW", "Mercedes", "Audi", "Vauxhall", "Honda", "Nissan", "Peugeot"]
        let models = ["Focus", "Corolla", "Golf", "3 Series", "C-Class", "A4", "Astra", "Civic", "Qashqai", "308"]
        let colors = ["Black", "White", "Silver", "Blue", "Red", "Grey", "Green", "Brown", "Yellow", "Orange"]
        let taxStatuses = ["Valid", "Valid", "Valid", "Expired", "Valid"]
        let motStatuses = ["Valid", "Valid", "Valid", "Expired", "Valid"]
        
        let makeIndex = abs(hashValue) % makes.count
        let modelIndex = abs(hashValue / 2) % models.count
        let colorIndex = abs(hashValue / 3) % colors.count
        let yearOffset = abs(hashValue % 15) // 0-14 years old
        let currentYear = Calendar.current.component(.year, from: Date())
        let year = currentYear - yearOffset
        
        // Generate registration date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let registrationDate = dateFormatter.string(from: Calendar.current.date(byAdding: .year, value: -yearOffset, to: Date()) ?? Date())
        
        // MOT expiry date (1 year from now, or expired)
        let taxStatusIndex = abs(hashValue / 4) % taxStatuses.count
        let motStatusIndex = abs(hashValue / 5) % motStatuses.count
        
        let motExpiryOffset = motStatuses[motStatusIndex] == "Valid" ? 1 : -1
        let motExpiryDate = dateFormatter.string(from: Calendar.current.date(byAdding: .year, value: motExpiryOffset, to: Date()) ?? Date())
        
        return Vehicle(
            make: makes[makeIndex],
            model: models[modelIndex],
            color: colors[colorIndex],
            year: year,
            registrationDate: registrationDate,
            taxStatus: taxStatuses[taxStatusIndex],
            motStatus: motStatuses[motStatusIndex],
            motExpiryDate: motExpiryDate
        )
    }
}

/// Service for validating and checking license plates
class PlateService: ObservableObject {
    // Published properties for UI binding
    @Published var isLoading = false
    @Published var searchResult: SearchResult?
    @Published var errorMessage: String?
    @Published var savedPlates: [String] = []
    
    // Authentication properties
    @Published var currentUser: User?
    @Published var authState: AuthState = .loggedOut
    @Published var authError: String?
    
    // Demo users for testing
    private var demoUsers: [User] = [
        User(id: "1", email: "demo@example.com", name: "Demo User", savedPlates: ["AB12 CDE", "XY34 ZWV"], profileImageName: "person.circle.fill"),
        User(id: "2", email: "test@example.com", name: "Test User", savedPlates: ["LM56 NPQ"], profileImageName: "person.fill")
    ]
    
    // Singleton instance
    static let shared = PlateService()
    
    // Private initializer
    private init() {
        // Load saved plates from UserDefaults
        if let plates = UserDefaults.standard.stringArray(forKey: "savedPlates") {
            savedPlates = plates
        }
        
        // Check for saved login
        checkForSavedLogin()
    }
    
    // MARK: - Authentication Methods
    
    /// Login with email and password
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // Simulate network delay
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            
            // Demo login - check if email matches a demo user
            if let user = self.demoUsers.first(where: { $0.email.lowercased() == email.lowercased() }) {
                // For demo, any password works
                self.currentUser = user
                self.savedPlates = user.savedPlates
                self.authState = .loggedIn
                self.authError = nil
                
                // Save login to UserDefaults
                UserDefaults.standard.set(user.id, forKey: "loggedInUserId")
                
                completion(true)
            } else {
                self.authError = "Invalid email or password"
                completion(false)
            }
        }
    }
    
    /// Register a new user
    func register(email: String, name: String, password: String, completion: @escaping (Bool) -> Void) {
        // Simulate network delay
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            
            // Check if email already exists
            if self.demoUsers.contains(where: { $0.email.lowercased() == email.lowercased() }) {
                self.authError = "Email already in use"
                completion(false)
                return
            }
            
            // Create new user
            let newUser = User(email: email, name: name, savedPlates: [])
            self.demoUsers.append(newUser)
            
            // Log in the new user
            self.currentUser = newUser
            self.savedPlates = []
            self.authState = .loggedIn
            self.authError = nil
            
            // Save login to UserDefaults
            UserDefaults.standard.set(newUser.id, forKey: "loggedInUserId")
            
            completion(true)
        }
    }
    
    /// Log out the current user
    func logout() {
        currentUser = nil
        authState = .loggedOut
        savedPlates = []
        
        // Remove saved login
        UserDefaults.standard.removeObject(forKey: "loggedInUserId")
    }
    
    /// Check for saved login
    private func checkForSavedLogin() {
        if let userId = UserDefaults.standard.string(forKey: "loggedInUserId"),
           let user = demoUsers.first(where: { $0.id == userId }) {
            currentUser = user
            savedPlates = user.savedPlates
            authState = .loggedIn
        }
    }
    
    // MARK: - Public Methods
    
    /// Validates a UK license plate format
    func isValidUKPlate(_ plate: String) -> Bool {
        // Current UK license plate format (simplified)
        // Should be between 2-7 characters, letters and numbers only
        let trimmedPlate = plate.trimmingCharacters(in: .whitespaces)
        guard trimmedPlate.count >= 2 && trimmedPlate.count <= 7 else { return false }
        
        // Only allow letters and numbers (real validation would be more complex)
        let characterSet = CharacterSet.alphanumerics
        return trimmedPlate.unicodeScalars.allSatisfy { characterSet.contains($0) }
    }
    
    /// Format a license plate (add spaces in appropriate places)
    func formatLicensePlate(_ plate: String) -> String {
        let cleaned = plate.replacingOccurrences(of: " ", with: "").uppercased()
        
        // Handle different plate formats
        // AB12CDE -> AB12 CDE
        // ABC123D -> ABC 123D
        if cleaned.count > 4 {
            let index = cleaned.index(cleaned.startIndex, offsetBy: min(4, cleaned.count - 1))
            return String(cleaned[..<index]) + " " + String(cleaned[index...])
        }
        
        return cleaned
    }
    
    /// Search for fines for a given license plate (simulated)
    func searchForFines(plate: String, completion: @escaping (Result<SearchResult, Error>) -> Void) {
        // Set loading state
        isLoading = true
        errorMessage = nil
        
        // Validate plate
        guard isValidUKPlate(plate) else {
            isLoading = false
            let error = NSError(domain: "com.clearfine.validation", 
                               code: 1, 
                               userInfo: [NSLocalizedDescriptionKey: "Invalid license plate format"])
            completion(.failure(error))
            return
        }
        
        // Check for test case
        let cleanedPlate = plate.uppercased().replacingOccurrences(of: " ", with: "")
        if cleanedPlate == "DV11DTO" {
            // Special test case
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    // Create a specific fine for the test license plate
                    let fine = Fine(
                        id: "TEST123",
                        date: "15/05/2025",
                        type: "Speeding Violation",
                        amount: 120.0,
                        location: "M25 Junction 8, Surrey",
                        status: .unpaid,
                        reference: "SPD23456UK"
                    )
                    
                    // Create a specific vehicle for the test license plate
                    let vehicle = Vehicle(
                        make: "BMW",
                        model: "5 Series",
                        color: "Black",
                        year: 2022,
                        registrationDate: "11/03/2022",
                        taxStatus: "Valid",
                        motStatus: "Valid",
                        motExpiryDate: "10/03/2026"
                    )
                    
                    let result = SearchResult(plate: "DV11 DTO", fines: [fine], vehicle: vehicle)
                    self.searchResult = result
                    completion(.success(result))
                }
            }
            return
        }
        
        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            DispatchQueue.main.async {
                self.isLoading = false
                
                // For demo purposes, randomly determine if there are fines
                let hasFines = Bool.random()
                var result: SearchResult
                
                let formattedPlate = self.formatLicensePlate(plate)
                
                if hasFines {
                    // Generate some sample fines
                    let fines = self.generateSampleFines()
                    result = SearchResult(
                        plate: formattedPlate, 
                        fines: fines,
                        vehicle: Vehicle.sample(for: formattedPlate)
                    )
                } else {
                    // No fines
                    result = SearchResult(
                        plate: formattedPlate, 
                        fines: [],
                        vehicle: Vehicle.sample(for: formattedPlate)
                    )
                }
                
                self.searchResult = result
                completion(.success(result))
            }
        }
    }
    
    /// Save a license plate for future reference
    func savePlate(_ plate: String) {
        let formattedPlate = formatLicensePlate(plate)
        
        // Check if plate already exists
        if !savedPlates.contains(formattedPlate) {
            savedPlates.append(formattedPlate)
            
            // If user is logged in, update their saved plates
            if var user = currentUser {
                if !user.savedPlates.contains(formattedPlate) {
                    user.savedPlates.append(formattedPlate)
                    
                    // Update the user in the demo users array
                    if let index = demoUsers.firstIndex(where: { $0.id == user.id }) {
                        demoUsers[index] = user
                        currentUser = user
                    }
                }
            }
            
            // Save to UserDefaults
            UserDefaults.standard.set(savedPlates, forKey: "savedPlates")
        }
    }
    
    /// Remove a saved license plate
    func removeSavedPlate(_ plate: String) {
        if let index = savedPlates.firstIndex(of: plate) {
            savedPlates.remove(at: index)
            
            // If user is logged in, update their saved plates
            if var user = currentUser {
                if let userPlateIndex = user.savedPlates.firstIndex(of: plate) {
                    user.savedPlates.remove(at: userPlateIndex)
                    
                    // Update the user in the demo users array
                    if let userIndex = demoUsers.firstIndex(where: { $0.id == user.id }) {
                        demoUsers[userIndex] = user
                        currentUser = user
                    }
                }
            }
            
            // Update UserDefaults
            UserDefaults.standard.set(savedPlates, forKey: "savedPlates")
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate sample fines for demo purposes
    private func generateSampleFines() -> [Fine] {
        // Common violation types
        let violationTypes = [
            "Parking Violation",
            "Congestion Charge",
            "Speed Camera",
            "Red Light Camera",
            "Bus Lane Violation",
            "No Stopping Zone"
        ]
        
        // Common London locations
        let locations = [
            "Oxford Street, London",
            "Piccadilly Circus, London",
            "Baker Street, London",
            "Trafalgar Square, London",
            "Camden High Street, London",
            "Tottenham Court Road, London",
            "A40, London",
            "M25 Junction 10"
        ]
        
        // Generate 1-3 random fines
        let count = Int.random(in: 1...3)
        var fines: [Fine] = []
        
        for i in 1...count {
            // Generate a random date in the last 6 months
            let randomDays = Int.random(in: 1...180)
            let date = Calendar.current.date(byAdding: .day, value: -randomDays, to: Date()) ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let dateString = dateFormatter.string(from: date)
            
            // Random amount between £30 and £150
            let amount = Double(Int.random(in: 3...15) * 10)
            
            // Random type and location
            let type = violationTypes.randomElement() ?? violationTypes[0]
            let location = locations.randomElement() ?? locations[0]
            
            // Create the fine
            let fine = Fine(
                id: "\(1000 + i)",
                date: dateString,
                type: type,
                amount: amount,
                location: location
            )
            
            fines.append(fine)
        }
        
        return fines
    }
}

/// Search result model
struct SearchResult {
    let plate: String
    let fines: [Fine]
    let vehicle: Vehicle
    let timestamp: Date = Date()
    
    var hasFines: Bool {
        return !fines.isEmpty
    }
} 