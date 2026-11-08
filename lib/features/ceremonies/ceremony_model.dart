import 'package:cloud_firestore/cloud_firestore.dart';

const ceremonyCategories = {
  'ballon_or': 'Ballon d\'or',
  'golden_boy': 'Golden Boy',
  'puskas': 'Prix Puskás',
  'assist': 'Plus belle passe décisive',
  'custom': 'Prix personnalisé',
};

class Nominee {
  const Nominee({
    required this.id,
    required this.uid,
    required this.name,
    required this.label,
    this.videoId,
  });
  factory Nominee.fromMap(Map<String, dynamic> m) => Nominee(
    id: m['id'],
    uid: m['uid'],
    name: m['name'],
    label: m['label'],
    videoId: m['videoId'],
  );
  final String id, uid, name, label;
  final String? videoId;
}

class AwardResult {
  AwardResult.fromMap(Map<String, dynamic> m)
    : nominee = Nominee.fromMap(m),
      rank = m['rank'],
      points = m['points'];
  final Nominee nominee;
  final int rank, points;
}

class Ceremony {
  Ceremony.fromMap(this.id, Map<String, dynamic> m)
    : title = m['title'],
      category = m['category'],
      status = m['status'],
      topSize = m['topSize'],
      voteCount = m['voteCount'] ?? 0,
      revision = m['revision'] ?? 0,
      allowSelfVote = m['allowSelfVote'] == true,
      voterIds = List<String>.from(m['voterIds']),
      nominees = (m['nominees'] as List)
          .map((n) => Nominee.fromMap(Map<String, dynamic>.from(n)))
          .toList(),
      results = (m['results'] as List? ?? [])
          .map((n) => AwardResult.fromMap(Map<String, dynamic>.from(n)))
          .toList(),
      createdAt = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
  final String id, title, category, status;
  final int topSize, voteCount, revision;
  final bool allowSelfVote;
  final List<String> voterIds;
  final List<Nominee> nominees;
  final List<AwardResult> results;
  final DateTime createdAt;
  String get statusLabel =>
      const {
        'draft': 'Brouillon',
        'open': 'Vote ouvert',
        'closed': 'Révélation disponible',
        'cancelled': 'Annulée',
      }[status] ??
      status;
  List<AwardResult> get revealedTop =>
      results.where((r) => r.rank <= topSize).toList();
  Set<String> get winners => status == 'closed'
      ? results.where((r) => r.rank == 1).map((r) => r.nominee.uid).toSet()
      : {};
}
