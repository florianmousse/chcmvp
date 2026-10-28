import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chc_mvp/core/config/club_config.dart';

/// Le même dessin vectoriel sur Android et le web, quelle que soit la densité.
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      clubLogoAssetPath,
      fit: BoxFit.contain,
      semanticsLabel: clubName,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.sports_hockey,
        size: size * .75,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
