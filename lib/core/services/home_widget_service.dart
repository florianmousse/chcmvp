import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:chc_mvp/core/models/match_model.dart';

/// Groupe d'app Android utilisé par home_widget pour identifier les
/// SharedPreferences partagées entre Flutter et les widgets natifs.
const _androidAppGroupId = 'fr.florianmousse.chcmvp';

/// Service qui pousse les données vers les widgets Android de l'écran d'accueil.
class HomeWidgetService {
  /// À appeler une fois au démarrage pour configurer le groupe.
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_androidAppGroupId);
  }

  /// Met à jour le widget « Prochain match ».
  static Future<void> updateNextMatch(MatchModel? match) async {
    if (match != null) {
      final date = DateFormat('EEEE d MMMM', 'fr_FR').format(match.date);
      final time = DateFormat('HH:mm', 'fr_FR').format(match.date);
      await HomeWidget.saveWidgetData(
        'next_match_opponent',
        'vs ${match.opponent}',
      );
      await HomeWidget.saveWidgetData('next_match_date', '📅 $date');
      await HomeWidget.saveWidgetData('next_match_time', '🕐 $time');
    } else {
      await HomeWidget.saveWidgetData(
        'next_match_opponent',
        'Aucun match prévu',
      );
      await HomeWidget.saveWidgetData('next_match_date', '');
      await HomeWidget.saveWidgetData('next_match_time', '');
    }
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'fr.florianmousse.chcmvp.NextMatchWidgetProvider',
    );
  }

  /// Met à jour le widget « Mon classement ».
  static Future<void> updateRanking({
    required int position,
    required int totalPoints,
    required int matchesPlayed,
  }) async {
    final suffix = position == 1 ? 'er' : 'e';
    await HomeWidget.saveWidgetData('ranking_position', '$position');
    await HomeWidget.saveWidgetData('ranking_suffix', suffix);
    await HomeWidget.saveWidgetData(
      'ranking_points',
      '$totalPoints pts · $matchesPlayed matchs',
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'fr.florianmousse.chcmvp.RankingWidgetProvider',
    );
  }

  /// Met à jour le widget « Dernier résultat ».
  static Future<void> updateLastResult({
    required MatchModel match,
    String? mvpName,
  }) async {
    // Score
    final hasScore = match.scoreHome != null && match.scoreAway != null;
    final scoreLabel = hasScore
        ? '${match.scoreHome} - ${match.scoreAway}'
        : '-';
    String resultEmoji = '';
    if (hasScore) {
      if (match.scoreHome! > match.scoreAway!) {
        resultEmoji = ' ✅';
      } else if (match.scoreHome! < match.scoreAway!) {
        resultEmoji = ' ❌';
      } else {
        resultEmoji = ' 🤝';
      }
    }

    await HomeWidget.saveWidgetData(
      'last_result_score',
      '$scoreLabel$resultEmoji',
    );
    await HomeWidget.saveWidgetData(
      'last_result_opponent',
      'vs ${match.opponent}',
    );
    await HomeWidget.saveWidgetData(
      'last_result_mvp',
      mvpName != null ? '🏆 MVP : $mvpName' : '',
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'fr.florianmousse.chcmvp.LastResultWidgetProvider',
    );
  }
}
