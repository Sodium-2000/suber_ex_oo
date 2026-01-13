import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:super_xo/models/websocket_message.dart';

/// Service to manage WebSocket connection for online gameplay
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  String? _currentUrl;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  Duration _reconnectDelay = const Duration(seconds: 1);
  Timer? _reconnectTimer;
  bool _isClosed = false;

  bool get isConnected => _channel != null;

  /// Check if the WebSocket is ready to send messages
  bool get isReady => _channel != null && !_isClosed;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Connect to the WebSocket server
  /// [url] should be in format: ws://localhost:8080 or wss://your-server.com
  /// Throws [TimeoutException] if connection takes too long
  /// Throws [Exception] if connection fails
  Future<void> connect(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _currentUrl = url;
    try {
      final uri = Uri.parse(url);

      // Create channel
      _channel = WebSocketChannel.connect(uri);

      // Wait for first message or error with timeout to verify connection
      await _channel!.ready.timeout(
        timeout,
        onTimeout: () {
          _channel?.sink.close();
          _channel = null;
          throw TimeoutException(
            'Could not connect to server. Please check your internet connection.',
          );
        },
      );

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            _messageController.add(data);
          } catch (e) {
            print('Error decoding message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      // Reset reconnection attempts on successful connection
      _reconnectAttempts = 0;
      _reconnectDelay = const Duration(seconds: 1);
      _isClosed = false;
    } catch (e) {
      _channel?.sink.close();
      _channel = null;
      print('Connection error: $e');
      rethrow;
    }
  }

  /// Send a message to the server
  void send(WebSocketMessage message) {
    if (!isReady) {
      throw Exception('Not connected to server');
    }
    try {
      _channel!.sink.add(jsonEncode(message.toJson()));
    } catch (e) {
      // If sending fails, mark as disconnected and trigger reconnection
      _handleDisconnection();
      throw Exception('Failed to send message: $e');
    }
  }

  /// Disconnect from the server
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reconnectAttempts = 0;
  }

  void _handleDisconnection() {
    _isClosed = true;
    _channel = null;
    if (_currentUrl != null && _reconnectAttempts < maxReconnectAttempts) {
      _attemptReconnect();
    } else {
      // Emit disconnection event
      _messageController.add({'type': 'CONNECTION_LOST'});
    }
  }

  void _attemptReconnect() {
    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      try {
        await connect(_currentUrl!);
      } catch (e) {
        _reconnectDelay *= 2; // Exponential backoff
        if (_reconnectAttempts < maxReconnectAttempts) {
          _attemptReconnect();
        } else {
          _messageController.add({'type': 'CONNECTION_LOST'});
        }
      }
    });
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
