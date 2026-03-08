import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum PPButtonVariant { primary, secondary, outline }

/// Botão reutilizável do Palace Pulse
/// Variantes: primary (verde), secondary (roxo), outline
class PPButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PPButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const PPButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PPButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
  });

  @override
  State<PPButton> createState() => _PPButtonState();
}

class _PPButtonState extends State<PPButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _controller.forward() : null,
        onTapUp: isEnabled ? (_) => _controller.reverse() : null,
        onTapCancel: isEnabled ? () => _controller.reverse() : null,
        onTap: isEnabled
            ? () {
                _controller.forward();
                Future.delayed(const Duration(milliseconds: 100), () {
                  _controller.reverse();
                  widget.onPressed?.call();
                });
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isEnabled ? 1 : 0.5,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: widget.variant == PPButtonVariant.outline
                  ? const Border.fromBorderSide(
                      BorderSide(color: AppColors.border),
                    )
                  : null,
              boxShadow: widget.variant == PPButtonVariant.primary && isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_foregroundColor),
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 20,
                            color: _foregroundColor,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: _foregroundColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (widget.variant) {
      case PPButtonVariant.primary:
        return AppColors.primary;
      case PPButtonVariant.secondary:
        return AppColors.secondary;
      case PPButtonVariant.outline:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (widget.variant) {
      case PPButtonVariant.primary:
      case PPButtonVariant.secondary:
        return AppColors.backgroundPrimary;
      case PPButtonVariant.outline:
        return AppColors.textPrimary;
    }
  }
}
