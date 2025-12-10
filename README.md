# NoteFlow – AI Voice Dictation

A production-quality Flutter mobile application for voice dictation with real-time speech-to-text, local document storage, and AI-powered summarization.

![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### 🎙️ Real-Time Dictation
- Tap to start listening
- Continuous speech recognition until you stop
- Live transcription displayed in real-time
- Auto-restart on unexpected interruptions
- Continues listening during silent pauses

### 📝 Auto-Save Documents
- Every recording session becomes a document
- Full transcript with timestamp
- Auto-generated titles ("Note — 2025-12-10 3:42 PM")
- Word count tracking

### 💾 Offline Storage
- Fast local storage using Hive
- Full offline support
- Search through all notes
- Quick access to recent notes

### 🤖 AI Summarization (Groq API)
- Generate crisp bullet summaries
- 3 action items from each note
- Uses Groq's llama3-70b-8192 model
- On-demand summarization

### 🎨 Modern UI
- Material 3 design system
- Light and dark theme support
- Responsive layout
- Smooth animations

## Screenshots

| Home Screen | Dictation | Document Detail |
|-------------|-----------|-----------------|
| Document list with search | Live recording with timer | Full transcript + AI summary |

## Getting Started

### Prerequisites

- Flutter SDK 3.38.0 or higher
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/noteflow.git
   cd noteflow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Groq API (Optional)**
   
   Get a free API key from [Groq Console](https://console.groq.com/) and add it to `.env`:
   ```
   GROQ_API_KEY=your_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

#### Android APK
```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle
```bash
flutter build appbundle
```

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── models/
│   ├── document.dart                   # Document model
│   └── document.g.dart                 # Hive adapter
├── services/
│   ├── speech_service.dart             # Speech-to-text service
│   ├── groq_service.dart               # Groq API integration
│   └── storage_service.dart            # Hive CRUD operations
├── providers/
│   └── document_provider.dart          # State management
├── screens/
│   ├── home_screen.dart                # Documents list
│   ├── dictation_screen.dart           # Live recording
│   └── document_detail_screen.dart     # View/Edit/Summarize
└── widgets/
    └── document_tile.dart              # Document card widget
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| speech_to_text | ^6.4.0 | Real-time speech recognition |
| provider | ^6.0.5 | State management |
| hive | ^2.2.3 | Local storage |
| hive_flutter | ^1.1.0 | Flutter Hive bindings |
| path_provider | ^2.1.2 | File system paths |
| dio | ^5.0.3 | HTTP client |
| flutter_dotenv | ^5.1.0 | Environment variables |
| share_plus | ^7.2.2 | Share functionality |
| permission_handler | ^11.0.1 | Permission handling |
| uuid | ^4.2.1 | UUID generation |
| intl | ^0.19.0 | Date formatting |

## Permissions

### Android
- `RECORD_AUDIO` - Microphone access for speech recognition
- `INTERNET` - Groq API for AI summarization

### iOS
Add to `Info.plist`:
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app uses speech recognition for voice dictation.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone for voice dictation.</string>
```

## Configuration

### Groq API
The app uses Groq's free API for AI summarization. Features work without it, but summarization will be disabled.

1. Sign up at [console.groq.com](https://console.groq.com/)
2. Create an API key
3. Add to `.env` file

## Architecture

- **State Management**: Provider pattern
- **Local Storage**: Hive for fast, offline-first storage
- **API Layer**: Dio for HTTP requests
- **Design**: Material 3 with custom theming

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [speech_to_text](https://pub.dev/packages/speech_to_text) for speech recognition
- [Groq](https://groq.com/) for AI summarization API
- [Hive](https://pub.dev/packages/hive) for local storage
