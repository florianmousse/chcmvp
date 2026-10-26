import 'dart:io';
import 'package:image/image.dart' as img;

// Keep the original club artwork intact. Pre-filter the large transparent PNG
// before Flutter's web renderer scales it to a 48/72 logical-pixel widget.
void main() {
  final source = img.decodePng(File('assets/logo/logo.png').readAsBytesSync());
  if (source == null) throw StateError('Logo PNG illisible');
  for (final density in [1, 2, 3, 4]) {
    final directory = density == 1
        ? 'assets/logo/display'
        : 'assets/logo/display/$density.0x';
    Directory(directory).createSync(recursive: true);
    final resized = img.copyResize(
      source,
      width: 72 * density,
      height: 72 * density,
      interpolation: img.Interpolation.average,
    );
    File('$directory/club.png').writeAsBytesSync(img.encodePng(resized));
  }
  stdout.writeln('Logo : variantes 72, 144, 216 et 288 px générées.');
}
