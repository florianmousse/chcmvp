import 'package:flutter/material.dart';

Future<bool> confirmReopenVoting(
  BuildContext context, {
  bool isTest = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Rouvrir le vote ?'),
        content: Text(
          isTest
              ? 'Les bulletins simulés seront conservés et resteront modifiables. Les résultats du test seront recalculés à sa prochaine clôture, sans effet sur le classement du club.\n\n'
                    'Un admin devra clôturer le vote manuellement. Les admins recevront un rappel toutes les 24 heures.'
              : 'Les votes déjà déposés seront conservés. Pour corriger un bulletin, un admin pourra ensuite le réinitialiser depuis le suivi des votes. '
                    'Les résultats, points et badges de ce match seront recalculés à sa prochaine clôture. '
                    'En attendant, ce match ne comptera plus dans le classement.\n\n'
                    'Un admin devra clôturer le vote manuellement. Les admins recevront un rappel toutes les 24 heures.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rouvrir'),
          ),
        ],
      ),
    ) ??
    false;
