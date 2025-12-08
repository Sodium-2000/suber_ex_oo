# Super XO - Ultimate Tic-Tac-Toe

An enhanced version of Ultimate Tic-Tac-Toe with both local and online multiplayer support.

## Features

- **Local Play**: Play against a friend on the same device
- **Online Play**: Play against anyone over the internet using WebSocket
- **Unified Settings**: All theme, language, and color settings in one place
- **Dark/Light Mode**: Toggle between themes
- **Multiple Languages**: Support for English and Arabic
- **Color Themes**: 8 different color schemes to choose from
- **Persistent Settings**: Your preferences are saved

## Project Structure

```
super_xo/
├── backend/              # Node.js WebSocket server
│   ├── server.js        # Main server file
│   ├── package.json     # Node dependencies
│   └── README.md        # Backend documentation
├── lib/                 # Flutter application
│   ├── main.dart        # App entry point
│   ├── models/          # Data models
│   │   ├── game_mode.dart
│   │   ├── game_state.dart
│   │   └── websocket_message.dart
│   ├── screens/         # UI screens
│   │   ├── start_menu_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── online_lobby_screen.dart
│   │   ├── ultimate_board.dart
│   │   └── small_board.dart
│   ├── services/        # Business logic
│   │   └── websocket_service.dart
│   ├── controllers/     # State management
│   │   └── language_controller.dart
│   ├── theme/          # Theming
│   │   ├── app_theme.dart
│   │   └── theme_controller.dart
│   ├── localization/   # Translations
│   │   └── app_localizations.dart
│   └── widgets/        # Reusable widgets
│       └── button.dart
└── pubspec.yaml        # Flutter dependencies
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Node.js (v18 or higher)
- Dart SDK (comes with Flutter)

### Flutter App Setup

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

   Or for web:
   ```bash
   flutter run -d chrome
   ```

### Backend Server Setup (for Online Play)

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install Node dependencies:**
   ```bash
   npm install
   ```

3. **Start the server:**
   ```bash
   npm start
   ```

   Or for development with auto-reload:
   ```bash
   npm run dev
   ```

   The server will start on `ws://localhost:8080`

### Configuration

To use a different WebSocket server URL (e.g., deploying to production):

1. Open `lib/screens/online_lobby_screen.dart`
2. Update the `wsUrl` constant:
   ```dart
   static const String wsUrl = 'ws://your-server-url:port';
   ```

## How to Play

### Local Mode

1. Launch the app
2. Tap "Play Locally"
3. Play with a friend on the same device
4. Players alternate turns

### Online Mode

1. Launch the app
2. Tap "Play Online"
3. Choose one of:
   - **Create Room**: Creates a new game room and displays a 6-character code
   - **Join Room**: Enter a room code to join an existing game
4. Wait for opponent to join
5. Play your game!

### Game Rules

- This is Ultimate Tic-Tac-Toe (also called Super Tic-Tac-Toe)
- The game board consists of 9 small tic-tac-toe boards arranged in a 3×3 grid
- The goal is to win the big board by winning 3 small boards in a row
- Your move determines which small board your opponent must play in next
- If sent to a completed board, opponent can play in any available board
- Undo is available in local mode only

## Settings

Access settings from:
- The settings button in the game (gear icon)
- The settings option in the start menu

Available settings:
- **Theme Mode**: Toggle between light and dark mode
- **Language**: Switch between English and Arabic
- **Color Theme**: Choose from 8 color schemes

All settings are automatically saved and persist between sessions.

## Architecture Decisions

### Best Practices Implemented

1. **Separation of Concerns**
   - Models separate from UI
   - Services handle business logic
   - Controllers manage state
   - Clear screen/widget hierarchy

2. **Scalability**
   - WebSocket service is reusable
   - Message types are extensible
   - Game state is well-defined
   - Easy to add new features

3. **Maintainability**
   - Centralized localization
   - Theme management in one place
   - Settings consolidated
   - Clear code structure

4. **State Management**
   - ValueNotifier for reactive updates
   - Stateful widgets where needed
   - Clean state initialization

5. **Network Architecture**
   - WebSocket for real-time communication
   - Room-based game sessions
   - Server-authoritative game state
   - Graceful disconnection handling

## Deployment

### Deploying the Backend

The backend can be deployed to any Node.js hosting service:

- **Heroku**: Add a `Procfile` with `web: node server.js`
- **Railway**: Connect your repo and it auto-deploys
- **DigitalOcean**: Use App Platform or Droplets
- **AWS**: Use Elastic Beanstalk or EC2

Remember to:
1. Set the `PORT` environment variable if required
2. Update the Flutter app's WebSocket URL
3. Use WSS (WebSocket Secure) for HTTPS deployments

### Deploying the Flutter App

- **Web**: `flutter build web` then deploy to any static host
- **Android**: `flutter build apk` or `flutter build appbundle`
- **iOS**: `flutter build ios`
- **Windows**: `flutter build windows`
- **macOS**: `flutter build macos`

## Troubleshooting

### WebSocket Connection Issues

- Ensure the backend server is running
- Check the WebSocket URL in `online_lobby_screen.dart`
- For web builds, ensure CORS is configured if needed
- Check firewall settings

### Build Issues

- Run `flutter clean` then `flutter pub get`
- Update Flutter: `flutter upgrade`
- Check Flutter doctor: `flutter doctor`

## Future Enhancements

Potential improvements:
- Player authentication
- Game history/statistics
- Ranked matchmaking
- Spectator mode
- Chat during games
- Multiple game modes (timed, different board sizes)
- Sound effects and animations
- AI opponent for single player

## License

This project is open source and available under the MIT License.

## Credits

Developed as an enhanced version of Super XO with online multiplayer capabilities.
