import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/core/navigation/navigator_key.dart';

class ReviewModeBanner extends ConsumerWidget {
  const ReviewModeBanner({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(reviewSpaceUidProvider) == null) return child;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Validation · données de démonstration\nNotifications coupées · invitations simulées',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  if (ref.watch(accountProfileProvider).value?.isAdmin == true)
                    TextButton(
                      onPressed: () {
                        rootNavigatorKey.currentState?.popUntil(
                          (route) => route.isFirst,
                        );
                        ref.read(inspectedReviewSpaceProvider.notifier).state =
                            null;
                      },
                      child: const Text('Revenir au club'),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
