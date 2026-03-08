import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Container de página com padding e largura máxima
/// Responsivo para desktop e mobile
class PageContainer extends StatelessWidget {
  final Widget child;
  final bool centered;
  final double maxWidth;

  const PageContainer({
    super.key,
    required this.child,
    this.centered = true,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding(context),
        vertical: 32,
      ),
      child: centered
          ? Center(
              child: SingleChildScrollView(
                child: child,
              ),
            )
          : SingleChildScrollView(
              child: child,
            ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 20;
    if (width < 900) return 40;
    return 64;
  }
}
