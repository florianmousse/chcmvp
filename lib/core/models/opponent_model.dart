import 'package:freezed_annotation/freezed_annotation.dart';

part 'opponent_model.freezed.dart';
part 'opponent_model.g.dart';

@freezed
class OpponentModel with _$OpponentModel {
  const factory OpponentModel({
    required String id,
    required String name,
    /// Chemin asset local du logo (ex: 'assets/team_logos/nantes.png').
    String? logoAsset,
  }) = _OpponentModel;

  factory OpponentModel.fromJson(Map<String, dynamic> json) =>
      _$OpponentModelFromJson(json);
}
