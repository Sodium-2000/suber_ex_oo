# Getting Started Checklist

Follow these steps to get Super XO running:

## ✅ Step 1: Install Flutter Dependencies

```bash
flutter pub get
```

**Expected output:** "Got dependencies!"

---

## ✅ Step 2: Set Up Backend Server

```bash
cd backend
npm install
```

**Expected output:** "added X packages"

---

## ✅ Step 3: Start Backend Server

**In the backend directory:**
```bash
npm start
```

**Expected output:** 
```
WebSocket server started on port 8080
```

**Keep this terminal running!** ⚠️

---

## ✅ Step 4: Run Flutter App

**In a new terminal, from project root:**

### For Mobile/Desktop:
```bash
flutter run
```

### For Web:
```bash
flutter run -d chrome
```

---

## ✅ Step 5: Test Local Play

1. App should open to Start Menu
2. Tap **"Play Locally"**
3. Game board should appear
4. Tap cells to play
5. Try making moves
6. Test the undo button
7. Test the restart button
8. Access settings (gear icon)
9. Change theme, language, colors
10. Return to game

**Status:** [ ] Working / [ ] Issues

---

## ✅ Step 6: Test Online Play

### Device/Browser 1:
1. Tap **"Play Online"**
2. Tap **"Create Room"**
3. Note the 6-character room code
4. Wait for opponent...

### Device/Browser 2:
1. Tap **"Play Online"**
2. Tap **"Join Room"**
3. Enter the room code from Device 1
4. Tap **"Join"**

### Both Devices:
1. Game should start
2. Player 1 (X) makes first move
3. Player 2 (O) makes second move
4. Verify moves sync
5. Complete a game
6. Try restart

**Status:** [ ] Working / [ ] Issues

---

## ✅ Step 7: Test Settings

1. From start menu → **Settings**
2. Toggle Dark Mode
3. Switch Language (EN ↔ AR)
4. Change Color Theme
5. Go back to menu
6. Restart app
7. Verify settings persisted

**Status:** [ ] Working / [ ] Issues

---

## Troubleshooting

### Backend won't start
- Check Node.js installed: `node --version`
- Delete `node_modules`: `rm -rf node_modules`
- Reinstall: `npm install`

### Flutter build errors
- Clean: `flutter clean`
- Get dependencies: `flutter pub get`
- Update: `flutter upgrade`

### Can't connect to server
- Ensure backend is running
- Check URL in `lib/screens/online_lobby_screen.dart`
- Default is: `ws://localhost:8080`

### Moves not syncing
- Check both devices connected to same server
- Check room codes match
- Restart backend server

---

## All Set! 🎉

If all steps passed, you're ready to:
- Play locally with friends
- Host online games
- Customize your experience
- Share room codes and play online

**Have fun playing Super XO!**

---

## Next Steps

- [ ] Read README.md for full documentation
- [ ] Check backend/README.md for API details
- [ ] Review CHANGES.md for what's new
- [ ] Consider deploying to production
- [ ] Share with friends!
