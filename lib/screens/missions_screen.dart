import 'package:flutter/material.dart';
import '../data/portfolio_data.dart';
import '../theme/app_theme.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LOG DE MISSÕES', style: AppText.kicker),
        const SizedBox(height: 8),
        Text('ONDE JÁ JOGUEI', style: AppText.h2),
        const SizedBox(height: 8),
        Text('Toque em cada missão pra ver os detalhes.', style: AppText.body),
        const SizedBox(height: 28),
        for (var i = 0; i < quests.length; i++) ...[
          _QuestTile(quest: quests[i], initiallyOpen: i == 0),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 30),
        Text('SIDE QUESTS', style: AppText.kicker),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final s in sideQuests) _Tag(s)],
        ),
      ],
    );
  }
}

class _QuestTile extends StatefulWidget {
  const _QuestTile({required this.quest, this.initiallyOpen = false});
  final Quest quest;
  final bool initiallyOpen;

  @override
  State<_QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends State<_QuestTile> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        border: Border.all(color: _open ? AppColors.cyan : AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '▸',
                      style: AppText.mono.copyWith(
                        color: AppColors.magenta,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          quest.company,
                          style: AppText.mono.copyWith(
                            fontSize: 14.5,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${quest.role}',
                          style: AppText.mono.copyWith(
                            fontSize: 12.5,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    quest.period,
                    style: AppText.mono.copyWith(
                      fontSize: 11.5,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.summary,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final d in quest.details) ...[
                    Text(d, style: AppText.body),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final t in quest.tags) _Tag(t)],
                  ),
                ],
              ),
            ),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppText.mono.copyWith(fontSize: 11, color: AppColors.textDim),
      ),
    );
  }
}
