# My Flutter Weather & AI Assistant App

## Project Overview

This is a comprehensive Flutter application designed to provide users with real-time weather forecasts, advanced weather radar visualizations, and an intelligent AI assistant. The application leverages Firebase as its backend for data storage and other cloud services, ensuring a robust and scalable solution.

## Key Features

*   **Detailed Weather Forecasts:**
    *   Current weather conditions.
    *   Hourly and weekly temperature and precipitation forecasts.
    *   Various weather indices (e.g., UV Index, Drying Index).
    *   Sunrise and sunset times.
    *   Clothing, drying, and outdoor sports advice based on weather conditions.
*   **Interactive Weather Radar:**
    *   Visualize weather patterns with different map layers (e.g., precipitation, temperature).
    *   Playback controls for historical and future radar data.
    *   AI-powered analysis of radar data.
*   **Intelligent AI Assistant:**
    *   Engage in conversations with an AI assistant.
    *   Receive personalized advice, including clothing recommendations and general weather insights.
    *   Quick question panels for common queries.
*   **Firebase Integration:**
    *   Utilizes Firebase for backend services, likely including Firestore for data storage and potentially other services like Authentication or Cloud Functions.
*   **Location Services:** Automatically fetches weather data based on the user's current location.
*   **User Settings:** Customizable settings for language, notifications, and "About" information.

## Technologies Used

*   **Flutter:** The UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
*   **Dart:** The programming language used by Flutter.
*   **Firebase:**
    *   **Firestore:** NoSQL cloud database for flexible, scalable data storage.
    *   **Firebase CLI & FlutterFire CLI:** Command-line tools for managing Firebase projects and Flutter integration.
*   **Location Services:** For accessing device location.

## Getting Started

Follow these steps to set up and run the project on your local machine.

### Prerequisites

Before you begin, ensure you have the following installed:

*   **Flutter SDK:** [Install Flutter](https://flutter.dev/docs/get-started/install)
*   **Git:** [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
*   **Firebase CLI:**
    ```bash
    curl -sL https://firebase.tools | bash
    ```
    (Or `npm install -g firebase-tools` if you have Node.js and npm installed)
*   **FlutterFire CLI:**
    ```bash
    dart pub global activate flutterfire_cli
    ```
    Ensure `~/.pub-cache/bin` is in your system's PATH.

### 1. Clone the Repository

First, clone the project repository to your local machine:

```bash
git clone YOUR_REPOSITORY_URL
cd my-flutter-weather-app # Replace with your actual project directory name
```

### 2. Install Dependencies

Navigate into the project directory and get all the necessary Dart packages:

```bash
flutter pub get
```

### 3. Firebase Project Setup (Crucial!)

Since sensitive Firebase configuration files are excluded from Git for security reasons, you'll need to set up your own Firebase project and link it to this application.

1.  **Create a Firebase Project:**
    *   Go to the [Firebase Console](https://console.firebase.google.com/).
    *   Click "Add project" and follow the instructions to create a new Firebase project.

2.  **Register Your Apps:**
    *   In your Firebase project, add an Android app and an iOS app.
    *   **For Android:**
        *   Provide your Android package name (e.g., `com.example.myapp`). You can find this in `android/app/src/main/AndroidManifest.xml` under the `package` attribute, or in `android/app/build.gradle.kts` in `applicationId`.
        *   Download the `google-services.json` file.
    *   **For iOS:**
        *   Provide your iOS Bundle ID (e.g., `com.example.myapp`). You can find this in Xcode under your project's General settings.
        *   Download the `GoogleService-Info.plist` file.

3.  **Generate `lib/firebase_options.dart`:**
    *   Make sure you are logged into Firebase CLI (`firebase login`).
    *   In your Flutter project's root directory, run the FlutterFire configuration command. This will guide you through selecting your Firebase project and automatically generate the `lib/firebase_options.dart` file and place `google-services.json` and `GoogleService-Info.plist` in their correct platform-specific locations (`android/app/` and `ios/Runner/` respectively).
    ```bash
    flutterfire configure
    ```
    *   **Verify:** After running this command, ensure that `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and `lib/firebase_options.dart` are present in their respective directories.

### 4. Run the Application

Once Firebase is configured, you can run the application on a connected device or simulator:

```bash
flutter run
```

## Project Structure

The project is organized using a feature-first approach to enhance modularity and maintainability:

```
.
├── android/                  # Android specific files
├── ios/                      # iOS specific files
├── lib/
│   ├── features/             # Contains distinct features (e.g., weather, radar, AI assistant)
│   │   ├── ai_assistant/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   ├── radar/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   ├── settings/
│   │   │   ├── screens/
│   │   │   └── utils/
│   │   └── weather/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   ├── models/               # Common data models
│   ├── services/             # Core application services (e.g., Firestore, Location)
│   ├── main.dart             # Application entry point
│   └── firebase_options.dart # Firebase configuration (auto-generated)
├── pubspec.yaml              # Project dependencies and metadata
├── README.md                 # Project documentation
├── .gitignore                # Files/directories to be ignored by Git
└── templates/                # Contains HTML templates (e.g., chat_page.dart, weather-app-showcase.html)
```

## Contributing

If you'd like to contribute to this project, please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/YourFeature`).
3.  Make your changes.
4.  Commit your changes (`git commit -m 'Add some feature'`).
5.  Push to the branch (`git push origin feature/YourFeature`).
6.  Open a Pull Request.

## License

[Specify your license here, e.g., MIT License]
