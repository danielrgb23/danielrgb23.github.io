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

  final _scroll = ScrollController();
  final _keys = List.generate(_sections.length, (_) => GlobalKey());
  bool _achieved = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Active section = last one whose top has passed the viewport's upper third.
    final threshold = MediaQuery.of(context).size.height * 0.35;
    var active = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= threshold) active = i;
    }
    final atBottom = _scroll.hasClients &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 4;
    if (atBottom) active = _sections.length - 1;
    if (active != _index || !_visited.contains(active)) {
      setState(() {
        _index = active;
        _visited.addAll({for (var i = 0; i <= active; i++) i});
      });
    }
    if (active == _sections.length - 1 && !_achieved) {
      _achieved = true;
      AchievementToast.show(
        context,
        '🏆 CONQUISTA DESBLOQUEADA:\nChegou até o fim da run!',
      );
    }
  }

  void _goTo(int i) {
    if (i < 0 || i >= _sections.length) return;
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
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
                    child: SingleChildScrollView(
                      controller: _scroll,
                      child: Column(
                        children: [
                          for (var i = 0; i < screens.length; i++)
                            Container(
                              key: _keys[i],
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 40,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 900),
                                  child: screens[i],
                                ),
                              ),
                            ),
                        ],
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
