# Quick Start Guide

## Get Started in 3 Steps

### 1. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Navigate to backend folder
cd backend

# Install Node.js dependencies
npm install
```

### 2. Start the Backend Server (for Online Play)

```bash
# From the backend directory
npm start
```

Keep this terminal running. The server will be available at `ws://localhost:8080`

### 3. Run the Flutter App

```bash
# From the project root (open a new terminal)
flutter run
```

Or for web:
```bash
flutter run -d chrome
```

## Testing the App

### Test Local Mode
1. Launch the app
2. Tap "Play Locally"
3. Play a game with two players on the same device

### Test Online Mode
1. Ensure backend is running (`npm start` in backend folder)
2. Launch the app (or use two devices/browsers)
3. Tap "Play Online"
4. On first device: tap "Create Room" and note the room code
5. On second device: tap "Join Room" and enter the code
6. Play online!

### Test Settings
1. From start menu, tap "Settings"
2. Toggle dark mode
3. Change language
4. Select a different color theme
5. Settings persist after restart

## Common Issues

**"Failed to connect to server"**
- Make sure backend is running: `cd backend && npm start`
- Check WebSocket URL in `lib/screens/online_lobby_screen.dart`

**Build errors**
- Run: `flutter clean && flutter pub get`
- Ensure Flutter SDK is up to date: `flutter upgrade`

**Backend won't start**
- Make sure Node.js is installed: `node --version`
- Delete `node_modules` and run `npm install` again

## Next Steps

- Read the full README.md for detailed documentation
- Explore the backend/README.md for WebSocket protocol details
- Check out the code architecture in lib/ directory

Enjoy playing Super XO!
