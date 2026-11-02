import 'package:flutter/foundation.dart';

class WebPush {
  static final subscribedUid = ValueNotifier<String?>(null);
  static bool get needsInstall => false;
  static bool get configured => false;
  static bool get dismissed => true;
  static String get permission => 'unsupported';
  static String? takeTarget() => null;
  static void dismiss() {}
  static Future<String> requestPermission() async => 'unsupported';
  static Future<bool> supported() async => false;
  static Future<void> sync(String uid) async {}
  static Future<void> disconnect() async {}
}
