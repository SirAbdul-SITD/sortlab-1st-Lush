// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../game/tube_painter.dart';
import '../game/constants_bridge.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';

class GameScreen extends StatefulWidget {
  final int levelIndex;
  const GameScreen({super.key, required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _victoryCtrl;
  late final Animation<double> _victoryAnim;

  @override
  void initState() {
    super.initState();
    _victoryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _victoryAnim =
        CurvedAnimation(parent: _victoryCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().loadLevel(widget.levelIndex);
    });
  }

  @override
  void dispose() {
    _victoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Consumer<GameState>(builder: (ctx, st, _) {
        if (!st.initialized) {
          return const Center(child: CircularProgressIndicator(color: kAccent));
        }
        if (st.isComplete && !_victoryCtrl.isCompleted) {
          _victoryCtrl.forward();
          if (Preferences.instance.isVibrationEnabled()) {
            HapticFeedback.heavyImpact();
          }
        }
        final doneTubes = st.tubes
            .where((t) => t.length == kCap && t.every((b) => b == t.first))
            .length;
        return Stack(children: [
          SafeArea(
            child: Column(children: [
              _hud(st),
              const SizedBox(height: 4),
              Text(
                st.selected == null
                    ? 'TUBES PURE  $doneTubes / ${st.level.colorCount}'
                    : 'TAP A TUBE TO POUR INTO',
                style: techno(11,
                    color: st.selected == null ? kTextDim : kAccent,
                    letterSpacing: 2),
              ),
              Expanded(child: Center(child: _tubeField(st))),
              _bottomBar(st),
              const SizedBox(height: 12),
            ]),
          ),
          if (st.isComplete) _victory(st),
        ]);
      }),
    );
  }

  Widget _hud(GameState st) {
    final diffColor = st.level.difficulty == 'Easy'
        ? kEasyColor
        : st.level.difficulty == 'Medium'
            ? kMediumColor
            : kHardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kTextDim, size: 16),
          ),
        ),
        const Spacer(),
        Column(children: [
          Text('LEVEL ${st.level.index + 1}',
              style: techno(14, letterSpacing: 3)),
          Text(st.level.difficulty.toUpperCase(),
              style: techno(10, color: diffColor, letterSpacing: 2)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${st.moves}',
              style: techno(18, color: kAccent, weight: FontWeight.w900)),
          Text('POURS · PAR ${st.level.parMoves}',
              style: techno(8, color: kTextDim, letterSpacing: 1.5)),
        ]),
      ]),
    );
  }

  Widget _tubeField(GameState st) {
    final n = st.tubes.length;
    final screen = MediaQuery.of(context).size;
    final perRow = (n / 2).ceil();
    const hGap = 10.0;
    final tubeW =
        ((screen.width - 32 - hGap * (perRow - 1)) / perRow).clamp(30.0, 64.0);
    final tubeH = tubeW * 3.6;

    Widget tube(int i) => GestureDetector(
          onTap: () {
            if (Preferences.instance.isVibrationEnabled()) {
              HapticFeedback.selectionClick();
            }
            st.tapTube(i);
          },
          child: SizedBox(
            width: tubeW,
            height: tubeH,
            child: CustomPaint(
              painter: TubePainter(
                balls: st.tubes[i],
                selected: st.selected == i,
                done: st.tubes[i].length == kCap &&
                    st.tubes[i].every((b) => b == st.tubes[i].first),
              ),
            ),
          ),
        );

    final row1 = List.generate(perRow, (i) => i);
    final row2 = List.generate(n - perRow, (i) => perRow + i);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final i in row1) ...[
              tube(i),
              if (i != row1.last) const SizedBox(width: hGap)
            ]
          ]),
      const SizedBox(height: 18),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final i in row2) ...[
              tube(i),
              if (i != row2.last) const SizedBox(width: hGap)
            ]
          ]),
    ]);
  }

  Widget _bottomBar(GameState st) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionBtn(Icons.undo_rounded, 'UNDO',
              st.canUndo ? () => st.undo() : null),
          const SizedBox(width: 16),
          _actionBtn(Icons.refresh_rounded, 'RESTART', () {
            _victoryCtrl.reset();
            st.restartLevel();
          }),
          const SizedBox(width: 16),
          _actionBtn(Icons.grid_view_rounded, 'LEVELS', () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const LevelSelectScreen()));
          }),
        ],
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: kTextDim, size: 16),
              const SizedBox(width: 6),
              Text(label, style: techno(10, color: kTextDim, letterSpacing: 2)),
            ]),
          ),
        ),
      );

  Widget _victory(GameState st) => Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: ScaleTransition(
            scale: _victoryAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: kAccent.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 4)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccent.withOpacity(0.12),
                    border: Border.all(color: kAccent, width: 2),
                  ),
                  child: const Icon(Icons.science_rounded,
                      color: kAccent, size: 30),
                ),
                const SizedBox(height: 16),
                Text('PERFECT SORT',
                    style: techno(17,
                        color: kAccent,
                        weight: FontWeight.w900,
                        letterSpacing: 4)),
                const SizedBox(height: 6),
                Text('${st.moves} POURS  ·  PAR ${st.level.parMoves}',
                    style: techno(11, color: kTextDim, letterSpacing: 2)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      3,
                      (i) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < st.stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < st.stars ? kStarOn : kStarOff,
                              size: 36,
                            ),
                          )),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: _vBtn('REPLAY', Icons.refresh_rounded, false, () {
                    _victoryCtrl.reset();
                    st.restartLevel();
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _vBtn('NEXT', Icons.arrow_forward_rounded, true,
                          () {
                    _victoryCtrl.reset();
                    if (st.currentLevelIndex < 149) {
                      st.nextLevel();
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => const LevelSelectScreen()));
                    }
                  })),
                ]),
              ]),
            ),
          ),
        ),
      );

  Widget _vBtn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF0C9D7B), Color(0xFF14C99C)])
                : null,
            color: primary ? null : kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.5) : kBorder),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: primary ? kBg : Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: techno(12,
                    color: primary ? kBg : kTextPrimary, letterSpacing: 2)),
          ]),
        ),
      );
}
