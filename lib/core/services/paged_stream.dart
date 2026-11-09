import 'dart:async';

class DataPage<T> {
  const DataPage(this.items, this.nextCursor);
  final List<T> items;
  final String? nextCursor;
}

/// Rebuild only the following pages when an insertion/deletion moves a boundary.
/// Emit complete snapshots so historical totals never show a partial page load.
Stream<List<T>> watchPages<T>(
  Stream<DataPage<T>> Function(String? cursor) source,
) {
  final pages = <int, DataPage<T>>{};
  final subscriptions = <int, StreamSubscription<DataPage<T>>>{};
  final generations = <int, int>{};
  var stopped = false;
  late StreamController<List<T>> controller;
  late void Function(int, String?) listen;
  listen = (index, cursor) {
    final generation = (generations[index] ?? 0) + 1;
    generations[index] = generation;
    subscriptions[index] = source(cursor).listen(
      (page) {
        if (stopped || generations[index] != generation) return;
        final previous = pages[index];
        pages[index] = page;
        if (previous == null || previous.nextCursor != page.nextCursor) {
          for (final key
              in subscriptions.keys.where((k) => k > index).toList()) {
            generations[key] = (generations[key] ?? 0) + 1;
            unawaited(subscriptions.remove(key)?.cancel());
            pages.remove(key);
          }
          if (page.nextCursor != null) listen(index + 1, page.nextCursor);
        }
        final items = <T>[];
        for (var i = 0; ; i++) {
          final current = pages[i];
          if (current == null) return;
          items.addAll(current.items);
          if (current.nextCursor == null) break;
        }
        controller.add(items);
      },
      onError: (Object error, StackTrace stack) {
        if (!stopped && generations[index] == generation) {
          controller.addError(error, stack);
        }
      },
    );
  };
  controller = StreamController<List<T>>(
    onListen: () => listen(0, null),
    onCancel: () async {
      stopped = true;
      await Future.wait(subscriptions.values.map((s) => s.cancel()));
    },
  );
  return controller.stream;
}
