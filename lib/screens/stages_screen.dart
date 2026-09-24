import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/portfolio_data.dart';
import '../theme/app_theme.dart';

class StagesScreen extends StatefulWidget {
  const StagesScreen({super.key});

  @override
  State<StagesScreen> createState() => _StagesScreenState();
}

class _StagesScreenState extends State<StagesScreen> {
  final _controller = PageController(viewportFraction: 0.86);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MAPA DE FASES', style: AppText.kicker),
        const SizedBox(height: 8),
        Text('SELECIONE SUA FASE', style: AppText.h2),
        const SizedBox(height: 8),
        Text(
          'Arraste pro lado — projetos pessoais e alguns que ajudei a '
          'construir com outros times.',
          style: AppText.body,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _controller,
            itemCount: stages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _StageCard(stage: stages[i], onOpen: _open),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(stages.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.cyan : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage, required this.onOpen});
  final Stage stage;
  final Future<void> Function(String) onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = stage.isBoss ? AppColors.gold : AppColors.cyan;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: stage.isBoss ? AppColors.bgPanelAlt : AppColors.bgPanel,
        border: Border.all(color: accent.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.18), blurRadius: 24),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.number,
            style: AppText.pixel.copyWith(fontSize: 10, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            stage.title,
            style: AppText.pixel.copyWith(fontSize: 15, color: AppColors.text),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in stage.tags) _Tag(t)],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Text(stage.description, style: AppText.body),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final action in stage.actions)
                OutlinedButton(
                  onPressed: () => onOpen(action.url),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    action.label,
                    style: AppText.button.copyWith(fontSize: 10, color: accent),
                  ),
                ),
            ],
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
