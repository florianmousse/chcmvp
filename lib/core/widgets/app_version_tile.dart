import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
});

class AppVersionTile extends ConsumerWidget {
  const AppVersionTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: const Icon(Icons.info_outline),
    title: const Text("Version de l'application"),
    subtitle: ref
        .watch(appVersionProvider)
        .when(
          data: (version) => SelectableText(version),
          loading: () => const Text('Chargement…'),
          error: (_, __) => const Text('Version indisponible'),
        ),
  );
}
