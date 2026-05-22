import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

class CustomNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const CustomNotification({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 15,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: CustomNotification(
              message: message,
              type: type,
              onDismiss: () {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
              },
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Timer(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void showSuccess(BuildContext context, String message) =>
      show(context, message, type: NotificationType.success);

  static void showError(BuildContext context, String message) =>
      show(context, message, type: NotificationType.error);

  static void showWarning(BuildContext context, String message) =>
      show(context, message, type: NotificationType.warning);

  static void showInfo(BuildContext context, String message) =>
      show(context, message, type: NotificationType.info);

  @override
  State<CustomNotification> createState() => _CustomNotificationState();
}

class _CustomNotificationState extends State<CustomNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check;
      case NotificationType.error:
        return Icons.close;
      case NotificationType.warning:
        return Icons.priority_high;
      case NotificationType.info:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF10B981);
      case NotificationType.error:
        return const Color(0xFFF43F5E);
      case NotificationType.warning:
        return const Color(0xFFF59E0B);
      case NotificationType.info:
        return const Color(0xFF0EA5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * _scaleAnimation.value),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(40), // Capsule shape
          border: Border.all(
            color: _getColor().withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Color(0xFF1E293B), // Professional Dark
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
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
}
