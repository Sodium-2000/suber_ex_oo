import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_xo/localization/app_localizations.dart';
import 'package:super_xo/services/websocket_service.dart';
import 'package:super_xo/models/websocket_message.dart';
import 'package:super_xo/screens/ultimate_board.dart';
import 'package:super_xo/models/game_mode.dart';

/// Online lobby screen for creating or joining game rooms
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _roomCodeController = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  String? _currentRoomCode;
  String? _playerId;
  String? _playerSymbol;
  bool _isWaitingForOpponent = false;
  bool _isConnecting = false;
  String? _errorMessage;
  bool _isInGame = false; // Track if we've navigated to game
  String? _lastRoomCode;
  String? _lastPlayerId;
  bool _isLoadingLastRoom = true;
  bool _canReconnectToLastRoom = false;
  bool _isCheckingRoom = false;

  // WebSocket server URL - change this to your server URL
  static const String wsUrl = 'wss://super-xo-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadLastRoomInfo();
    _connectToServer();
  }

  Future<void> _loadLastRoomInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastRoomCode = prefs.getString('last_room_code');
      _lastPlayerId = prefs.getString('last_player_id');
      _isLoadingLastRoom = false;
    });

    // Check if room is still active after loading
    if (_lastRoomCode != null && _lastPlayerId != null) {
      _checkRoomStatus();
    }
  }

  Future<void> _saveRoomInfo(String roomCode, String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_room_code', roomCode);
    await prefs.setString('last_player_id', playerId);
    setState(() {
      _lastRoomCode = roomCode;
      _lastPlayerId = playerId;
    });
  }

  Future<void> _clearLastRoomInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_room_code');
    await prefs.remove('last_player_id');
    setState(() {
      _lastRoomCode = null;
      _lastPlayerId = null;
      _canReconnectToLastRoom = false;
    });
  }

  Future<void> _checkRoomStatus() async {
    if (_lastRoomCode == null || _lastPlayerId == null) return;
    if (!_wsService.isConnected) return;

    setState(() {
      _isCheckingRoom = true;
    });

    _wsService.send(
      CheckRoomMessage(playerId: _lastPlayerId!, roomCode: _lastRoomCode!),
    );
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await _wsService.connect(wsUrl);
      _listenToMessages();
      setState(() {
        _isConnecting = false;
      });
    } on TimeoutException {
      setState(() {
        _isConnecting = false;
        _errorMessage = tr('server_unreachable');
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = tr('connection_failed');
      });
    }
  }

  void _listenToMessages() {
    _wsSubscription = _wsService.messages.listen((message) {
      final type = message['type'];
      final payload = message['payload'];

      switch (type) {
        case 'ROOM_CREATED':
          _handleRoomCreated(payload);
          break;
        case 'ROOM_JOINED':
          _handleRoomJoined(payload);
          break;
        case 'RECONNECTED':
          _handleReconnected(payload);
          break;
        case 'OPPONENT_JOINED':
          _handleOpponentJoined();
          break;
        case 'ROOM_TIMEOUT':
          _handleRoomTimeout(payload);
          break;
        case 'ROOM_CHECK_RESULT':
          _handleRoomCheckResult(payload);
          break;
        case 'ERROR':
          _handleError(payload);
          break;
      }
    });
  }

  void _handleRoomCreated(Map<String, dynamic> payload) {
    final roomInfo = RoomInfo.fromJson(payload);
    setState(() {
      _currentRoomCode = roomInfo.roomCode;
      _playerId = roomInfo.playerId;
      _playerSymbol = roomInfo.playerSymbol;
      _isWaitingForOpponent = true;
    });
    _saveRoomInfo(roomInfo.roomCode, roomInfo.playerId);
  }

  void _handleRoomJoined(Map<String, dynamic> payload) {
    final roomInfo = RoomInfo.fromJson(payload);
    _playerId = roomInfo.playerId;
    _playerSymbol = roomInfo.playerSymbol;
    _saveRoomInfo(roomInfo.roomCode, roomInfo.playerId);

    // Navigate to game
    _navigateToGame(roomInfo.roomCode);
  }

  void _handleOpponentJoined() {
    if (_currentRoomCode != null) {
      _navigateToGame(_currentRoomCode!);
    }
  }

  void _handleReconnected(Map<String, dynamic> payload) {
    print('🔄 Lobby: RECONNECTED received');
    print('🔄 Payload: $payload');
    final roomInfo = RoomInfo.fromJson(payload);
    _playerId = roomInfo.playerId;
    _playerSymbol = roomInfo.playerSymbol;

    // Navigate to game with initial game state
    print('🔄 Navigating to game with initialGameState');
    _navigateToGame(roomInfo.roomCode, initialGameState: payload);
  }

  void _handleError(Map<String, dynamic> payload) {
    setState(() {
      _errorMessage = payload['error'] ?? 'Unknown error';
      _isWaitingForOpponent = false;
    });
  }

  void _handleRoomTimeout(Map<String, dynamic> payload) {
    setState(() {
      _errorMessage = payload['message'] ?? 'Room timed out';
      _isWaitingForOpponent = false;
      _currentRoomCode = null;
      _playerId = null;
      _playerSymbol = null;
    });
  }

  void _handleRoomCheckResult(Map<String, dynamic> payload) {
    setState(() {
      _isCheckingRoom = false;
      final exists = payload['exists'] ?? false;
      final canReconnect = payload['canReconnect'] ?? false;

      // Only show reconnect button if room exists and can reconnect
      _canReconnectToLastRoom = exists && canReconnect;

      // If room doesn't exist or can't reconnect, clear the saved info
      if (!_canReconnectToLastRoom) {
        _clearLastRoomInfo();
      }
    });
  }

  void _navigateToGame(
    String roomCode, {
    Map<String, dynamic>? initialGameState,
  }) {
    // Cancel the lobby's WebSocket subscription before navigating
    _wsSubscription?.cancel();
    _wsSubscription = null;

    // Mark that we're in a game
    _isInGame = true;

    // Navigate to game (use push to keep lobby in stack)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UltimateBoard(
          gameMode: GameMode.online,
          wsService: _wsService,
          playerId: _playerId!,
          playerSymbol: _playerSymbol!,
          roomCode: roomCode,
          initialGameState: initialGameState,
        ),
      ),
    ).then((_) {
      // When returning from game, reset state and re-establish listener
      setState(() {
        _isInGame = false;
        _isWaitingForOpponent = false;
        _currentRoomCode = null;
        _playerId = null;
        _playerSymbol = null;
      });

      // Re-establish WebSocket message listener for the lobby
      if (_wsService.isConnected && _wsSubscription == null) {
        _listenToMessages();
      }
    });
  }

  void _createRoom() {
    if (!_wsService.isConnected) {
      setState(() {
        _errorMessage = tr('not_connected');
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });
    _wsService.send(CreateRoomMessage());
  }

  void _joinRoom() {
    if (!_wsService.isConnected) {
      setState(() {
        _errorMessage = tr('not_connected');
      });
      return;
    }

    final roomCode = _roomCodeController.text.trim().toUpperCase();
    if (roomCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a room code';
      });
      return;
    }

    _wsService.send(JoinRoomMessage(roomCode));
  }

  void _reconnectToLastRoom() {
    if (!_wsService.isConnected) {
      setState(() {
        _errorMessage = tr('not_connected');
      });
      return;
    }

    if (_lastRoomCode == null || _lastPlayerId == null) {
      setState(() {
        _errorMessage = 'No previous room found';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });
    _wsService.send(
      ReconnectMessage(playerId: _lastPlayerId!, roomCode: _lastRoomCode!),
    );
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _wsSubscription?.cancel();
    // Only dispose WebSocket if we're not in a game
    // If we're in a game, the game screen is using it
    if (!_isInGame) {
      _wsService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('play_online')), centerTitle: true),
      body: SafeArea(
        child: _isConnecting
            ? const Center(child: CircularProgressIndicator())
            : _isWaitingForOpponent
            ? _buildWaitingScreen()
            : _buildLobbyScreen(),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              tr('waiting_for_opponent'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      tr('room_code'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentRoomCode ?? '',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _currentRoomCode ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Code copied: $_currentRoomCode'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                _wsService.send(LeaveRoomMessage());
                setState(() {
                  _isWaitingForOpponent = false;
                  _currentRoomCode = null;
                });
              },
              child: Text(tr('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      if (!_wsService.isConnected) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _connectToServer,
                            icon: const Icon(Icons.refresh, size: 20),
                            label: Text(tr('retry_connection')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Create Room Button
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add_circle_outline, size: 28),
                label: Text(
                  tr('create_room'),
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 32),

            // Reconnect to Last Room Button
            if (_canReconnectToLastRoom &&
                _lastRoomCode != null &&
                _lastPlayerId != null) ...[
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _reconnectToLastRoom,
                  icon: const Icon(Icons.history, size: 24),
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reconnect to Last Room',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Room: $_lastRoomCode',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Join Room Section
            Text(
              tr('join_room'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomCodeController,
              decoration: InputDecoration(
                labelText: tr('enter_room_code'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _joinRoom,
                icon: const Icon(Icons.login, size: 28),
                label: Text(tr('join'), style: const TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
