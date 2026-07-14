import 'package:flutter/material.dart';

class FloatingWindowCloseScope extends InheritedWidget {
  final VoidCallback close;

  const FloatingWindowCloseScope({
    super.key,
    required this.close,
    required super.child,
  });

  static VoidCallback? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FloatingWindowCloseScope>()
        ?.close;
  }

  @override
  bool updateShouldNotify(FloatingWindowCloseScope oldWidget) =>
      close != oldWidget.close;
}

class FloatingWindow extends StatefulWidget {
  final String windowId;
  final String title;
  final Widget child;
  final Size initialSize;
  final Offset initialPosition;
  final bool isMinimized;
  final VoidCallback onMinimize;
  final VoidCallback onClose;
  final VoidCallback onMove;
  final void Function(Offset) onPositionChanged;
  final void Function(Size) onSizeChanged;

  const FloatingWindow({
    super.key,
    required this.windowId,
    required this.title,
    required this.child,
    required this.initialSize,
    required this.initialPosition,
    required this.isMinimized,
    required this.onMinimize,
    required this.onClose,
    required this.onMove,
    required this.onPositionChanged,
    required this.onSizeChanged,
  });

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  Offset _position = Offset.zero;
  Size _size = const Size(560, 420);

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _size = widget.initialSize;
  }

  @override
  void didUpdateWidget(FloatingWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPosition != widget.initialPosition) {
      _position = widget.initialPosition;
    }
    if (oldWidget.initialSize != widget.initialSize) {
      _size = widget.initialSize;
    }
  }

  void _updatePosition(Offset delta) {
    setState(() {
      _position = Offset(
        (_position.dx + delta.dx).clamp(0, double.infinity),
        (_position.dy + delta.dy).clamp(0, double.infinity),
      );
    });
    widget.onPositionChanged(_position);
    widget.onMove();
  }

  void _updateSize(Offset delta) {
    setState(() {
      _size = Size(
        (_size.width + delta.dx).clamp(300, 1200),
        (_size.height + delta.dy).clamp(200, 900),
      );
    });
    widget.onSizeChanged(_size);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: SizedBox(
        width: _size.width,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(10),
          color: cs.surface,
          surfaceTintColor: cs.surfaceTint,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitleBar(cs),
                if (!widget.isMinimized)
                  SizedBox(
                    height: _size.height - 36,
                    child: Stack(
                      children: [
                        FloatingWindowCloseScope(
                          close: widget.onClose,
                          child: widget.child,
                        ),
                        _buildResizeHandle(cs),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(ColorScheme cs) {
    return GestureDetector(
      onPanUpdate: (details) => _updatePosition(details.delta),
      child: Container(
        height: 36,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          children: [
            Icon(Icons.drag_indicator, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                widget.isMinimized ? Icons.maximize : Icons.minimize,
                size: 14,
              ),
              onPressed: widget.onMinimize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashRadius: 14,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 14),
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashRadius: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle(ColorScheme cs) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: (details) => _updateSize(details.delta),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(120),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Icon(Icons.drag_handle, size: 12, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
