import 'dart:async';
import 'package:flutter/material.dart';
import '../services/phone_service.dart';
import '../services/localization_service.dart';

/// A standardized PhoneInputField widget that integrates with the PhoneService
/// for auto-formatting, validation, and consistent UI across the app.
///
/// Features:
/// - Country code selection with flag icons
/// - Real-time phone number formatting as you type
/// - Validation using PhoneService
/// - Proper error handling and accessibility
/// - Consistent styling with the app's design system
class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final ValueChanged<PhoneNumber>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool readOnly;
  final String initialCountryCode;
  final bool showCountryFlag;
  final bool showCountryCode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final String? semanticLabel;
  final String? semanticHint;
  final EdgeInsetsGeometry? contentPadding;
  final InputDecoration? decoration;

  const PhoneInputField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.initialCountryCode = 'MA',
    this.showCountryFlag = true,
    this.showCountryCode = true,
    this.textInputAction,
    this.autofocus = false,
    this.semanticLabel,
    this.semanticHint,
    this.contentPadding,
    this.decoration,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  PhoneNumber? _phoneNumber;
  String? _errorText;
  bool _isValidating = false;
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);

    // Initialize with default country
    _initializePhoneNumber();
  }

  @override
  void didUpdateWidget(PhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }

    if (widget.initialCountryCode != oldWidget.initialCountryCode) {
      _initializePhoneNumber();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _validationTimer?.cancel();
    // Cancel any pending debounced validation
    PhoneService.cancelDebouncedValidation();
    super.dispose();
  }

  Future<void> _initializePhoneNumber() async {
    try {
      _phoneNumber = PhoneNumber(
        isoCode: widget.initialCountryCode,
        phoneNumber: '', // Initialize with empty string to prevent validation errors
      );
    } catch (e) {
      debugPrint('Failed to initialize phone number: $e');
      _phoneNumber = PhoneNumber(
        isoCode: 'MA',
        phoneNumber: '',
      );
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Validate on focus loss
      _validatePhoneNumber();
    }
  }

  void _onTextChanged() {
    // Sanitize input before validation to prevent injection attacks
    final sanitizedInput = _sanitizeInput(_controller.text);

    // Use the optimized debounced validation from PhoneService with security enhancements
    PhoneService.debouncedValidate(
      sanitizedInput,
      widget.initialCountryCode,
      (error) {
        if (mounted) {
          setState(() {
            _errorText = error;
            _isValidating = false;
          });
        }
      },
      clientId: _getClientId(), // Add client identification for rate limiting
    );

    // Also trigger local validation timer for UI feedback
    _validationTimer?.cancel();
    setState(() => _isValidating = true);
    _validationTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    });
  }

  /// Sanitize input to prevent XSS and injection attacks
  String _sanitizeInput(String input) {
    // Remove any HTML tags and script content
    final sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '')
                          .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
                          .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // Limit input length to prevent buffer overflow attacks
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  /// Get client identifier for rate limiting (could be user ID, device ID, etc.)
  String? _getClientId() {
    // In a real app, this would be a proper client identifier
    // For now, return null to disable rate limiting for UI components
    return null;
  }

  Future<void> _validatePhoneNumber() async {
    if (!mounted || _controller.text.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    try {
      // Sanitize input before validation
      final sanitizedInput = _sanitizeInput(_controller.text);
      final error = await PhoneService.validatePhoneNumber(
        sanitizedInput,
        clientId: _getClientId(),
      );
      setState(() {
        _errorText = error;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _errorText = LocalizationService.tr('phone_validation_error');
        _isValidating = false;
      });
    }
  }

  void _onPhoneNumberChanged(PhoneNumber phoneNumber) {
    _phoneNumber = phoneNumber;
    widget.onChanged?.call(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveErrorText = widget.errorText ?? _errorText;
    final showError = effectiveErrorText != null && effectiveErrorText.isNotEmpty;

    final effectiveDecoration = (widget.decoration ?? const InputDecoration())
        .copyWith(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: showError ? effectiveErrorText : null,
          helperText: widget.helperText,
          contentPadding: widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: showError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
              width: 1,
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
      label: widget.semanticLabel ?? widget.labelText ?? 'Phone number field',
      hint: widget.semanticHint ?? widget.hintText ?? 'Enter your phone number',
      textField: true,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      focusable: true,
      focused: _focusNode.hasFocus,
      child: Stack(
        children: [
          InternationalPhoneNumberInput(
            onInputChanged: (PhoneNumber number) {
              if (number.phoneNumber != null && number.phoneNumber!.isNotEmpty) {
                _onPhoneNumberChanged(number);
              }
            },
            onInputValidated: (bool value) {
              // Handle validation callback if needed
            },
            onFieldSubmitted: widget.onSubmitted,
            onSaved: (PhoneNumber? number) {
              // Handle save if needed
            },
            selectorConfig: SelectorConfig(
              selectorType: PhoneInputSelectorType.DROPDOWN,
              showFlags: widget.showCountryFlag,
              setSelectorButtonAsPrefixIcon: true,
              leadingPadding: 16,
            ),
            ignoreBlank: true, // Prevent validation on empty input
            autoValidateMode: AutovalidateMode.disabled,
            selectorTextStyle: Theme.of(context).textTheme.bodyLarge,
            initialValue: _phoneNumber,
            textFieldController: _controller,
            focusNode: _focusNode,
            formatInput: true,
            keyboardType: TextInputType.phone,
            inputDecoration: effectiveDecoration,
            spaceBetweenSelectorAndTextField: 0,
            autoFocus: widget.autofocus,
            autoFocusSearch: false,
            countries: const ['MA', 'FR', 'ES', 'GB', 'US', 'CA', 'DE', 'IT', 'BE', 'NL'],
          ),
          if (_isValidating)
            Positioned(
              right: 48, // Account for country selector
              top: 0,
              bottom: 0,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
