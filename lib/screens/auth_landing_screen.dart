import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';

// Custom button widget with hover animation
class AnimatedAuthButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isWhiteButton;

  const AnimatedAuthButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isWhiteButton = false,
  });

  @override
  State<AnimatedAuthButton> createState() => _AnimatedAuthButtonState();
}

class _AnimatedAuthButtonState extends State<AnimatedAuthButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered && !widget.isLoading
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isWhiteButton
                ? Colors.white
                : const Color(0xFF9FD49F), // White or green button color
            foregroundColor: widget.isWhiteButton
                ? const Color(0xFF0E1F16) // Dark green text on white button
                : const Color(0xFF0E1F16), // Dark green text
            disabledBackgroundColor: widget.isWhiteButton
                ? Colors.white.withOpacity(0.6)
                : const Color(0xFF9FD49F).withOpacity(0.6),
            disabledForegroundColor: const Color(0xFF0E1F16).withOpacity(0.6),
            elevation: _isHovered && !widget.isLoading ? 8 : 4,
            shadowColor: widget.isWhiteButton
                ? Colors.black.withOpacity(0.1)
                : const Color(0xFF9FD49F).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Fun Join the Game button with multiple animations
class JoinGameButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isEligible;

  const JoinGameButton({
    super.key,
    this.onPressed,
    this.isEligible = true,
  });

  @override
  State<JoinGameButton> createState() => _JoinGameButtonState();
}

