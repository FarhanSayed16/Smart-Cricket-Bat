# Coach's Eye AI - Smart Cricket Training App

A Flutter mobile application that connects to a smart cricket bat equipped with ESP32 and BNO055 sensors to analyze player performance and provide real-time feedback.

## 🏏 Features

### Player Features
- **Real-time Shot Analysis**: Live monitoring of bat speed, power, timing, and sweet spot accuracy
- **Session Management**: Track practice sessions with detailed statistics
- **Performance Insights**: Comprehensive analysis of batting performance
- **Data Visualization**: Charts and heatmaps for performance tracking
- **Coach Linking**: Connect to coaches using invite codes
- **Coach Feedback**: Receive personalized notes and feedback on shots

### Coach Features
- **Coach Dashboard**: Manage multiple players and view their progress
- **Invite Code System**: Generate unique codes for players to join
- **Player Performance Analysis**: Deep dive into individual player sessions
- **Real-time Feedback**: Add notes and feedback to specific shots
- **Session Visualization**: Charts and heatmaps for comprehensive analysis
- **Player Management**: View all linked players and their training history

### Core Features
- **User Authentication**: Secure login/signup with Firebase Auth
- **Cloud Storage**: Session data stored in Firestore for analysis and history
- **Role-based Access**: Separate interfaces for players and coaches

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.9.2+
- **State Management**: Riverpod
- **Backend**: Firebase (Auth + Firestore)
- **Hardware**: ESP32 + BNO055 IMU sensor
- **Development**: Hardware simulator for testing

## 📱 App Structure

```
lib/
├── src/
│   ├── features/
│   │   ├── auth/              # Login & Signup screens
│   │   ├── dashboard/         # Player dashboard with session history
│   │   ├── coach_dashboard/   # Coach dashboard and player management
│   │   └── session/           # Live session & summary screens
│   ├── models/                # Data models (User, Session, Shot, Profiles)
│   ├── services/              # Firebase & hardware services
│   ├── providers/             # Riverpod state management
│   └── common_widgets/        # Reusable UI components
└── main.dart                 # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Firebase project setup
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd coaches_eye_ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate platform folders

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Hardware Integration

### ESP32 + BNO055 Setup

The app is designed to work with:
- **ESP32 DevKit V1** (or similar)
- **BNO055 IMU sensor** for motion detection
- **Bluetooth/WiFi** for data transmission

### Hardware Simulator

For development and testing, the app includes a `HardwareSimulator` class that generates realistic shot data:

- **Bat Speed**: 70-130 km/h (realistic cricket bat speeds)
- **Power Index**: 60-95 (based on swing force)
- **Timing Score**: -25 to +25 ms (early/late timing)
- **Sweet Spot Accuracy**: 0.7-1.0 (contact quality)

## 📊 Data Models

### User Model
- `uid`: Unique user identifier
- `email`: User email address
- `displayName`: User's display name
- `role`: 'player' or 'coach'

### Session Model
- `sessionId`: Unique session identifier
- `playerId`: Associated player ID
- `date`: Session date/time
- `durationInMinutes`: Session duration
- `totalShots`: Number of shots taken
- `averageBatSpeed`: Average bat speed for session

### Shot Model
- `shotId`: Unique shot identifier
- `sessionId`: Associated session ID
- `timestamp`: Shot timestamp
- `batSpeed`: Bat speed in km/h
- `powerIndex`: Power rating (0-100)
- `timingScore`: Timing accuracy (-50 to +50 ms)
- `sweetSpotAccuracy`: Sweet spot contact (0.0-1.0)
- `coachNotes`: Optional coach feedback

### Profile Models
- **PlayerProfile**: Player-specific data with coach relationship
- **CoachProfile**: Coach-specific data with linked players
- **CoachInviteCode**: Invite code management for player-coach linking

## 🔄 State Management

The app uses Riverpod for state management with the following providers:

### Core Providers
- `authStateProvider`: Authentication state stream
- `currentUserProvider`: Current user data
- `shotStreamProvider`: Real-time shot data stream
- `sessionsProvider`: User's session history
- `appStateProvider`: Global app state management

### Coach-Player Providers
- `playersForCoachProvider`: Players linked to a coach
- `coachProfileProvider`: Coach profile data
- `playerProfileProvider`: Player profile data
- `sessionsForPlayerByCoachProvider`: Sessions for specific player (coach view)

## 🎯 Key Features Explained

### Live Session Screen
- Real-time shot data display
- Large, easy-to-read metrics
- Recent shots history
- Session statistics
- End session functionality

### Dashboard Screen
- Welcome message with user info
- Session history list
- Quick session start button
- Performance overview

### Session Summary Screen
- Detailed session statistics
- Performance insights with charts and heatmaps
- Shot-by-shot history with coach feedback
- Bat speed performance chart
- Hit location heatmap (simulated)
- Coach note system for feedback

### Coach Dashboard Screen
- Invite code generation and sharing
- Linked players list
- Player performance overview
- Quick access to player sessions

### Player Detail Screen (Coach View)
- Individual player performance analysis
- Complete session history
- Access to detailed session summaries
- Player-specific insights

## 🔐 Authentication Flow

1. **Splash Screen**: Shows while checking auth state
2. **Login/Signup**: Email/password authentication
3. **Dashboard**: Main app interface for authenticated users
4. **Auto-logout**: Handles session expiration

## 📈 Performance Metrics

The app tracks and analyzes:

- **Bat Speed**: Measured in km/h, indicates swing power
- **Power Index**: 0-100 scale based on acceleration
- **Timing Score**: Milliseconds early/late from optimal contact
- **Sweet Spot Accuracy**: Quality of bat-ball contact

## 🚧 Future Enhancements

- **Bluetooth Integration**: Direct ESP32 connection
- **Video Analysis**: Camera integration for swing analysis
- **Performance Trends**: Long-term progress tracking
- **Social Features**: Share achievements and compete
- **AI Insights**: Machine learning for personalized feedback
- **Advanced Analytics**: More sophisticated performance metrics
- **Team Management**: Group coaching and team sessions

## 🐛 Troubleshooting

### Common Issues

1. **Firebase Connection**: Ensure Firebase is properly configured
2. **Dependencies**: Run `flutter pub get` if packages are missing
3. **Platform Setup**: Check Android/iOS configuration files
4. **Hardware Simulator**: Use simulator for testing without hardware

### Debug Mode

Enable debug logging by setting:
```dart
// In main.dart
debugShowCheckedModeBanner: true;
```

## 📝 Development Notes

- The hardware simulator generates realistic data for testing
- All Firebase operations include proper error handling
- UI follows Material Design principles
- Code is well-commented and documented
- State management is centralized and efficient

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**Happy Cricket Training! 🏏**