// lib/game/game_state.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'sort_level.dart';
import 'constants_bridge.dart';
import '../utils/preferences.dart';
import '../utils/audio_manager.dart';

class _Snapshot {
  final List<List<int>> tubes;
  final int moves;
  _Snapshot(this.tubes, this.moves);
}

class GameState extends ChangeNotifier {
  late SortLevel level;
  late List<List<int>> tubes;
  int? selected; // tube index with lifted orbs
  int moves = 0;
  bool isComplete = false;
  int stars = 0;
  int currentLevelIndex = 0;
  bool initialized = false;
  final List<_Snapshot> _undo = [];

  void loadLevel(int index) {
    currentLevelIndex = index;
    level = LevelGenerator.generate(index);
    tubes = level.freshTubes();
    selected = null;
    moves = 0;
    isComplete = false;
    stars = 0;
    _undo.clear();
    initialized = true;
    notifyListeners();
  }

  bool get canUndo => _undo.isNotEmpty && !isComplete;

  bool _isTubeDone(List<int> t) =>
      t.length == kCap && t.every((b) => b == t.first);

  int _topRun(List<int> t) {
    if (t.isEmpty) return 0;
    final c = t.last;
    int run = 0;
    for (int k = t.length - 1; k >= 0 && t[k] == c; k--) {
      run++;
    }
    return run;
  }

  bool canPour(int from, int to) {
    if (from == to) return false;
    final src = tubes[from], dst = tubes[to];
    if (src.isEmpty || dst.length >= kCap) return false;
    if (dst.isNotEmpty && dst.last != src.last) return false;
    return true;
  }

  void tapTube(int index) {
    if (isComplete) return;
    if (selected == null) {
      if (tubes[index].isEmpty || _isTubeDone(tubes[index])) return;
      selected = index;
      notifyListeners();
      return;
    }
    if (selected == index) {
      selected = null;
      notifyListeners();
      return;
    }
    if (canPour(selected!, index)) {
      _pour(selected!, index);
      selected = null;
    } else {
      // reselect if the tapped tube is pickable
      selected = (tubes[index].isEmpty || _isTubeDone(tubes[index]))
          ? null
          : index;
    }
    notifyListeners();
  }

  void _pour(int from, int to) {
    _undo.add(_Snapshot(
        tubes.map((t) => List<int>.from(t)).toList(), moves));
    if (_undo.length > 300) _undo.removeAt(0);

    final src = tubes[from], dst = tubes[to];
    final pour = min(_topRun(src), kCap - dst.length);
    for (int k = 0; k < pour; k++) {
      dst.add(src.removeLast());
    }
    moves++;
    AudioManager.instance.playPour();
    _checkComplete();
  }

  void undo() {
    if (!canUndo) return;
    final s = _undo.removeLast();
    tubes = s.tubes;
    moves = s.moves;
    selected = null;
    notifyListeners();
  }

  void _checkComplete() {
    final done = tubes.every((t) => t.isEmpty || _isTubeDone(t));
    if (done && !isComplete) {
      isComplete = true;
      stars = _calcStars();
      AudioManager.instance.playComplete();
      Preferences.instance.saveLevelResult(currentLevelIndex, stars);
    }
  }

  int _calcStars() {
    if (moves <= level.parMoves) return 3;
    if (moves <= (level.parMoves * 1.6).round()) return 2;
    return 1;
  }

  void restartLevel() {
    tubes = level.freshTubes();
    selected = null;
    moves = 0;
    isComplete = false;
    stars = 0;
    _undo.clear();
    notifyListeners();
  }

  void nextLevel() {
    if (currentLevelIndex < 149) loadLevel(currentLevelIndex + 1);
  }
}
