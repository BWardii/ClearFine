# ClearFine: UK License Plate Fine Checker

ClearFine is an iOS application that allows users to check if their UK vehicle has any outstanding fines or penalties by entering their license plate number.

## Features

- **Simple License Plate Search**: Quickly check for fines by entering a UK license plate
- **Real-time Results**: Instant feedback on whether a vehicle has outstanding fines
- **Fine Details**: View comprehensive information about each fine including type, amount, date, and location
- **Vehicle Information**: Access detailed vehicle data including make, model, year, and MOT/tax status
- **Saved Plates**: Save license plates for quick access to frequently checked vehicles
- **Modern UI**: Clean, intuitive interface designed specifically for iOS

## Screens

### Splash Screen
- Displays the app logo and name
- Auto-transitions to the Home screen after 2-3 seconds

### Home Screen
- Search functionality for license plate entry
- Recently searched plates list
- Information about the app's purpose

### Results Screen
- Clear visual indication of results (green for no fines, red for fines)
- Detailed list of fines with expandable information
- Vehicle summary information
- Options to save the license plate, check another one, or view vehicle details

### Vehicle Details Screen
- Comprehensive vehicle information including make, model, year, and color
- Registration details and history
- MOT and tax status with expiry dates
- Options to export vehicle reports or set reminders for MOT/tax renewals

### Settings Screen
- App preferences
- Notification settings
- Privacy policy and terms of service
- Contact support

## Technical Implementation

The app is built using:
- Swift and SwiftUI for the UI
- MVVM architecture pattern
- UserDefaults for local storage of saved plates
- Modern iOS design patterns and components

## Building and Running

### Requirements
- Xcode 14.0 or later
- iOS 16.0 or later (target deployment)
- Swift 5.7 or later

### Steps
1. Clone the repository
2. Open `FineDemo.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run (⌘+R)

## Future Enhancements

- Backend API integration for real fine data
- Push notifications for fine updates
- Dark mode support
- History of previous searches
- Detailed fine payment options
- Vehicle history reports
- MOT and tax renewal reminders

## License

This project is for demonstration purposes only. 