import 'package:flutter/material.dart';
import 'package:chc_mvp/core/models/match_model.dart';

Color matchTypeColor(MatchType type) => switch (type) {
  MatchType.championship => const Color(0xFF3865B0),
  MatchType.friendly => const Color(0xFF757575),
  MatchType.playoff => const Color(0xFF2DAA36),
};

class MatchTypeChip extends StatelessWidget {
  const MatchTypeChip({super.key, required this.type});
  final MatchType type;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(
      type == MatchType.friendly
          ? Icons.handshake_outlined
          : type == MatchType.playoff
          ? Icons.emoji_events_outlined
          : Icons.sports_hockey,
      size: 18,
      color: matchTypeColor(type),
    ),
    backgroundColor: matchTypeColor(type).withValues(alpha: .13),
    side: BorderSide(color: matchTypeColor(type).withValues(alpha: .6)),
    label: Text(type.label),
  );
}
