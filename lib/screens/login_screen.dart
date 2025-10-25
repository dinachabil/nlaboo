import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../services/error_handler.dart';
import '../services/feedback_service.dart';
import '../widgets/enhanced_error_boundary.dart';
import '../widgets/loading_overlay.dart';
import '../utils/validators.dart';
import '../utils/responsive_utils.dart';
import '../constants/translation_keys.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Logger _logger = Logger();
  bool _obscurePassword = true;
  // Local submitting flag to disable the submit button while submitting.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changeLanguage(String languageCode) async {
    await LocalizationService().loadLanguage(languageCode);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      // Debug: Log JWT token

      // Show success feedback
      context.showSuccess(LocalizationService.tr('login_success'));

      context.go('/home');
    } catch (error, st) {
      if (!mounted) return;

      // Log the error with context
      ErrorHandler.logError(error, st, 'LoginScreen._login');

      // Show error feedback with retry option
      context.showError(error, onRetry: () => _login());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate(TranslationKeys.language)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: const Text('🇺🇸'),
                onTap: () {
                  _changeLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Français'),
                leading: const Text('🇫🇷'),
                onTap: () {
                  _changeLanguage('fr');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('العربية'),
                leading: const Text('🇲🇦'),
                onTap: () {
                  _changeLanguage('ar');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = context.isDesktop; // Use responsive utils
    final isMediumScreen = context.isTablet; // Use responsive utils

    return ScreenErrorBoundary(
      screenName: 'LoginScreen',
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // Language Button
            IconButton(
              icon: const Icon(Icons.language, color: Colors.grey),
              onPressed: () => _showLanguageDialog(context),
              tooltip: 'Language',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isLargeScreen) {
                // Large screen layout: Form on the left, empty space on the right
                return Row(
                  children: [
                    // Left side - Form
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        padding: context.responsivePadding,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                screenHeight - 48, // Account for SafeArea
                            maxWidth: 400,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Header Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(26),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.sports_soccer,
                                      size: context.isMobile ? 50 : 60,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 2),
                                  Text(
                                    LocalizationService().translate(
                                      TranslationKeys.loginTitle,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: context.isMobile ? 24 : 28,
                                        ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  Text(
                                    LocalizationService().translate(
                                      TranslationKeys.loginSubtitle,
                                    ),
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacitySafe(0.7),
                                          fontSize: context.isMobile ? 14 : 16,
                                        ),
                                  ),
                                ],
                              ),

                              SizedBox(height: context.itemSpacing * 3),

                              // Login Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Email Field
                                    Text(
                                      LocalizationService().translate('email'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontSize: context.isMobile
                                                ? 16
                                                : 18,
                                          ),
                                    ),
                                    SizedBox(height: context.itemSpacing * 0.5),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        hintText: LocalizationService()
                                            .translate(TranslationKeys.enterEmail),
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacitySafe(0.6),
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) =>
                                          validateEmail(value),
                                    ),

                                    SizedBox(height: context.itemSpacing * 2),

                                    // Password Field
                                    Text(
                                      LocalizationService().translate(
                                        TranslationKeys.password,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontSize: context.isMobile
                                                ? 16
                                                : 18,
                                          ),
                                    ),
                                    SizedBox(height: context.itemSpacing * 0.5),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        hintText: LocalizationService()
                                            .translate('enter_password'),
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacitySafe(0.6),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacitySafe(0.6),
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            );
                                          },
                                        ),
                                      ),
                                      obscureText: _obscurePassword,
                                      validator: (value) =>
                                          validatePassword(value),
                                    ),

                                    SizedBox(height: context.itemSpacing),

                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          // TODO: Implement forgot password
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: context.isMobile
                                                ? 14
                                                : 16,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: context.itemSpacing * 3),

                                    // Login Button
                                    LoadingButton(
                                      isLoading:
                                          authProvider.isLoading ||
                                          _isSubmitting,
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        elevation: 4,
                                        shadowColor: Theme.of(
                                          context,
                                        ).colorScheme.primary.withAlpha((0.3 * 255).round()),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      height: context.buttonHeight,
                                      child: Text(
                                        LocalizationService().translate(
                                          TranslationKeys.loginButton,
                                        ),
                                        style: TextStyle(
                                          fontSize: context.isMobile ? 16 : 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: context.itemSpacing * 2),

                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacitySafe(0.3),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            'or',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacitySafe(0.6),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacitySafe(0.3),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Sign Up Link
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          LocalizationService().translate(
                                            TranslationKeys.dontHaveAccount,
                                          ),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacitySafe(0.7),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.go('/signup'),
                                          child: Text(
                                            LocalizationService().translate(
                                              TranslationKeys.signupButton,
                                            ),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Right side - Empty space or background
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: Icon(
                            Icons.sports_soccer,
                            size: 200,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacitySafe(0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile/Tablet layout: Centered form
                return Center(
                  child: SingleChildScrollView(
                    padding: context.responsivePadding,
                    child: Container(
                      width: isMediumScreen
                          ? screenWidth * 0.6
                          : double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha(26),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.sports_soccer,
                                    size: context.isMobile ? 50 : 60,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: context.itemSpacing * 2),
                                Text(
                                  LocalizationService().translate(
                                    TranslationKeys.loginTitle,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: context.isMobile ? 24 : 28,
                                      ),
                                ),
                                SizedBox(height: context.itemSpacing * 0.5),
                                Text(
                                  LocalizationService().translate(
                                    TranslationKeys.loginSubtitle,
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacitySafe(0.7),
                                        fontSize: context.isMobile ? 14 : 16,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: context.itemSpacing * 3),

                          // Login Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email Field
                                Text(
                                  LocalizationService().translate(TranslationKeys.email),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: context.isMobile ? 16 : 18,
                                      ),
                                ),
                                SizedBox(height: context.itemSpacing * 0.5),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: LocalizationService().translate(
                                      TranslationKeys.enterEmail,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacitySafe(0.6),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return LocalizationService().translate(
                                        TranslationKeys.emailRequired,
                                      );
                                    }
                                    if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+',
                                    ).hasMatch(value)) {
                                      return LocalizationService().translate(
                                        TranslationKeys.invalidEmail,
                                      );
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: context.itemSpacing * 2),

                                // Password Field
                                Text(
                                  LocalizationService().translate(TranslationKeys.password),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: context.isMobile ? 16 : 18,
                                      ),
                                ),
                                SizedBox(height: context.itemSpacing * 0.5),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    hintText: LocalizationService().translate(
                                      TranslationKeys.enterPassword,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacitySafe(0.6),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacitySafe(0.6),
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        );
                                      },
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return LocalizationService().translate(
                                        TranslationKeys.passwordRequired,
                                      );
                                    }
                                    if (value.length < 6) {
                                      return LocalizationService().translate(
                                        TranslationKeys.passwordTooShort8,
                                      );
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: context.itemSpacing),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // TODO: Implement forgot password
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: context.isMobile ? 14 : 16,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: context.itemSpacing * 3),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: context.buttonHeight,
                                  child: ElevatedButton(
                                    onPressed:
                                        (authProvider.isLoading ||
                                            _isSubmitting)
                                        ? null
                                        : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      disabledBackgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha((0.12 * 255).round()),
                                      disabledForegroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha((0.38 * 255).round()),
                                      elevation: 4,
                                      shadowColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha((0.3 * 255).round()),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child:
                                        (authProvider.isLoading ||
                                            _isSubmitting)
                                        ? SizedBox(
                                            height: 28,
                                            width: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            LocalizationService().translate(
                                              TranslationKeys.loginButton,
                                            ),
                                            style: TextStyle(
                                              fontSize: context.isMobile
                                                  ? 16
                                                  : 18,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(height: context.itemSpacing * 2),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacitySafe(0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacitySafe(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacitySafe(0.3),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Sign Up Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      LocalizationService().translate(
                                        TranslationKeys.dontHaveAccount,
                                      ),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacitySafe(0.7),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/signup'),
                                      child: Text(
                                        LocalizationService().translate(
                                          TranslationKeys.signupButton,
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
