// lib/game/sort_level.dart
import 'dart:math';
import 'constants_bridge.dart';

/// A SortLab level: [colorCount] colors × 4 orbs dealt into [colorCount]
/// tubes, plus 2 empty tubes. Every generated deal is run through a DFS
/// solver — only solvable deals ship, and the solver's solution length
/// becomes the par.
class SortLevel {
  final int index;
  final int colorCount;
  final String difficulty;
  final int parMoves;
  final List<List<int>> initialTubes;

  SortLevel({
    required this.index,
    required this.colorCount,
    required this.difficulty,
    required this.parMoves,
    required this.initialTubes,
  });

  int get tubeCount => initialTubes.length;

  List<List<int>> freshTubes() =>
      initialTubes.map((t) => List<int>.from(t)).toList();
}

class LevelGenerator {
  static SortLevel generate(int levelIndex) {
    int colors;
    String difficulty;
    if (levelIndex < 50) {
      colors = 4 + (levelIndex ~/ 17); // 4,5,6
      difficulty = 'Easy';
    } else if (levelIndex < 100) {
      colors = 7 + ((levelIndex - 50) ~/ 25); // 7,8
      difficulty = 'Medium';
    } else {
      colors = 9 + ((levelIndex - 100) ~/ 25); // 9,10
      difficulty = 'Hard';
    }
    colors = colors.clamp(4, 10);

    final rng = Random(levelIndex * 6131 + levelIndex * 23 + 17);

    for (int attempt = 0; attempt < 40; attempt++) {
      final tubes = _deal(colors, Random(rng.nextInt(1 << 31)));
      if (_isSolved(tubes)) continue;
      final par = SortSolver.solve(tubes);
      if (par > 0) {
        return SortLevel(
          index: levelIndex,
          colorCount: colors,
          difficulty: difficulty,
          parMoves: par,
          initialTubes: tubes,
        );
      }
    }
    // Statistically unreachable fallback: an almost-solved deal
    final tubes = List.generate(
        colors, (c) => List<int>.filled(kCap, c))
      ..add(<int>[])
      ..add(<int>[]);
    final a = tubes[0].removeLast();
    final b = tubes[1].removeLast();
    tubes[colors].add(b);
    tubes[colors + 1].add(a);
    return SortLevel(
      index: levelIndex,
      colorCount: colors,
      difficulty: difficulty,
      parMoves: 2,
      initialTubes: tubes,
    );
  }

  static List<List<int>> _deal(int colors, Random rng) {
    final balls = <int>[];
    for (int c = 0; c < colors; c++) {
      for (int k = 0; k < kCap; k++) {
        balls.add(c);
      }
    }
    balls.shuffle(rng);
    final tubes = <List<int>>[];
    for (int t = 0; t < colors; t++) {
      tubes.add(balls.sublist(t * kCap, (t + 1) * kCap));
    }
    tubes.add(<int>[]);
    tubes.add(<int>[]);
    return tubes;
  }

  static bool _isSolved(List<List<int>> tubes) => tubes.every((t) =>
      t.isEmpty || (t.length == kCap && t.every((b) => b == t.first)));
}

/// Depth-first solver with canonical-state deduplication.
/// Tube ORDER is irrelevant to the puzzle, so states are keyed on the
/// sorted multiset of tubes — this collapses the search space massively.
class SortSolver {
  static const int _maxNodes = 150000;

  /// Returns the length of a found solution, or -1 if none found
  /// within the node budget.
  static int solve(List<List<int>> start) {
    final tubes = start.map((t) => List<int>.from(t)).toList();
    final visited = <String>{};
    int nodes = 0;

    bool solved() => tubes.every((t) =>
        t.isEmpty || (t.length == kCap && t.every((b) => b == t.first)));

    String key() {
      final parts = tubes.map((t) => t.join(',')).toList()..sort();
      return parts.join('|');
    }

    bool uniform(List<int> t) => t.every((b) => b == t.first);

    int result = -1;

    bool dfs(int depth, int maxDepth) {
      if (solved()) {
        result = depth;
        return true;
      }
      if (depth >= maxDepth || nodes++ > _maxNodes) return false;
      if (!visited.add(key())) return false;

      // Collect legal moves, then order them: completing pours first.
      final moves = <List<int>>[]; // [from, to, count, priority]
      for (int i = 0; i < tubes.length; i++) {
        final src = tubes[i];
        if (src.isEmpty) continue;
        if (src.length == kCap && uniform(src)) continue; // done tube
        final color = src.last;
        int run = 0;
        for (int k = src.length - 1; k >= 0 && src[k] == color; k--) {
          run++;
        }
        for (int j = 0; j < tubes.length; j++) {
          if (j == i) continue;
          final dst = tubes[j];
          if (dst.length >= kCap) continue;
          if (dst.isNotEmpty && dst.last != color) continue;
          if (dst.isEmpty && run == src.length) continue; // pointless shuffle
          final pour = min(run, kCap - dst.length);
          if (pour <= 0) continue;
          int priority = dst.isEmpty ? 1 : 0;
          if (dst.isNotEmpty && dst.length + pour == kCap) priority = -1;
          moves.add([i, j, pour, priority]);
        }
      }
      moves.sort((a, b) => a[3].compareTo(b[3]));

      for (final m in moves) {
        final src = tubes[m[0]], dst = tubes[m[1]];
        final moved = <int>[];
        for (int k = 0; k < m[2]; k++) {
          moved.add(src.removeLast());
        }
        dst.addAll(moved);
        if (dfs(depth + 1, maxDepth)) return true;
        for (int k = 0; k < m[2]; k++) {
          dst.removeLast();
        }
        src.addAll(moved.reversed);
      }
      return false;
    }

    dfs(0, tubes.length * 12);
    return result;
  }
}
