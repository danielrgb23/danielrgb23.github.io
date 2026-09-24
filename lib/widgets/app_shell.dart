import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/contact_screen.dart';
import '../screens/hero_screen.dart';
import '../screens/missions_screen.dart';
import '../screens/stages_screen.dart';
import '../screens/status_screen.dart';
import '../theme/app_theme.dart';
import 'achievement_toast.dart';
import 'background_fx.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final Set<int> _visited = {0};
  final _focusNode = FocusNode();

  static const _sections = ['HOME', 'STATUS', 'MISSÕES', 'FASES', 'CONTATO'];
  static const _sectionIcons = [
    Icons.videogame_asset,
    Icons.bar_chart_rounded,
    Icons.list_alt_rounded,
    Icons.grid_view_rounded,
    Icons.forum_rounded,
  ];

  static const _konami = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];
  int _konamiProgress = 0;

  void _goTo(int i) {
    if (i < 0 || i >= _sections.length) return;
    setState(() {
      _index = i;
      _visited.add(i);
    });
    if (i == _sections.length - 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          AchievementToast.show(
            context,
            '🏆 CONQUISTA DESBLOQUEADA:\nChegou até o fim da run!',
          );
        }
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == _konami[_konamiProgress]) {
      _konamiProgress++;
    } else {
      _konamiProgress = (key == _konami[0]) ? 1 : 0;
    }
    if (_konamiProgress == _konami.length) {
      _konamiProgress = 0;
      AchievementToast.show(context, '🎮 KONAMI CODE! +100 XP');
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 640;

    final screens = [
      HeroScreen(onStart: () => _goTo(1)),
      const StatusScreen(),
      const MissionsScreen(),
      const StagesScreen(),
      const ContactScreen(),
    ];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: BackgroundFx()),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    sections: _sections,
                    index: _index,
                    visited: _visited,
                    isCompact: isCompact,
                    onSelect: _goTo,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        final v = details.primaryVelocity ?? 0;
                        if (v < -250) {
                          _goTo(_index + 1);
                        } else if (v > 250) {
                          _goTo(_index - 1);
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: SingleChildScrollView(
                          key: ValueKey(_index),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 32,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 900),
                              child: screens[_index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isCompact
            ? BottomNavigationBar(
                currentIndex: _index,
                onTap: _goTo,
                backgroundColor: AppColors.bgPanel,
                selectedItemColor: AppColors.cyan,
                unselectedItemColor: AppColors.textDim,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 10,
                unselectedFontSize: 10,
                items: [
                  for (var i = 0; i < _sections.length; i++)
                    BottomNavigationBarItem(
                      icon: Icon(_sectionIcons[i]),
                      label: _sections[i],
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.sections,
    required this.index,
    required this.visited,
    required this.isCompact,
    required this.onSelect,
  });

  final List<String> sections;
  final int index;
  final Set<int> visited;
  final bool isCompact;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final progress = visited.length / sections.length;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xD90D0221),
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'D_R23>',
                style: AppText.pixel.copyWith(fontSize: 12, color: AppColors.gold),
              ),
              if (!isCompact)
                Row(
                  children: List.generate(sections.length, (i) {
                    final active = i == index;
                    return Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: InkWell(
                        onTap: () => onSelect(i),
                        child: Text(
                          sections[i],
                          style: AppText.mono.copyWith(
                            fontSize: 13,
                            color: active ? AppColors.cyan : AppColors.textDim,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: AppColors.bgPanel,
                valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