class _JoinGameButtonState extends State<JoinGameButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _spinController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _spinAnimation;
  late Animation<double> _progressAnimation;

  bool _isAnimating = false;
  bool _showConfetti = false;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();

    // Pulse/Glow animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bounce/Scale animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Spin animation for icon morph
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _spinAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159 * 2).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeInOut),
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _spinController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure controllers are properly initialized when dependencies change
    if (!_pulseController.isAnimating && !_bounceController.isAnimating) {
      // Controllers are ready to be used
    }
  }

  void _handlePress() async {
    if (_isAnimating || !widget.isEligible) return;

    setState(() => _isAnimating = true);

    // Start all animations simultaneously
    _bounceController.forward();
    _pulseController.forward();
    _spinController.forward();

    // Show progress after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showProgress = true);
      _progressController.forward();
    });

    // Complete animations and show confetti
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _showConfetti = true;
        _showProgress = false;
      });
    }

    // Reset animations
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showConfetti = false;
        _isAnimating = false;
      });

      _bounceController.reverse();
      _pulseController.reverse();
      _spinController.reset();
      _progressController.reset();
    }

    // Call the action
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isEligible
          ? 'Click to join the game!'
          : 'You must be logged in to join a team',
      child: MouseRegion(
        cursor: widget.isEligible ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: _handlePress,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti particles
              if (_showConfetti) ..._buildConfetti(),

              // Main button with animations
              AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseAnimation,
                  _bounceAnimation,
                  _spinAnimation,
                  _progressAnimation,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: widget.isEligible
                            ? (_isAnimating
                                ? const Color(0xFF9FD49F).withOpacity(0.9)
                                : const Color(0xFF9FD49F))
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isEligible
                                ? const Color(0xFF9FD49F).withOpacity(_pulseAnimation.value * 0.4)
                                : Colors.grey.shade400.withOpacity(0.3),
                            blurRadius: _pulseAnimation.value * 15,
                            spreadRadius: _pulseAnimation.value * 3,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress bar overlay
                          if (_showProgress)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: LinearProgressIndicator(
                                  value: _progressAnimation.value,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0E1F16),
                                  ),
                                ),
                              ),
                            ),

                          // Button content
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated icon
                              AnimatedBuilder(
                                animation: _spinAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _isAnimating ? _spinAnimation.value : 0,
                                    child: Icon(
                                      _isAnimating ? Icons.sports_soccer : Icons.play_arrow,
                                      color: widget.isEligible
                                          ? const Color(0xFF0E1F16)
                                          : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),

                              // Animated text
                              AnimatedOpacity(
                                opacity: _isAnimating ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _isAnimating ? 'Joining...' : 'Join the Game',
                                  style: TextStyle(
                                    color: widget.isEligible
                                        ? const Color(0xFF0E1F16)
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildConfetti() {
    return List.generate(12, (index) {
      final angle = (index * 30) * (3.14159 / 180); // 30 degrees apart
      final distance = 60.0;
      final dx = distance * cos(angle);
      final dy = distance * sin(angle);

      return Positioned(
        left: dx + 50,
        top: dy + 20,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: [
              Colors.yellow,
              Colors.blue,
              Colors.red,
              Colors.green,
              Colors.purple,
              Colors.orange,
            ][index % 6],
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }
}

enum AuthMode { login, signup }

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate('language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: const Text('🇺🇸'),
                onTap: () {
                  LocalizationService().loadLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Français'),
                leading: const Text('🇫🇷'),
                onTap: () {
                  LocalizationService().loadLanguage('fr');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('العربية'),
                leading: const Text('🇲🇦'),
                onTap: () {
                  LocalizationService().loadLanguage('ar');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F16), // Dark green background
        elevation: 0,
        title: const Text(
          'FootConnect',
          style: TextStyle(
            color: Color(0xFF9FD49F), // Light green title
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Color(0xFF9FD49F)), // Light green language button
            onPressed: () => _showLanguageDialog(context),
            tooltip: 'Language',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWideScreen ? _buildWideScreenLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWideScreenLayout() {
    return Container(
      color: const Color(0xFF0E1F16), // Dark green background for entire screen
      child: Row(
        children: [
          // Left side - Auth Form
          Expanded(
            flex: 1,
            child: const Center(child: AuthForm()),
          ),
          // Right side - Welcome Content
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 120,
                      color: const Color(0xFF9FD49F), // Green accent color
                    ),
                    const SizedBox(height: 32),
                    Text(
                      LocalizationService().translate('welcome_to_footconnect'),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationService().translate('football_community'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    JoinGameButton(
                      onPressed: () {
                        // Navigate to team selection or home
                        context.go('/home');
                      },
                      isEligible: context.watch<AuthProvider>().isAuthenticated,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      color: const Color(0xFF0E1F16), // Dark green background for entire screen
      child: const Center(child: AuthForm()), // Only show the form on mobile
    );
  }


}

// Unified Auth Form Widget
class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  AuthMode _authMode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGender;
  bool _obscurePassword = true;
  // final bool _obscureConfirmPassword = true; // Removed unused field
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login;
      // Clear form when switching modes
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _ageController.clear();
      _phoneController.clear();
      _selectedGender = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_authMode == AuthMode.login) {
        await authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        context.go('/home');
      } else {
        if (authProvider.isAuthenticated) {
          await authProvider.logoutWithConfirmation(context);
        }

        final isConfirmed = await authProvider.signup(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          age: int.parse(_ageController.text.trim()),
          phone: _phoneController.text.trim(),
          gender: _selectedGender,
          role: 'player',
        );

        if (!mounted) return;

        if (isConfirmed) {
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService().translate('account_created_welcome'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService().translate('account_created_check_email'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;

      String errorMessage;
      if (_authMode == AuthMode.login) {
        errorMessage = LocalizationService().translate('login_failed');
        if (error.toString().contains('Invalid login credentials')) {
          errorMessage = LocalizationService().translate('invalid_credentials');
        } else if (error.toString().contains('Email not confirmed')) {
          errorMessage = LocalizationService().translate('email_not_confirmed');
        }
      } else {
        errorMessage = LocalizationService().translate('signup_failed');
      }

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
    final isLogin = _authMode == AuthMode.login;

    return Container(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600), // Compact and short
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Compact height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Tab Bar for Login/Signup
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _authMode = AuthMode.login),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300), // Smooth transition
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _authMode == AuthMode.login
                              ? const Color(0xFF9FD49F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          LocalizationService().translate('login'),
                          style: TextStyle(
                            color: _authMode == AuthMode.login
                                ? const Color(0xFF0E1F16)
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _authMode = AuthMode.signup),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300), // Smooth transition
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _authMode == AuthMode.signup
                              ? const Color(0xFF9FD49F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          LocalizationService().translate('signup'),
                          style: TextStyle(
                            color: _authMode == AuthMode.signup
                                ? const Color(0xFF0E1F16)
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Login Fields
            if (isLogin) ...[
              // Email Field
              Text(
                LocalizationService().translate('email'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('enter_email'),
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('email_required');
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return LocalizationService().translate('invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              Text(
                LocalizationService().translate('password'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('enter_password'),
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade600,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('password_required');
                  }
                  if (value.length < 6) {
                    return LocalizationService().translate('password_too_short');
                  }
                  return null;
                },
              ),

              // Forgot Password
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: Text(
                    LocalizationService().translate('forgot_password'),
                    style: const TextStyle(
                      color: Color(0xFF9FD49F), // Green accent color
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ]

            // Signup Fields
            else ...[
              // Name Field
              Text(
                LocalizationService().translate('full_name'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('full_name'),
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('full_name_required');
                  }
                  if (value.length < 2) {
                    return LocalizationService().translate('name_too_short_2');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Email Field
              Text(
                LocalizationService().translate('email'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('enter_email'),
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('email_required');
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return LocalizationService().translate('invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone Field
              Text(
                LocalizationService().translate('phone'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: '+212 XX XX XX XX',
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.phone,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('phone_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Age Field
              Text(
                LocalizationService().translate('age'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('age'),
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('age_required');
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 100) {
                    return LocalizationService().translate('age_invalid_range');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Gender Field
              Text(
                LocalizationService().translate('gender'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('select_gender'),
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(LocalizationService().translate('male')),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(LocalizationService().translate('female')),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('gender_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Password Field
              Text(
                LocalizationService().translate('password'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0E1F16), // Dark green text
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('enter_password'),
                  hintStyle: TextStyle(color: Colors.grey.shade500), // Gray placeholder
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Wider padding
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade600,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9FD49F), width: 2),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('password_required');
                  }
                  if (value.length < 6) {
                    return LocalizationService().translate('password_too_short');
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: AnimatedAuthButton(
                onPressed: (authProvider.isLoading || _isSubmitting) ? null : _submitForm,
                isLoading: authProvider.isLoading || _isSubmitting,
                isWhiteButton: true, // White background, dark green text
                child: (authProvider.isLoading || _isSubmitting)
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0E1F16), // Dark green spinner
                          ),
                        ),
                      )
                    : Text(
                        isLogin
                            ? LocalizationService().translate('login_button')
                            : LocalizationService().translate('signup_button'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Toggle Mode Button
            Center(
              child: TextButton(
                onPressed: _toggleAuthMode,
                child: Text(
                  isLogin
                      ? LocalizationService().translate('dont_have_account')
                      : LocalizationService().translate('already_have_account'),
                  style: const TextStyle(
                    color: Color(0xFF9FD49F), // Green accent color
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
