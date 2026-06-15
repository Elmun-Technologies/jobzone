import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an SVG asset (e.g. a Figma-exported icon or illustration).
///
/// Pass [color] to tint single-color icons; leave it null for multi-color
/// illustrations. Centralizing SVG rendering here means screens never depend on
/// `flutter_svg` directly and tinting/sizing stays consistent.
class JzSvgAsset extends StatelessWidget {
  const JzSvgAsset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.color,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      semanticsLabel: semanticLabel,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
