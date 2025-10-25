import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that provides keyboard navigation support
class KeyboardNavigationWrapper extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final bool enableArrowNavigation;
  final bool enableTabNavigation;
  final VoidCallback? onEnterPressed;
  final VoidCallback? onEscapePressed;
  final ValueChanged<FocusNode>? onFocusChanged;

  const KeyboardNavigationWrapper({
    super.key,
    required this.child,
    this.focusNode,
    this.enableArrowNavigation = true,
    this.enableTabNavigation = true,
    this.onEnterPressed,
    this.onEscapePressed,
    this.onFocusChanged,
  });

  @override
  State<KeyboardNavigationWrapper> createState() =>
      _KeyboardNavigationWrapperState();
}

class _KeyboardNavigationWrapperState extends State<KeyboardNavigationWrapper> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(KeyboardNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    widget.onFocusChanged?.call(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        widget.onEnterPressed?.call();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape:
        widget.onEscapePressed?.call();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        if (widget.enableArrowNavigation) {
          _navigateToPrevious();
          return KeyEventResult.handled;
        }
        break;

      case LogicalKeyboardKey.arrowDown:
        if (widget.enableArrowNavigation) {
          _navigateToNext();
          return KeyEventResult.handled;
        }
        break;

      case LogicalKeyboardKey.arrowLeft:
        if (widget.enableArrowNavigation) {
          _navigateToPrevious();
          return KeyEventResult.handled;
        }
        break;

      case LogicalKeyboardKey.arrowRight:
        if (widget.enableArrowNavigation) {
          _navigateToNext();
          return KeyEventResult.handled;
        }
        break;

      case LogicalKeyboardKey.tab:
        if (widget.enableTabNavigation) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _navigateToPrevious();
          } else {
            _navigateToNext();
          }
          return KeyEventResult.handled;
        }
        break;
    }

    return KeyEventResult.ignored;
  }

  void _navigateToNext() {
    final currentScope = FocusScope.of(context);
    currentScope.nextFocus();
  }

  void _navigateToPrevious() {
    final currentScope = FocusScope.of(context);
    currentScope.previousFocus();
  }
}

/// A mixin that provides keyboard navigation for lists
mixin KeyboardNavigableListMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _listFocusNode;
  int _focusedIndex = -1;

  void initializeKeyboardNavigation({
    FocusNode? focusNode,
    int initialIndex = -1,
  }) {
    _listFocusNode = focusNode ?? FocusNode();
    _focusedIndex = initialIndex;
  }

  void disposeKeyboardNavigation() {
    _listFocusNode?.dispose();
  }

  Widget wrapListItem({
    required Widget child,
    required int index,
    required VoidCallback onPressed,
    VoidCallback? onEnterPressed,
    VoidCallback? onEscapePressed,
  }) {
    return KeyboardNavigationWrapper(
      focusNode: index == _focusedIndex ? _listFocusNode : null,
      onEnterPressed: onEnterPressed ?? onPressed,
      onEscapePressed: onEscapePressed,
      onFocusChanged: (node) {
        if (node.hasFocus) {
          setState(() {
            _focusedIndex = index;
          });
        }
      },
      child: child,
    );
  }

  void moveFocusToIndex(int index) {
    setState(() {
      _focusedIndex = index;
    });
    _listFocusNode?.requestFocus();
  }

  int get focusedIndex => _focusedIndex;
}

/// Extension to add keyboard navigation to common widgets
extension KeyboardNavigationExtensions on Widget {
  /// Wrap widget with keyboard navigation support
  Widget withKeyboardNavigation({
    FocusNode? focusNode,
    bool enableArrowNavigation = true,
    bool enableTabNavigation = true,
    VoidCallback? onEnterPressed,
    VoidCallback? onEscapePressed,
    ValueChanged<FocusNode>? onFocusChanged,
  }) {
    return KeyboardNavigationWrapper(
      focusNode: focusNode,
      enableArrowNavigation: enableArrowNavigation,
      enableTabNavigation: enableTabNavigation,
      onEnterPressed: onEnterPressed,
      onEscapePressed: onEscapePressed,
      onFocusChanged: onFocusChanged,
      child: this,
    );
  }

  /// Make widget focusable with keyboard navigation
  Widget focusable({
    FocusNode? focusNode,
    VoidCallback? onEnterPressed,
    VoidCallback? onEscapePressed,
  }) {
    return KeyboardNavigationWrapper(
      focusNode: focusNode,
      onEnterPressed: onEnterPressed,
      onEscapePressed: onEscapePressed,
      child: this,
    );
  }
}

/// A focusable button that supports keyboard navigation
class FocusableButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  const FocusableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardNavigationWrapper(
      focusNode: focusNode,
      onEnterPressed: onPressed,
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: InkWell(onTap: onPressed, autofocus: autofocus, child: child),
      ),
    );
  }
}

/// A focusable card that supports keyboard navigation
class FocusableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;

  const FocusableCard({
    super.key,
    required this.child,
    this.onPressed,
    this.focusNode,
    this.semanticLabel,
    this.padding,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardNavigationWrapper(
      focusNode: focusNode,
      onEnterPressed: onPressed,
      child: Semantics(
        label: semanticLabel,
        button: onPressed != null,
        enabled: onPressed != null,
        child: Card(
          color: color,
          margin: EdgeInsets.zero,
          shape: borderRadius != null
              ? RoundedRectangleBorder(borderRadius: borderRadius!)
              : null,
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}
