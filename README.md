# SpendWise

SpendWise is a SwiftUI iOS personal-finance app for recording expenses, setting monthly and category budgets, viewing spending insights, and synchronizing financial data with Firebase.

## Features

- Email/password registration and sign-in with Firebase Authentication
- Local-first expense recording with Core Data
- Firestore synchronization for expenses, monthly budgets, and category budgets
- Offline retry support for pending expense uploads and deletions
- Receipt attachment, camera capture, and on-device receipt-text extraction
- Optional location capture for expenses and map-based expense views
- Monthly and category budget tracking with threshold notifications
- Spending insights, charts, and a Core ML-assisted end-of-month forecast
- Optional Face ID protection and daily expense reminders

## Technology

| Area | Used technology |
| --- | --- |
| Interface | SwiftUI |
| Language | Swift 5 |
| Local persistence | Core Data |
| Authentication and cloud sync | Firebase Authentication and Cloud Firestore |
| Dependencies | Swift Package Manager |
| Receipt scanning | Vision |
| Location and maps | Core Location and MapKit |
| Notifications | UserNotifications |
| Forecasting | Core ML |
| Tests | XCTest |

## Repository structure

```text
SpendWise/
  App/             Application entry point, root flow, onboarding, app state
  Views/           SwiftUI screens grouped by feature
  ViewModels/      Expense and budget presentation/business logic
  Services/        Firebase, Firestore, Core Data, OCR, location, notifications, biometrics, prediction
  Models/          Generated Core Data managed-object classes
  Persistence/     Core Data model
  Utilities/       Validation, sync monitoring, network monitoring, receipt parsing
  ML/              Core ML models and model training/evaluation data
  Resources/       Assets and Firebase configuration
SpendWiseTests/    XCTest unit tests
docs/              User manual and screenshot guide
```

## Prerequisites

- macOS with Xcode that supports the project's configured iOS SDK and deployment target (`iOS 26.2` at the time of writing)
- An Apple ID/team for running on a physical device
- A Firebase project with Email/Password Authentication and Cloud Firestore enabled
- An iPhone simulator or physical iPhone; a physical device is required to test camera, Face ID, location, and notifications fully

## Set up the project

1. Clone the repository.

   ```bash
   git clone <repository-url>
   cd SpendWise
   ```

2. Obtain the iOS Firebase configuration for your Firebase project.

   - Register an iOS app whose bundle identifier matches the Xcode target.
   - Download `GoogleService-Info.plist` from Firebase.
   - Replace `SpendWise/GoogleService-Info.plist` with your own configuration when using a separate Firebase environment.
   - In Firebase Console, enable **Authentication > Sign-in method > Email/Password** and create a **Cloud Firestore** database.

3. Open [SpendWise.xcodeproj](SpendWise.xcodeproj) in Xcode.

4. Allow Xcode to resolve the Swift Package Manager dependencies. The project uses Firebase Core, Authentication, and Firestore; locked package versions are stored in `Package.resolved`.

5. Select the **SpendWise** scheme and an iOS simulator or a signed physical device.

6. Build and run with **Product > Run** (`Cmd + R`).

## Build from the command line

Run these commands from the repository root on macOS with Xcode installed:

```bash
xcodebuild \
  -project SpendWise.xcodeproj \
  -scheme SpendWise \
  -sdk iphonesimulator \
  -configuration Debug \
  build
```

To run the unit tests on an available simulator, first list available destinations:

```bash
xcodebuild -project SpendWise.xcodeproj -scheme SpendWise -showdestinations
```

Then substitute a valid simulator name in this command:

```bash
xcodebuild \
  -project SpendWise.xcodeproj \
  -scheme SpendWise \
  -destination 'platform=iOS Simulator,name=<simulator-name>' \
  test
```

## Required iOS permissions

SpendWise uses protected device features. Before release, ensure the app target's `Info.plist` contains clear user-facing purpose strings for:

- `NSCameraUsageDescription` for receipt photos
- `NSLocationWhenInUseUsageDescription` for saving an expense location
- `NSFaceIDUsageDescription` for Face ID protection

Also test notification authorization when enabling daily reminders. See [PROJECT_REVIEW.md](PROJECT_REVIEW.md) for the full release-readiness review.

## Firebase and data security

- Store Firestore records under the authenticated user's `users/{uid}` path.
- Configure Firestore Security Rules so authenticated users can access only their own data. Client-side ownership checks are not sufficient security controls.
- Restrict the Firebase API key in Google Cloud to the app's bundle identifier and expected services.
- Do not commit service-account keys, Firestore admin credentials, or other server secrets.

The checked-in `GoogleService-Info.plist` is mobile-client configuration, not a server secret. Use a separate Firebase project/configuration for development, staging, and production where appropriate.

## Test coverage

The XCTest target currently covers input validation, downloaded-record validation, and Firebase authentication error mapping. Run tests from Xcode with `Cmd + U` or with the command shown above.

Recommended additions include Core Data integration tests, Firestore Emulator security/sync tests, offline retry tests, and UI tests for the primary user journeys.

## Documentation

- [User Manual](docs/USER_MANUAL.md)

## Development notes

- The app uses LKR/Rs. as its display currency.
- Core Data is the local source used by the interface; Firestore synchronization runs after relevant changes and can also be triggered from **Settings > Sync Now**.
- Test the camera, Face ID, location, notification, and synchronization behavior on a physical device before release.
