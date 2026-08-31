import 'package:flutter/material.dart';

/// Affiche le logo local choisi pour un match (voir MatchModel.opponentLogoAsset
/// et le sélecteur dans MatchFormScreen), ou une icône de secours si aucun
/// n'a été choisi — jamais de requête réseau.
class OpponentLogo extends StatelessWidget {
  const OpponentLogo({super.key, required this.logoAssetPath, this.size = 40});

  final String? logoAssetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (logoAssetPath == null) {
      return _fallback(context);
    }
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        logoAssetPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.shield_outlined,
        size: size * 0.55,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
