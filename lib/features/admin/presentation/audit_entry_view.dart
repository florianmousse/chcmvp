import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _fields = {
  'firstName': 'Prénom',
  'lastName': 'Nom',
  'team': 'Équipe',
  'jerseyNumber': 'Numéro de maillot',
  'photoUrl': 'Photo',
  'name': 'Nom',
  'date': 'Date du match',
  'civilDate': 'Date du calendrier',
  'time': 'Heure',
  'opponent': 'Adversaire',
  'isHome': 'À domicile',
  'status': 'État du vote',
  'matchType': 'Type de match',
  'eventName': 'Événement',
  'city': 'Ville',
  'matchDay': 'Journée',
  'matchNumber': 'Numéro du match',
  'presentPlayerIds': 'Joueurs présents',
  'votingOpensAt': 'Ouverture du vote',
  'votingClosesAt': 'Clôture du vote',
  'pointsScale': 'Barème',
  'allowSelfVote': 'Vote pour soi',
  'scoreHome': 'Score domicile',
  'scoreAway': 'Score extérieur',
  'goals': 'Buts',
  'assists': 'Passes décisives',
  'greenCards': 'Cartons verts',
  'yellowCards': 'Cartons jaunes',
  'redCards': 'Cartons rouges',
};
const _values = {
  'upcoming': 'À venir',
  'voting_open': 'Vote ouvert',
  'voting_closed': 'Vote terminé',
  'championship': 'Championnat',
  'friendly': 'Amical',
  'tournament': 'Tournoi',
  'playoff': 'Playoff',
};

String auditActionLabel(Map<String, dynamic> data) {
  final action = data['action'];
  final target = '${data['target'] ?? ''}';
  if (action == 'open_voting') return 'Ouverture automatique du vote';
  if (action == 'close_voting') return 'Clôture automatique du vote';
  if (target.contains('reopen')) return 'Réouverture du vote';
  if (target.contains('reset-vote')) return "Annulation d'un bulletin";
  if (target.contains('invite')) return "Envoi d'une invitation";
  if (target.contains('recompute')) return 'Recalcul des résultats';
  if (target == '/members' || target == '/members/') {
    return "Création d'un membre";
  }
  if (target.endsWith('/email')) return "Changement d'adresse e-mail";
  if (target == '/data' || target == '/data/') {
    return 'Enregistrement de modifications';
  }
  final subject = target.contains('playerStats') || target.endsWith('/stats')
      ? 'des statistiques'
      : target.contains('matches')
      ? "d'un match"
      : target.contains('members') || target.startsWith('users/')
      ? "d'un membre"
      : target.contains('ceremonies')
      ? "d'une cérémonie"
      : target.startsWith('teams/')
      ? "d'une équipe"
      : target.startsWith('opponents/')
      ? "d'un adversaire"
      : 'des données';
  return switch (action) {
    'create' => 'Création $subject',
    'delete' || 'DELETE' => 'Suppression $subject',
    'update' || 'merge' || 'PATCH' || 'PUT' => 'Modification $subject',
    _ =>
      'Action serveur : ${subject.startsWith('des ') ? subject.substring(4) : subject.substring(2)}',
  };
}

String _readable(Object? value, String key) {
  if (value == null) return 'Non renseigné';
  if (key == 'photoUrl') return 'Photo renseignée';
  if (value is Timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate().toLocal());
  }
  if (value is bool) return value ? 'Oui' : 'Non';
  if (value is List) return '${value.length} joueur(s)';
  if (key == 'pointsScale' && value is Map) {
    return '${value['first']} / ${value['second']} / ${value['third']} points';
  }
  if (value is Map) return 'Données mises à jour';
  return _values[value.toString()] ?? value.toString();
}

String auditSubjectLabel(Map<String, dynamic> data) {
  final value = data['after'] is Map ? data['after'] : data['before'];
  if (value is! Map) return '';
  if (value['opponent'] is String) {
    final team = value['team'];
    return "Contre ${value['opponent']}${team is String ? ' · $team' : ''}";
  }
  return [
    value['firstName'],
    value['lastName'],
    value['name'],
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
}

/// Display only known business fields; never render arbitrary raw JSON.
List<({String label, String before, String after})> auditChanges(
  Map<String, dynamic> data,
) {
  final before = data['before'] is Map ? data['before'] as Map : const {};
  final after = data['after'] is Map ? data['after'] as Map : const {};
  return [
    for (final field in _fields.entries)
      if ((before.containsKey(field.key) || after.containsKey(field.key)) &&
          before[field.key].toString() != after[field.key].toString())
        (
          label: field.value,
          before: _readable(before[field.key], field.key),
          after: _readable(after[field.key], field.key),
        ),
  ];
}

class AuditEntryCard extends StatelessWidget {
  const AuditEntryCard({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (status, icon, color) = switch (data['status']) {
      'success' => ('Réussie', Icons.check_circle_outline, colors.primary),
      'failed' => ('Échec', Icons.error_outline, colors.error),
      _ => ('Résultat inconnu', Icons.hourglass_empty, colors.onSurfaceVariant),
    };
    final at = data['at'];
    final time = at is Timestamp
        ? DateFormat('dd/MM/yyyy à HH:mm:ss').format(at.toDate().toLocal())
        : 'Date indisponible';
    final name = data['actorName'] is String
        ? (data['actorName'] as String).trim()
        : '';
    final changes = auditChanges(data);
    final subject = auditSubjectLabel(data);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ExpansionTile(
        leading: Icon(icon, color: color, semanticLabel: status),
        title: Text(
          auditActionLabel(data),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${subject.isEmpty ? '' : '$subject\n'}${name.isEmpty ? 'Auteur non renseigné' : name}\n$time\n$status${data['reviewSpaceUid'] != null ? ' · Espace de validation' : ''}',
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['status'] == 'failed')
            const Text(
              'Des effets partiels sont possibles. Vérifier le résultat avant de recommencer.',
            ),
          if (data['status'] != 'success' && data['status'] != 'failed')
            const Text(
              "L'action peut être en cours ou avoir été interrompue. Ce statut ne confirme pas sa réussite.",
            ),
          if (changes.isEmpty)
            const Text(
              'Aucun détail de modification conservé pour cette action.',
            ),
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    change.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Avant : ${change.before}'),
                  Text('Après : ${change.after}'),
                ],
              ),
            ),
          const Divider(),
          SelectableText(
            'Référence : ${data['target'] ?? 'Non renseignée'}\n'
            'Origine : ${data['source'] == 'transaction' ? 'Modification enregistrée' : 'Requête au serveur'}'
            '${data['httpStatus'] is int ? '\nCode de réponse : ${data['httpStatus']}' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
