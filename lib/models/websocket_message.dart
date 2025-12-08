/// Base class for WebSocket messages
abstract class WebSocketMessage {
  final String type;
  final Map<String, dynamic> payload;

  const WebSocketMessage({required this.type, required this.payload});

  Map<String, dynamic> toJson() {
    return {'type': type, 'payload': payload};
  }
}

/// Create room message
class CreateRoomMessage extends WebSocketMessage {
  CreateRoomMessage() : super(type: 'CREATE_ROOM', payload: {});
}

/// Join room message
class JoinRoomMessage extends WebSocketMessage {
  JoinRoomMessage(String roomCode)
    : super(type: 'JOIN_ROOM', payload: {'roomCode': roomCode});
}

/// Make move message
class MakeMoveMessage extends WebSocketMessage {
  MakeMoveMessage({required int boardIndex, required int cellIndex})
    : super(
        type: 'MAKE_MOVE',
        payload: {'boardIndex': boardIndex, 'cellIndex': cellIndex},
      );
}

/// Restart game message
class RestartGameMessage extends WebSocketMessage {
  RestartGameMessage() : super(type: 'RESTART_GAME', payload: {});
}

/// Leave room message
class LeaveRoomMessage extends WebSocketMessage {
  LeaveRoomMessage() : super(type: 'LEAVE_ROOM', payload: {});
}

/// Reconnect message
class ReconnectMessage extends WebSocketMessage {
  ReconnectMessage({required String playerId, required String roomCode})
    : super(
        type: 'RECONNECT',
        payload: {'playerId': playerId, 'roomCode': roomCode},
      );
}

/// Check room message
class CheckRoomMessage extends WebSocketMessage {
  CheckRoomMessage({required String playerId, required String roomCode})
    : super(
        type: 'CHECK_ROOM',
        payload: {'playerId': playerId, 'roomCode': roomCode},
      );
}

/// Room info received from server
class RoomInfo {
  final String roomCode;
  final String roomId;
  final String playerId;
  final String playerSymbol;

  const RoomInfo({
    required this.roomCode,
    required this.roomId,
    required this.playerId,
    required this.playerSymbol,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomCode: json['roomCode'] ?? '',
      roomId: json['roomId'] ?? '',
      playerId: json['playerId'] ?? '',
      playerSymbol: json['playerSymbol'] ?? '',
    );
  }
}

/// Move data received from server
class MoveData {
  final String playedBy;
  final int boardIndex;
  final int cellIndex;
  final String playerId;

  const MoveData({
    required this.playedBy,
    required this.boardIndex,
    required this.cellIndex,
    required this.playerId,
  });

  factory MoveData.fromJson(Map<String, dynamic> json) {
    return MoveData(
      playedBy: json['playedBy'] ?? '',
      boardIndex: json['boardIndex'] ?? 0,
      cellIndex: json['cellIndex'] ?? 0,
      playerId: json['playerId'] ?? '',
    );
  }
}
