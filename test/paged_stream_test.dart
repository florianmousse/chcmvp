import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/services/paged_stream.dart';

void main() {
  test(
    'pages retain history, rebuild shifted boundaries and cancel listeners',
    () async {
      final sources = <String?, StreamController<DataPage<String>>>{};
      final snapshots = <List<String>>[];
      final subscription = watchPages<String>((cursor) {
        final controller = StreamController<DataPage<String>>();
        sources[cursor] = controller;
        return controller.stream;
      }).listen(snapshots.add);
      sources[null]!.add(const DataPage(['a', 'b'], 'b'));
      await Future<void>.delayed(Duration.zero);
      expect(snapshots, isEmpty);
      sources['b']!.add(const DataPage(['c', 'd'], null));
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last, ['a', 'b', 'c', 'd']);
      sources[null]!.add(const DataPage(['a'], 'a'));
      await Future<void>.delayed(Duration.zero);
      expect(sources['b']!.hasListener, isFalse);
      expect(snapshots.length, 1);
      sources['a']!.add(const DataPage(['c', 'd'], null));
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last, ['a', 'c', 'd']);
      sources['a']!.add(const DataPage(['c', 'changed'], null));
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last, ['a', 'c', 'changed']);
      await subscription.cancel();
      expect(sources.values.every((s) => !s.hasListener), isTrue);
      for (final source in sources.values) {
        await source.close();
      }
    },
  );
}
