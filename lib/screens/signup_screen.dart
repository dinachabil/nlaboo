import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/localization_service.dart';
import '../services/connectivity_checker.dart';
import '../utils/validators.dart';
import '../utils/responsive_utils.dart';
import '../services/error_handler.dart';
import '../widgets/phone_input_field.dart';
import '../services/phone_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  PhoneNumber? _phoneNumber;
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // Local flag to disable the submit button while a request is in-flight.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateConfirmPasswordValidation);
    _confirmPasswordController.addListener(_updateConfirmPasswordValidation);
  }

  void _updateConfirmPasswordValidation() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateConfirmPasswordValidation);
    _confirmPasswordController.removeListener(_updateConfirmPasswordValidation);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _changeLanguage(String languageCode) async {
    try {
      await LocalizationService().loadLanguage(languageCode);
      // Update the theme provider to persist the language change and update the app locale
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        await themeProvider.setLanguage(languageCode);
      }
    } catch (error) {
      // Handle async gap by checking mounted before using context
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to change language: $error')),
            );
          }
        });
      }
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Language'),
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

  Future<void> _signup() async {
    // Validate synchronously using Form validators before making any API calls.
    if (!_formKey.currentState!.validate()) return;

    // Check backend connectivity before attempting signup
    final connectivityResult = await ConnectivityChecker.checkBackendConnectivity();
    if (connectivityResult != ConnectivityResult.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ConnectivityChecker.getConnectivityMessage(connectivityResult)),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // If user is already logged in, log them out first
      if (authProvider.isAuthenticated) {
        await authProvider.logoutWithConfirmation(context);
      }

      final isConfirmed = await authProvider.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        age: int.parse(_ageController.text.trim()),
        phone: _phoneNumber?.phoneNumber ?? _phoneController.text.trim(),
        gender: _selectedGender,
        role: 'player', // Always default to player role
      );

      if (!mounted) return;

      if (isConfirmed) {
        // User is now logged in with token, navigate to home
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully! Welcome!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Email confirmation required, navigate to login
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created successfully! Please check your email to confirm your account before logging in.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      // Use the standardized error handler for consistent error messages
      final errorMessage = ErrorHandler.userMessage(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = context.isDesktop; // Use responsive utils
    final isMediumScreen = context.isTablet; // Use responsive utils

    // If user is already authenticated, show a message instead of signup form
    if (authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Already Signed In'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'You are already signed in!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'You are currently logged in as ${authProvider.user?.email ?? 'Unknown'}. If you want to create a new account, please logout first.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue to App'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await authProvider.logoutWithConfirmation(context);
                    // After logout, the screen will rebuild and show the signup form
                  },
                  child: const Text('Logout and Create New Account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
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
                          minHeight: screenHeight - 48, // Account for SafeArea
                          maxWidth: 400,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: context.itemSpacing * 4),

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
                                      Icons.person_add,
                                      size: context.isMobile ? 50 : 60,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 2),
                                  Text(
                                    'Create Account',
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
                                    'enter you information here ',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(26),
                                          fontSize: context.isMobile ? 14 : 16,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: context.itemSpacing * 3),

                            // Signup Form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name Field
                                  Text(
                                    LocalizationService.tr('full_name'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
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
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: LocalizationService.tr(
                                        'full_name',
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(26),
                                      ),
                                    ),
                                    validator: (value) => validateName(value),
                                  ),

                                  SizedBox(height: context.itemSpacing * 2),

                                  // Email Field
                                  Text(
                                    LocalizationService.tr('email'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
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
                                      hintText: LocalizationService.tr(
                                        'enter_email',
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(26),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) => validateEmail(value),
                                  ),

                                  SizedBox(height: context.itemSpacing * 2),

                                  // Age Field
                                  Text(
                                    LocalizationService.tr('age'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
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
                                    controller: _ageController,
                                    decoration: InputDecoration(
                                      hintText: LocalizationService.tr('age'),
                                      prefixIcon: Icon(
                                        Icons.calendar_today,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(26),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) => validateAge(value),
                                  ),

                                  SizedBox(height: context.itemSpacing * 2),

                                  // Phone Number Field
                                  Text(
                                    LocalizationService.tr('phone'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: context.isMobile ? 16 : 18,
                                        ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  PhoneInputField(
                                    controller: _phoneController,
                                    onChanged: (phoneNumber) {
                                      setState(() => _phoneNumber = phoneNumber);
                                    },
                                    hintText: LocalizationService.tr('phone'),
                                    initialCountryCode: 'MA',
                                  ),
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  // Phone requirements hint
                                  Container(
                                    padding: EdgeInsets.all(
                                      context.isMobile ? 8 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface.withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withAlpha(51),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizationService.tr(
                                            'phone_requirements',
                                          ),
                                          style: TextStyle(
                                            fontSize: context.isMobile
                                                ? 11
                                                : 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(
                                          height: context.itemSpacing * 0.25,
                                        ),
                                        Text(
                                          '• ${LocalizationService.tr('phone_req_digits')}',
                                          style: TextStyle(
                                            fontSize: context.isMobile
                                                ? 10
                                                : 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(179),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: context.itemSpacing * 2),

                                  // Gender Field
                                  Text(
                                    'Gender',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: context.isMobile ? 16 : 18,
                                        ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedGender,
                                    decoration: InputDecoration(
                                      hintText: 'Select your gender',
                                      prefixIcon: Icon(
                                        Icons.person,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(26),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'male',
                                        child: Text('Male'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'female',
                                        child: Text('Female'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() => _selectedGender = value);
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select your gender';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: context.itemSpacing * 2),

                                  // Password Field
                                  Text(
                                    LocalizationService.tr('password'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
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
                                      hintText: LocalizationService.tr(
                                        'enter_password',
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(26),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(26),
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
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  // Password strength hint (weak/strong) to guide the user.
                                  Builder(
                                    builder: (context) {
                                      final pwd = _passwordController.text;
                                      if (pwd.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      if (pwd.length < 8) {
                                        return Text(
                                          LocalizationService.tr(
                                            'password_strength_weak',
                                          ),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            fontSize: context.isMobile
                                                ? 11
                                                : 12,
                                          ),
                                        );
                                      }
                                      return Text(
                                        LocalizationService.tr(
                                          'password_strength_strong',
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: context.isMobile ? 11 : 12,
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: context.itemSpacing * 2),

                                  // Confirm Password Field
                                  Text(
                                    LocalizationService.tr('confirm_password'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
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
                                    controller: _confirmPasswordController,
                                    decoration: InputDecoration(
                                      hintText: LocalizationService.tr(
                                        'confirm_password',
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(26),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(26),
                                        ),
                                        onPressed: () {
                                          setState(
                                            () => _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                          );
                                        },
                                      ),
                                    ),
                                    obscureText: _obscureConfirmPassword,
                                    validator: (value) =>
                                        validateConfirmPassword(
                                          value,
                                          _passwordController.text,
                                        ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  // Password match indicator
                                  Builder(
                                    builder: (context) {
                                      final password = _passwordController.text;
                                      final confirmPassword = _confirmPasswordController.text;
                                      if (confirmPassword.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      if (password == confirmPassword) {
                                        return Text(
                                          '✓ Passwords match',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: context.isMobile ? 11 : 12,
                                          ),
                                        );
                                      } else {
                                        return Text(
                                          '✗ Passwords do not match',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                            fontSize: context.isMobile ? 11 : 12,
                                          ),
                                        );
                                      }
                                    },
                                  ),

                                  SizedBox(height: context.itemSpacing * 3),

                                  // Signup Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: context.buttonHeight,
                                    child: ElevatedButton(
                                      onPressed:
                                          (authProvider.isLoading ||
                                              _isSubmitting)
                                          ? null
                                          : _signup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        disabledBackgroundColor:
                                            Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha((0.12 * 255).round()),
                                        disabledForegroundColor:
                                            Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha((0.38 * 255).round()),
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
                                      child:
                                          (authProvider.isLoading ||
                                              _isSubmitting)
                                          ? SizedBox(
                                              height: 28,
                                              width: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              LocalizationService.tr(
                                                'signup_button',
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

                                  // Login Link
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(26),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.go('/login'),
                                          child: Text(
                                            'Sign In',
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withAlpha(26),
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withAlpha(26),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.sports_soccer,
                          size: 200,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(26),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isMediumScreen ? 48.0 : 24.0,
                    vertical: 24.0,
                  ),
                  child: Container(
                    width: isMediumScreen ? screenWidth * 0.6 : double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

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
                                  Icons.person_add,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Create Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'On the sign-up page, you must create an account once to join the football community.',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(26),
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // Signup Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name Field
                              Text(
                                LocalizationService.tr('full_name'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: LocalizationService.tr('full_name'),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(26),
                                  ),
                                ),
                                validator: (value) => validateName(value),
                              ),

                              const SizedBox(height: 24),

                              // Email Field
                              Text(
                                LocalizationService.tr('email'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: LocalizationService.tr(
                                    'enter_email',
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(26),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => validateEmail(value),
                              ),

                              const SizedBox(height: 24),

                              // Age Field
                              Text(
                                LocalizationService.tr('age'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _ageController,
                                decoration: InputDecoration(
                                  hintText: LocalizationService.tr('age'),
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(26),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) => validateAge(value),
                              ),

                              const SizedBox(height: 24),

                              // Phone Number Field
                              Text(
                                LocalizationService.tr('phone'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              PhoneInputField(
                                controller: _phoneController,
                                onChanged: (phoneNumber) {
                                  setState(() => _phoneNumber = phoneNumber);
                                },
                                hintText: LocalizationService.tr('phone'),
                                initialCountryCode: 'MA',
                              ),
                              const SizedBox(height: 8),
                              // Phone requirements hint
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withAlpha(51),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationService.tr(
                                        'phone_requirements',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• ${LocalizationService.tr('phone_req_digits')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(179),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Gender Field
                              Text(
                                'Gender',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedGender,
                                decoration: InputDecoration(
                                  hintText: 'Select your gender',
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(26),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text('Female'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedGender = value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your gender';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Password Field
                              Text(
                                LocalizationService.tr('password'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  hintText: LocalizationService.tr(
                                    'enter_password',
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(26),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(26),
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
                                validator: (value) => validatePassword(value),
                              ),
                              const SizedBox(height: 8),
                              // Password requirements hint
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withAlpha(51),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationService.tr(
                                        'password_requirements',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...[
                                      '• ${LocalizationService.tr('password_req_length')}',
                                      '• ${LocalizationService.tr('password_req_uppercase')}',
                                      '• ${LocalizationService.tr('password_req_lowercase')}',
                                      '• ${LocalizationService.tr('password_req_digit')}',
                                    ].map(
                                      (requirement) => Text(
                                        requirement,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(179),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Password requirements hint
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withAlpha(51),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationService.tr(
                                        'password_requirements',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...[
                                      '• ${LocalizationService.tr('password_req_length')}',
                                      '• ${LocalizationService.tr('password_req_uppercase')}',
                                      '• ${LocalizationService.tr('password_req_lowercase')}',
                                      '• ${LocalizationService.tr('password_req_digit')}',
                                    ].map(
                                      (requirement) => Text(
                                        requirement,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(179),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final pwd = _passwordController.text;
                                  if (pwd.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  if (pwd.length < 8) {
                                    return Text(
                                      LocalizationService.tr(
                                        'password_strength_weak',
                                      ),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return Text(
                                    LocalizationService.tr(
                                      'password_strength_strong',
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Confirm Password Field
                              Text(
                                LocalizationService.tr('confirm_password'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  hintText: LocalizationService.tr(
                                    'confirm_password',
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(26),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(26),
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      );
                                    },
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                validator: (value) => validateConfirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Password match indicator
                              Builder(
                                builder: (context) {
                                  final password = _passwordController.text;
                                  final confirmPassword = _confirmPasswordController.text;
                                  if (confirmPassword.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  if (password == confirmPassword) {
                                    return Text(
                                      '✓ Passwords match',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      '✗ Passwords do not match',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                },
                              ),

                              const SizedBox(height: 32),

                              // Signup Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed:
                                      (authProvider.isLoading || _isSubmitting)
                                      ? null
                                      : _signup,
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
                                      (authProvider.isLoading || _isSubmitting)
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
                                          LocalizationService.tr(
                                            'signup_button',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login Link
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(26),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/login'),
                                      child: Text(
                                        'Sign In',
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
    );
  }
}
