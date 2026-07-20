import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_xo/localization/app_localizations.dart';
import 'package:super_xo/models/game_mode.dart';
import 'package:super_xo/models/websocket_message.dart';
import 'package:super_xo/screens/ultimate_board.dart';
import 'package:super_xo/services/websocket_service.dart';
import 'package:super_xo/widgets/floating_pieces_background.dart';
import 'package:super_xo/widgets/staged_status_view.dart';

/// Quick-match screen: connects to the backend, joins the matchmaking queue,
/// and waits to be paired with a random opponent (first-come-first-served,
/// no skill matching).
class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

enum _Phase { connecting, searching, timedOut, error }

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  static const String wsUrl = 'wss://super-xo-backend.onrender.com';

  // Backup timer in case the server's own MATCHMAKING_TIMEOUT message never
  // arrives (dropped connection, etc.) - a few seconds past the server's own
  // 2-minute limit so the server message wins under normal conditions.
  static const Duration _clientSideBackupTimeout = Duration(seconds: 125);

  _Phase _phase = _Phase.connecting;
  String? _errorMessage;
  bool _isInGame = false;
  Timer? _backupTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _connectAndSearch();
  }

  Future<void> _connectAndSearch() async {
    setState(() {
      _phase = _Phase.connecting;
      _errorMessage = null;
    });

    try {
      await _wsService.connect(wsUrl, timeout: WebSocketService.coldStartTimeout);
      if (!mounted) return;
      _listenToMessages();
      _startSearching();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = tr('server_unreachable');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = tr('connection_failed');
      });
    }
  }

  void _startSearching() {
    setState(() {
      _phase = _Phase.searching;
    });
    try {
      _wsService.send(FindMatchMessage());
    } catch (e) {
      setState(() {
        _phase = _Phase.error;
        _errorMessage = tr('connection_failed');
      });
      return;
    }

    _backupTimeoutTimer?.cancel();
    _backupTimeoutTimer = Timer(_clientSideBackupTimeout, () {
      if (!mounted || _phase != _Phase.searching) return;
      setState(() {
        _phase = _Phase.timedOut;
      });
    });
  }

  void _listenToMessages() {
    _wsSubscription = _wsService.messages.listen((message) {
      if (!mounted) return;
      final type = message['type'];
      final payload = message['payload'];

      switch (type) {
        case 'MATCH_FOUND':
          _handleMatchFound(payload);
          break;
        case 'MATCHMAKING_TIMEOUT':
          _handleTimeout();
          break;
        case 'ERROR':
          _handleError(payload);
          break;
      }
    });
  }

  void _handleMatchFound(Map<String, dynamic> payload) {
    _backupTimeoutTimer?.cancel();
    final roomInfo = RoomInfo.fromJson(payload);

    // Confirm receipt so the server doesn't tear this match down thinking
    // we never got it.
    try {
      _wsService.send(MatchAckMessage());
    } catch (e) {
      // If this fails, the connection is already broken and the server's
      // own ack timeout will recover the other player anyway.
    }

    _wsSubscription?.cancel();
    _wsSubscription = null;
    _isInGame = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UltimateBoard(
          gameMode: GameMode.online,
          wsService: _wsService,
          playerId: roomInfo.playerId,
          playerSymbol: roomInfo.playerSymbol,
          roomCode: roomInfo.roomCode,
        ),
      ),
    );
  }

  void _handleTimeout() {
    _backupTimeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.timedOut;
    });
  }

  void _handleError(Map<String, dynamic> payload) {
    _backupTimeoutTimer?.cancel();
    setState(() {
      _phase = _Phase.error;
      _errorMessage = payload['error'] ?? tr('connection_failed');
    });
  }

  void _cancelSearch() {
    try {
      _wsService.send(CancelMatchmakingMessage());
    } catch (e) {
      // Leaving anyway - nothing to reconcile locally
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _backupTimeoutTimer?.cancel();
    _wsSubscription?.cancel();
    if (!_isInGame) {
      if (_phase == _Phase.searching) {
        try {
          _wsService.send(CancelMatchmakingMessage());
        } catch (e) {
          // Disposing anyway
        }
      }
      _wsService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('quick_match')), centerTitle: true),
      body: FloatingPiecesBackground(
        child: SafeArea(child: Center(child: _buildBody())),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.connecting:
        return const StagedStatusView(stages: kConnectingStages);
      case _Phase.searching:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StagedStatusView(stages: kMatchmakingStages),
              const SizedBox(height: 32),
              TextButton(onPressed: _cancelSearch, child: Text(tr('cancel'))),
            ],
          ),
        );
      case _Phase.timedOut:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                tr('matchmaking_timeout_title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                tr('matchmaking_timeout_message'),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startSearching,
                child: Text(tr('search_again')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('back')),
              ),
            ],
          ),
        );
      case _Phase.error:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? tr('connection_failed'),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _connectAndSearch,
                child: Text(tr('retry_connection')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('back')),
              ),
            ],
          ),
        );
    }
  }
}
