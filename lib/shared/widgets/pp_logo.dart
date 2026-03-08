import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Logo tipográfica do Palace Pulse
/// Design simples e moderno para uso na UI
class PPLogo extends StatelessWidget {
  final bool showTagline;
  final double? fontSize;
  final Color? color;

  const PPLogo({
    super.key,
    this.showTagline = true,
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [effectiveColor, effectiveColor.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            AppConstants.appName,
            style: GoogleFonts.dmSans(
              fontSize: fontSize ?? 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            AppConstants.appTagline,
            style: GoogleFonts.dmSans(
              fontSize: (fontSize ?? 32) * 0.4,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
