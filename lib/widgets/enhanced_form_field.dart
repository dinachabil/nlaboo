import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/error_handler.dart';

/// Enhanced form field with better validation feedback and error handling
class EnhancedFormField extends StatefulWidget {
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
  final bool showValidationFeedback;
  final Duration validationDebounce;

  const EnhancedFormField({
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
    this.showValidationFeedback = true,
    this.validationDebounce = const Duration(milliseconds: 500),
  });

  @override
  State<EnhancedFormField> createState() => _EnhancedFormFieldState();
}

class _EnhancedFormFieldState extends State<EnhancedFormField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _hasFocus = false;
  String? _errorText;
  String? _lastValidationError;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(EnhancedFormField oldWidget) {
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
      _controller.addListener(_onTextChanged);
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

    // Validate on focus loss if we have a validator
    if (!_focusNode.hasFocus &&
        widget.validator != null &&
        widget.showValidationFeedback) {
      _validateField();
    }
  }

  void _onTextChanged() {
    if (widget.showValidationFeedback && widget.validator != null) {
      _debouncedValidate();
    }

    widget.onChanged?.call(_controller.text);
  }

  void _debouncedValidate() {
    // Cancel any pending validation
    _validationTimer?.cancel();

    // Start new validation after debounce
    _validationTimer = Timer(widget.validationDebounce, () {
      if (mounted) {
        _validateField();
      }
    });
  }

  Timer? _validationTimer;

  void _validateField() {
    if (!mounted || widget.validator == null) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final error = widget.validator!(_controller.text);
      setState(() {
        _errorText = error;
        _lastValidationError = error;
        _isValidating = false;
      });

      // Provide haptic feedback for validation errors
      if (error != null && error != _lastValidationError) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      ErrorHandler.logError(e, null, 'EnhancedFormField._validateField');
      setState(() {
        _errorText = 'Validation error occurred';
        _isValidating = false;
      });
    }
  }

  void _announceFocus() {
    final label = widget.semanticLabel ?? widget.labelText ?? 'Text field';
    // In a real implementation, you would use platform-specific accessibility services
    debugPrint('Focus entered: $label');
  }

  @override
  Widget build(BuildContext context) {
    final effectiveErrorText = widget.errorText ?? _errorText;
    final showError =
        effectiveErrorText != null && effectiveErrorText.isNotEmpty;

    final effectiveDecoration = (widget.decoration ?? const InputDecoration())
        .copyWith(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: showError ? effectiveErrorText : null,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isValidating)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              if (widget.suffixIcon != null) widget.suffixIcon!,
            ],
          ),
          contentPadding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: showError
                  ? Theme.of(context).colorScheme.error
                  : _hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: _hasFocus ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: showError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: showError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2,
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

/// Enhanced form with better error handling and validation feedback
class EnhancedForm extends StatefulWidget {
  final Widget child;
  final AutovalidateMode autovalidateMode;
  final VoidCallback? onSubmit;
  final FocusNode? initialFocus;
  final bool showValidationFeedback;
  final Function(String? error)? onValidationError;

  const EnhancedForm({
    super.key,
    required this.child,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onSubmit,
    this.initialFocus,
    this.showValidationFeedback = true,
    this.onValidationError,
  });

  @override
  State<EnhancedForm> createState() => _EnhancedFormState();
}

class _EnhancedFormState extends State<EnhancedForm> {
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

  bool validate() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid && widget.onValidationError != null) {
      // Find first error message
      String? firstError;
      // This is a simplified approach - in practice you'd need to collect errors from all fields
      widget.onValidationError!(firstError);
    }

    return isValid;
  }

  void save() {
    _formKey.currentState?.save();
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
        child: _EnhancedFormScope(
          registerFocusNode: _registerFocusNode,
          unregisterFocusNode: _unregisterFocusNode,
          validate: validate,
          save: save,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Inherited widget to provide enhanced form management
class _EnhancedFormScope extends InheritedWidget {
  final void Function(FocusNode) registerFocusNode;
  final void Function(FocusNode) unregisterFocusNode;
  final bool Function() validate;
  final void Function() save;

  const _EnhancedFormScope({
    required this.registerFocusNode,
    required this.unregisterFocusNode,
    required this.validate,
    required this.save,
    required super.child,
  });

  // Removed unused static method 'of'

  @override
  bool updateShouldNotify(_EnhancedFormScope oldWidget) {
    return registerFocusNode != oldWidget.registerFocusNode ||
        unregisterFocusNode != oldWidget.unregisterFocusNode ||
        validate != oldWidget.validate ||
        save != oldWidget.save;
  }
}
