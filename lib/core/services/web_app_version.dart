/// Flutter writes these fields to version.json when building the web app.
String? newerWebVersion(String runningVersion, Object? data) {
  if (data is! Map<String, Object?> ||
      data['version'] is! String ||
      data['build_number'] is! String) {
    throw const FormatException('Version web invalide');
  }
  final deployed = '${data['version']}+${data['build_number']}';
  final pattern = RegExp(r'^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$');
  if (!pattern.hasMatch(runningVersion) || !pattern.hasMatch(deployed)) {
    throw const FormatException('Version web invalide');
  }
  final current = runningVersion.split(RegExp(r'[.+]')).map(int.parse).toList();
  final latest = deployed.split(RegExp(r'[.+]')).map(int.parse).toList();
  for (var index = 0; index < 4; index++) {
    final before = current[index];
    final after = latest[index];
    if (after > before) return deployed;
    if (after < before) return null;
  }
  return null;
}
