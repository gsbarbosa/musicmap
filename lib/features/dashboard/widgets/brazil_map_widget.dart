import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import 'brazil_map_data.dart';

/// Mapa do Brasil com pins por estado
/// Cada banda cadastrada aparece como um pin no estado
class BrazilMapWidget extends StatefulWidget {
  final Map<String, int> stateCounts;
  const BrazilMapWidget({
    super.key,
    required this.stateCounts,
  });

  @override
  State<BrazilMapWidget> createState() => _BrazilMapWidgetState();
}

class _BrazilMapWidgetState extends State<BrazilMapWidget> {
  String? _hoveredState;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Presença no Brasil',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_hoveredState != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_hoveredState: ${widget.stateCounts[_hoveredState] ?? 0} banda(s)',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const padding = 16.0;
                final contentW = constraints.maxWidth - padding * 2;
                final contentH = constraints.maxHeight - padding * 2;
                const aspect = 1000 / 912; // viewBox do br.svg
                double w, h;
                if (contentW / contentH > aspect) {
                  h = contentH;
                  w = contentH * aspect;
                } else {
                  w = contentW;
                  h = contentW / aspect;
                }
                final left = padding + (contentW - w) / 2;
                final top = padding + (contentH - h) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: w,
                      height: h,
                      child: SvgPicture.asset(
                        'assets/maps/br.svg',
                        fit: BoxFit.fill,
                        colorFilter: const ColorFilter.mode(
                          AppColors.border,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    ...widget.stateCounts.entries
                        .where((e) => e.value > 0 && brazilStateCoordinates.containsKey(e.key))
                        .map((e) => _buildPin(
                              state: e.key,
                              count: e.value,
                              left: left,
                              top: top,
                              width: w,
                              height: h,
                            )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPin({
    required String state,
    required int count,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final coords = brazilStateCoordinates[state]!;
    final x = left + coords.$1 * width;
    final y = top + coords.$2 * height;
    final isHovered = _hoveredState == state;

    return Positioned(
      left: x - 12,
      top: y - 24,
      child: GestureDetector(
        onTap: () {},
        onTapDown: (_) => setState(() => _hoveredState = state),
        onTapCancel: () => setState(() => _hoveredState = null),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredState = state),
          onExit: (_) => setState(() => _hoveredState = null),
          child: AnimatedScale(
            scale: isHovered ? 1.15 : 1,
            duration: const Duration(milliseconds: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: count > 9 ? 8 : 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: AppColors.backgroundPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(16, 12),
                  painter: _PinTailPainter(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
