import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:chc_mvp/core/models/user_model.dart';

part 'vote_model.freezed.dart';
part 'vote_model.g.dart';

@freezed
class VoteModel with _$VoteModel {
  const factory VoteModel({
    required String voterUid,
    required String firstPlaceUid,
    required String secondPlaceUid,
    required String thirdPlaceUid,
    @TimestampConverter() DateTime? votedAt,
  }) = _VoteModel;

  factory VoteModel.fromJson(Map<String, dynamic> json) =>
      _$VoteModelFromJson(json);
}

/// Erreurs de validation d'un vote, vérifiées côté client avant l'envoi
/// (les règles Firestore font la même vérification côté serveur).
class VoteValidationException implements Exception {
  final String message;
  VoteValidationException(this.message);
  @override
  String toString() => message;
}

class VoteValidator {
  /// [allowSelfVote] vient du match courant (option configurable par l'admin).
  static void validate({
    required String voterUid,
    required String firstPlaceUid,
    required String secondPlaceUid,
    required String thirdPlaceUid,
    required bool allowSelfVote,
  }) {
    final choices = [firstPlaceUid, secondPlaceUid, thirdPlaceUid];
    if (choices.toSet().length != 3) {
      throw VoteValidationException(
        'Impossible de voter plusieurs fois pour le même joueur.',
      );
    }
    if (!allowSelfVote && choices.contains(voterUid)) {
      throw VoteValidationException(
        'Vous ne pouvez pas voter pour vous-même pour ce match.',
      );
    }
  }
}
