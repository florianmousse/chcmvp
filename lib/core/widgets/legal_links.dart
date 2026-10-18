import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pages HTML publiques, également disponibles avant la connexion.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final page in const {
          'Mentions légales': '/mentions-legales.html',
          'Confidentialité': '/confidentialite.html',
          'Cookies': '/cookies.html',
          'Conditions d'utilisation': '/conditions-utilisation.html',
          'Mes données': '/supprimer-compte.html',
        }.entries)
          TextButton(
            onPressed: () async {
              final opened = await launchUrl(
                Uri.base.resolve(page.value),
                webOnlyWindowName: '_self',
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Impossible d'ouvrir cette page.'),
                  ),
                );
              }
            },
            child: Text(page.key, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
