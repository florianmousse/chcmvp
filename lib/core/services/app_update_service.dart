import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'web_app_update_stub.dart'
    if (dart.library.html) 'web_app_update_browser.dart'
    as browser;

class AvailableAppUpdate {
  const AvailableAppUpdate({required this.id, required this.isWeb});

  final String id;
  final bool isWeb;
}

final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService(),
);

class AppUpdateService {
  Future<AvailableAppUpdate?> check() async {
    if (kIsWeb) {
      final version = await browser.availableWebVersion();
      return version == null
          ? null
          : AvailableAppUpdate(id: version, isWeb: true);
    }
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final info = await InAppUpdate.checkForUpdate().timeout(
      const Duration(seconds: 10),
    );
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    return AvailableAppUpdate(id: '${info.availableVersionCode}', isWeb: false);
  }

  Future<void> openUpdate(AvailableAppUpdate update) async {
    if (update.isWeb) {
      browser.reloadApp();
      return;
    }
    final info = await PackageInfo.fromPlatform();
    final uri = Uri.https('play.google.com', '/store/apps/details', {
      'id': info.packageName,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Google Play indisponible');
    }
  }
}
