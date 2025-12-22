import 'package:flutter/material.dart';

class AdaptiveIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AdaptiveIcon({
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Image.asset(
      isDarkMode
          ? 'assets/icons/ICONNutriSyncDrack.png'
          : 'assets/icons/ICONNutriSyncBlack.png',
      width: size,
      height: size,
      color: color,
      semanticLabel: semanticLabel,
      fit: BoxFit.contain,
    );
  }
}

class NutriSyncLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final String? semanticLabel;

  const NutriSyncLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Image.asset(
      isDarkMode
          ? 'assets/icons/ICONNutriSyncDrack.png'
          : 'assets/icons/ICONNutriSyncBlack.png',
      width: width,
      height: height,
      color: color,
      semanticLabel: semanticLabel,
      fit: BoxFit.contain,
    );
  }
}
