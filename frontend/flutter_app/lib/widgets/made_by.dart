import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// "Created by HAMZl", linking to the author's GitHub profile.
class MadeByCredit extends StatelessWidget {
  const MadeByCredit({super.key, this.color, this.linkColor});

  final Color? color;
  final Color? linkColor;

  static final Uri url = Uri.parse(AppConfig.authorUrl);

  Future<void> _open(BuildContext context) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open ${AppConfig.authorUrl}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = color ?? Theme.of(context).textTheme.bodyMedium?.color;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Created by ', style: TextStyle(color: text)),
        Semantics(
          link: true,
          child: InkWell(
            key: const Key('author-link'),
            borderRadius: BorderRadius.circular(6),
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 16, color: linkColor ?? text),
                  const SizedBox(width: 4),
                  Text(
                    AppConfig.author,
                    style: TextStyle(
                      color: linkColor ?? text,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      decorationColor: linkColor ?? text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(' on GitHub', style: TextStyle(color: text)),
      ],
    );
  }
}
