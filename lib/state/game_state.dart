import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show GlobalKey;

/// Session score shown in the header HUD. Not persisted: like an arcade,
/// every visit starts from zero coins.
class GameState {
  GameState._();

  static final coins = ValueNotifier<int>(0);

  /// Marks the header's coin counter, so effects can aim at it.
  static final coinHudKey = GlobalKey(debugLabel: 'coinHud');

  /// Coins needed to unlock the collector achievement.
  static const collectorGoal = 10;
}
