import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

/// A widget for drag to move window.
///
/// When you have hidden the title bar, you can add this widget to move the window position.
///
/// {@tool snippet}
///
/// The sample creates a red box, drag the box to move the window.
///
/// ```dart
/// DragToMoveArea2(
///   child: Container(
///     width: 300,
///     height: 32,
///     color: Colors.red,
///   ),
/// )
/// ```
/// {@end-tool}
class DragToMoveArea2 extends StatelessWidget {
  const DragToMoveArea2({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          WindowManagerPlus.current.startDragging();
        },
        onDoubleTap: () async {
          bool isMaximized = await WindowManagerPlus.current.isMaximized();
          if (!isMaximized) {
            WindowManagerPlus.current.maximize();
          } else {
            WindowManagerPlus.current.unmaximize();
          }
        },
        child: child,
      );
    }
    return child;
  }
}
