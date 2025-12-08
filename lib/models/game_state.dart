/// Represents the state of a small 3x3 board
class SmallBoardState {
  final List<String> cells;
  final String winner;
  final bool isGameOver;

  const SmallBoardState({
    required this.cells,
    required this.winner,
    required this.isGameOver,
  });

  factory SmallBoardState.initial() {
    return SmallBoardState(
      cells: List.filled(9, ''),
      winner: '',
      isGameOver: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'cells': cells, 'winner': winner, 'isGameOver': isGameOver};
  }

  factory SmallBoardState.fromJson(Map<String, dynamic> json) {
    return SmallBoardState(
      cells: List<String>.from(json['cells'] ?? []),
      winner: json['winner'] ?? '',
      isGameOver: json['isGameOver'] ?? false,
    );
  }

  SmallBoardState copyWith({
    List<String>? cells,
    String? winner,
    bool? isGameOver,
  }) {
    return SmallBoardState(
      cells: cells ?? List.from(this.cells),
      winner: winner ?? this.winner,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }
}

/// Represents the complete game state
class GameState {
  final List<String> bigBoard;
  final List<SmallBoardState> smallBoards;

  const GameState({required this.bigBoard, required this.smallBoards});

  factory GameState.initial() {
    return GameState(
      bigBoard: List.filled(9, ''),
      smallBoards: List.generate(9, (_) => SmallBoardState.initial()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bigBoard': bigBoard,
      'smallBoards': smallBoards.map((sb) => sb.toJson()).toList(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      bigBoard: List<String>.from(json['bigBoard'] ?? []),
      smallBoards:
          (json['smallBoards'] as List?)
              ?.map((sb) => SmallBoardState.fromJson(sb))
              .toList() ??
          [],
    );
  }

  GameState copyWith({
    List<String>? bigBoard,
    List<SmallBoardState>? smallBoards,
  }) {
    return GameState(
      bigBoard: bigBoard ?? List.from(this.bigBoard),
      smallBoards: smallBoards ?? List.from(this.smallBoards),
    );
  }
}
