import 'package:flutter/foundation.dart';

/// Session score shown in the header HUD. Not persisted: like an arcade,
/// every visit starts from zero coins.
class GameState {
  GameState._();

  static final coins = ValueNotifier<int>(0);

  /// Coins needed to unlock the collector achievement.
  static const collectorGoal = 10;
}
