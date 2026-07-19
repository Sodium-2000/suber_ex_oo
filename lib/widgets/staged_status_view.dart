import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_xo/localization/app_localizations.dart';

/// One step in a [StagedStatusView]'s progression: the message shown once
/// [after] has elapsed since the view was first built.
class StageSpec {
  final Duration after;
  final String messageKey;
  final String? subMessageKey;

  const StageSpec({
    required this.after,
    required this.messageKey,
    this.subMessageKey,
  });
}

/// Shows a spinner plus a message that progresses through increasingly
/// reassuring stages the longer we wait. Used for any long-running network
/// wait (connecting to the backend, looking for a matchmaking opponent) where
/// a static "loading..." message would otherwise leave the user guessing
/// whether anything is still happening.
class StagedStatusView extends StatefulWidget {
  final List<StageSpec> stages;

  const StagedStatusView({super.key, required this.stages});

  @override
  State<StagedStatusView> createState() => _StagedStatusViewState();
}

class _StagedStatusViewState extends State<StagedStatusView> {
  late final Stopwatch _stopwatch;
  late final Timer _ticker;
  int _stageIndex = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateStage());
  }

  void _updateStage() {
    final elapsed = _stopwatch.elapsed;
    var newIndex = 0;
    for (var i = 0; i < widget.stages.length; i++) {
      if (elapsed >= widget.stages[i].after) newIndex = i;
    }
    if (newIndex != _stageIndex && mounted) {
      setState(() => _stageIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stages[_stageIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            tr(stage.messageKey),
            key: ValueKey(stage.messageKey),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        if (stage.subMessageKey != null) ...[
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              tr(stage.subMessageKey!),
              key: ValueKey(stage.subMessageKey),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

/// Stages for waiting on the initial WebSocket connection, where the delay is
/// usually the backend waking up from a cold start.
const List<StageSpec> kConnectingStages = [
  StageSpec(after: Duration.zero, messageKey: 'connecting_stage_1'),
  StageSpec(after: Duration(seconds: 3), messageKey: 'connecting_stage_2'),
  StageSpec(
    after: Duration(seconds: 8),
    messageKey: 'connecting_stage_3',
    subMessageKey: 'connecting_stage_3_sub',
  ),
  StageSpec(
    after: Duration(seconds: 20),
    messageKey: 'connecting_stage_4',
    subMessageKey: 'connecting_stage_4_sub',
  ),
  StageSpec(
    after: Duration(seconds: 40),
    messageKey: 'connecting_stage_5',
    subMessageKey: 'connecting_stage_5_sub',
  ),
];

/// Stages for waiting in the quick-match queue for a random opponent.
const List<StageSpec> kMatchmakingStages = [
  StageSpec(after: Duration.zero, messageKey: 'matchmaking_stage_1'),
  StageSpec(after: Duration(seconds: 5), messageKey: 'matchmaking_stage_2'),
  StageSpec(
    after: Duration(seconds: 20),
    messageKey: 'matchmaking_stage_3',
    subMessageKey: 'matchmaking_stage_3_sub',
  ),
  StageSpec(
    after: Duration(seconds: 45),
    messageKey: 'matchmaking_stage_4',
    subMessageKey: 'matchmaking_stage_4_sub',
  ),
  StageSpec(
    after: Duration(seconds: 90),
    messageKey: 'matchmaking_stage_5',
    subMessageKey: 'matchmaking_stage_5_sub',
  ),
];
