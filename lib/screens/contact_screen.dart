import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/portfolio_data.dart';
import '../state/strings.dart';
import '../theme/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('GAME OVER?', style: AppText.kicker, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('CONTINUE?', style: AppText.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          S.contactHint,
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < contactLinks.length; i++)
              OutlinedButton(
                onPressed: () => _open(contactLinks[i].url),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      i.isEven ? AppColors.cyan : AppColors.magenta,
                  side: BorderSide(
                    color: i.isEven ? AppColors.cyan : AppColors.magenta,
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  contactLinks[i].label,
                  style: AppText.button.copyWith(
                    color: i.isEven ? AppColors.cyan : AppColors.magenta,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 50),
        Text(
          S.footer,
          style: AppText.small,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
