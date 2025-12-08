import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:super_xo/models/websocket_message.dart';

/// Service to manage WebSocket connection for online gameplay
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _channel != null;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Connect to the WebSocket server
  /// [url] should be in format: ws://localhost:8080 or wss://your-server.com
  /// Throws [TimeoutException] if connection takes too long
  /// Throws [Exception] if connection fails
  Future<void> connect(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
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
          _messageController.addError(error);
        },
        onDone: () {
          print('WebSocket connection closed');
          disconnect();
        },
      );
    } catch (e) {
      _channel?.sink.close();
      _channel = null;
      print('Connection error: $e');
      rethrow;
    }
  }

  /// Send a message to the server
  void send(WebSocketMessage message) {
    if (_channel == null) {
      throw Exception('Not connected to server');
    }
    _channel!.sink.add(jsonEncode(message.toJson()));
  }

  /// Disconnect from the server
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
