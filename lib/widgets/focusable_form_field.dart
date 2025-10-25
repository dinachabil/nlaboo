import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A focusable form field with proper focus management and accessibility
class FocusableFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final String? semanticLabel;
  final String? semanticHint;

  const FocusableFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.decoration,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  State<FocusableFormField> createState() => _FocusableFormFieldState();
}

class _FocusableFormFieldState extends State<FocusableFormField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _hasFocus = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FocusableFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }

    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });

    // Announce focus changes for screen readers
    if (_focusNode.hasFocus) {
      _announceFocus();
    }
  }

  void _announceFocus() {
    final label = widget.semanticLabel ?? widget.labelText ?? 'Text field';
    // In a real implementation, you would use platform-specific accessibility services
    // For now, we'll use a simple approach
    debugPrint('Focus entered: $label');
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = (widget.decoration ?? const InputDecoration())
        .copyWith(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: widget.errorText ?? _errorText,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          contentPadding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: _hasFocus ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        );

    return Semantics(
      label: widget.semanticLabel ?? widget.labelText,
      hint: widget.semanticHint ?? widget.hintText,
      textField: true,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      focusable: true,
      focused: _hasFocus,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        validator: widget.validator,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        autofocus: widget.autofocus,
        decoration: effectiveDecoration,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: widget.enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withAlpha((0.38 * 255).round()),
        ),
      ),
    );
  }
}

/// A form with focus management and keyboard navigation
class FocusableForm extends StatefulWidget {
  final Widget child;
  final AutovalidateMode autovalidateMode;
  final VoidCallback? onSubmit;
  final FocusNode? initialFocus;

  const FocusableForm({
    super.key,
    required this.child,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onSubmit,
    this.initialFocus,
  });

  @override
  State<FocusableForm> createState() => _FocusableFormState();
}

class _FocusableFormState extends State<FocusableForm> {
  final _formKey = GlobalKey<FormState>();
  final _focusNodes = <FocusNode>[];
  int _currentFocusIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.initialFocus?.requestFocus();
    });
  }

  void _registerFocusNode(FocusNode node) {
    if (!_focusNodes.contains(node)) {
      _focusNodes.add(node);
      node.addListener(() => _onFocusChanged(node));
    }
  }

  void _unregisterFocusNode(FocusNode node) {
    _focusNodes.remove(node);
    node.removeListener(() => _onFocusChanged(node));
  }

  void _onFocusChanged(FocusNode node) {
    if (node.hasFocus) {
      _currentFocusIndex = _focusNodes.indexOf(node);
    }
  }

  void _moveToNextField() {
    if (_currentFocusIndex < _focusNodes.length - 1) {
      _focusNodes[_currentFocusIndex + 1].requestFocus();
    } else {
      widget.onSubmit?.call();
    }
  }

  void _moveToPreviousField() {
    if (_currentFocusIndex > 0) {
      _focusNodes[_currentFocusIndex - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: widget.autovalidateMode,
      child: FocusScope(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              _moveToNextField();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.tab) {
              if (HardwareKeyboard.instance.isShiftPressed) {
                _moveToPreviousField();
              } else {
                _moveToNextField();
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: _FocusableFormScope(
          registerFocusNode: _registerFocusNode,
          unregisterFocusNode: _unregisterFocusNode,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Inherited widget to provide form focus management
class _FocusableFormScope extends InheritedWidget {
  final void Function(FocusNode) registerFocusNode;
  final void Function(FocusNode) unregisterFocusNode;

  const _FocusableFormScope({
    required this.registerFocusNode,
    required this.unregisterFocusNode,
    required super.child,
  });

  static _FocusableFormScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FocusableFormScope>();
  }

  @override
  bool updateShouldNotify(_FocusableFormScope oldWidget) {
    return registerFocusNode != oldWidget.registerFocusNode ||
        unregisterFocusNode != oldWidget.unregisterFocusNode;
  }
}


/// Extension to make TextFormField focusable with form management
extension FocusableTextFormFieldExtension on TextFormField {
  Widget focusable() {
    return Builder(
      builder: (context) => _FocusableTextFormField(textFormField: this),
    );
  }
}

class _FocusableTextFormField extends StatefulWidget {
  final TextFormField textFormField;

  const _FocusableTextFormField({required this.textFormField});

  @override
  State<_FocusableTextFormField> createState() =>
      _FocusableTextFormFieldState();
}

class _FocusableTextFormFieldState extends State<_FocusableTextFormField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    final scope = _FocusableFormScope.of(context);
    scope?.registerFocusNode(_focusNode);
  }

  @override
  void dispose() {
    final scope = _FocusableFormScope.of(context);
    scope?.unregisterFocusNode(_focusNode);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create a new TextFormField with the same properties but with our focus node
    // We need to use reflection or create a copy manually since TextFormField doesn't expose getters
    return TextFormField(
      key: widget.textFormField.key,
      controller: widget.textFormField.controller,
      initialValue: widget.textFormField.initialValue,
      focusNode: _focusNode,
      // We can't access the properties directly, so we create a basic TextFormField
      // The original extension was flawed - TextFormField properties aren't accessible
      onChanged: widget.textFormField.onChanged,
      onSaved: widget.textFormField.onSaved,
      validator: widget.textFormField.validator,
      enabled: widget.textFormField.enabled,
      restorationId: widget.textFormField.restorationId,
    );
  }
}
