import 'package:flutter/material.dart';

/// Section « Records de la saison » — grille compacte de 4 stats iconiques.
class SeasonRecordsSection extends StatelessWidget {
  const SeasonRecordsSection({super.key, required this.records});

  final List<SeasonRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Les records de la saison',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: records.map((r) => _RecordTile(record: r)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class SeasonRecord {
  const SeasonRecord({
    required this.emoji,
    required this.label,
    required this.value,
    this.detail,
  });

  final String emoji;
  final String label;
  final String value;
  final String? detail;
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final SeasonRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(record.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.label,
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              record.value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (record.detail != null)
              Text(
                record.detail!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
