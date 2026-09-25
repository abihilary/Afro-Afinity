import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _loading = false;
  bool _socialLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CREATE ACCOUNT
  // ===========================================================================

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      _showError(
        'Please confirm that you are 18+ and accept the Terms & Privacy Policy.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    context.go('/verification');
  }

  // ===========================================================================
  // GOOGLE
  // ===========================================================================

  Future<void> _continueWithGoogle() async {
    FocusScope.of(context).unfocus();

    if (!_acceptedTerms) {
      _showError(
        'Please confirm that you are 18+ and accept the Terms & Privacy Policy.',
      );
      return;
    }

    setState(() {
      _socialLoading = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    setState(() {
      _socialLoading = false;
    });

    context.go('/verification');
  }

  // ===========================================================================
  // APPLE
  // ===========================================================================

  Future<void> _continueWithApple() async {
    FocusScope.of(context).unfocus();

    if (!_acceptedTerms) {
      _showError(
        'Please confirm that you are 18+ and accept the Terms & Privacy Policy.',
      );
      return;
    }

    setState(() {
      _socialLoading = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    setState(() {
      _socialLoading = false;
    });

    context.go('/verification');
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF8F3D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email address';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please create a password';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  // ===========================================================================
  // INPUT DECORATION
  // ===========================================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF6F6A70),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF8C858A),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1A191D),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFD9A441),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFB85445),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFB85445),
          width: 1.2,
        ),
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFD87568),
        fontSize: 11,
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF121216);
    const gold = Color(0xFFD9A441);
    const terracotta = Color(0xFF9B473B);
    const mutedText = Color(0xFFA7A3A0);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // ===================================================================
          // TOP GRADIENT
          // ===================================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 270,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      terracotta.withValues(alpha: 0.72),
                      const Color(0xFF5C302B).withValues(alpha: 0.40),
                      background.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===================================================================
          // MAIN CONTENT
          // ===================================================================

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    18,
                    24,
                    36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =======================================================
                      // BACK BUTTON
                      // =======================================================



                      // =======================================================
                      // BRAND
                      // =======================================================

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE1B65A),
                                    Color(0xFFB87532),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withValues(alpha: 0.20),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'AA',
                                  style: TextStyle(
                                    color: Color(0xFF171519),
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Affinity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Rooted in Culture, Connected by Heart',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFD0A956),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 42),

                      // =======================================================
                      // TITLE
                      // =======================================================

                      const Text(
                        'Create your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),

                      const SizedBox(height: 9),

                      const Text(
                        'Start your journey with Affinity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // =======================================================
                      // GOOGLE
                      // =======================================================

                      _SocialButton(
                        icon: const _GoogleIcon(),
                        label: 'Continue with Google',
                        onPressed: _socialLoading
                            ? null
                            : _continueWithGoogle,
                      ),

                      const SizedBox(height: 12),

                      // =======================================================
                      // APPLE
                      // =======================================================

                      _SocialButton(
                        icon: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 23,
                        ),
                        label: 'Continue with Apple',
                        onPressed: _socialLoading
                            ? null
                            : _continueWithApple,
                      ),

                      const SizedBox(height: 27),

                      // =======================================================
                      // OR
                      // =======================================================

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Color(0xFF777277),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 27),

                      // =======================================================
                      // FORM
                      // =======================================================

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _FieldLabel(
                              text: 'Email address',
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              validator: _validateEmail,
                              decoration: _inputDecoration(
                                hintText: 'Enter your email',
                                prefixIcon: Icons.email_outlined,
                              ),
                            ),

                            const SizedBox(height: 20),

                            const _FieldLabel(
                              text: 'Password',
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              validator: _validatePassword,
                              onFieldSubmitted: (_) {
                                if (!_loading) {
                                  _createAccount();
                                }
                              },
                              decoration: _inputDecoration(
                                hintText: 'Create a password',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                      !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF918B90),
                                    size: 21,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 9),

                            const Text(
                              'Use at least 8 characters.',
                              style: TextStyle(
                                color: Color(0xFF777277),
                                fontSize: 11.5,
                              ),
                            ),

                            const SizedBox(height: 23),

                            // =================================================
                            // TERMS
                            // =================================================

                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptedTerms =
                                            value ?? false;
                                      });
                                    },
                                    activeColor: gold,
                                    checkColor: const Color(0xFF18161A),
                                    side: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.30),
                                      width: 1.3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 3,
                                    ),
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          color: Color(0xFF999398),
                                          fontSize: 11.5,
                                          height: 1.55,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                            'I confirm that I am 18 or older and agree to the ',
                                          ),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: gold,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' and ',
                                          ),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: gold,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // =================================================
                            // CREATE ACCOUNT
                            // =================================================

                            SizedBox(
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFFE1B65A),
                                      Color(0xFFC98A3D),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withValues(alpha: 0.16),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                  _loading ? null : _createAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor:
                                    Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor:
                                    const Color(0xFF19161A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                        Color(0xFF19161A),
                                      ),
                                    ),
                                  )
                                      : const Text(
                                    'Create account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 27),

                      // =======================================================
                      // LOGIN LINK
                      // =======================================================

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Color(0xFF858086),
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go('/login');
                            },
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                color: gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // =======================================================
                      // SECURITY
                      // =======================================================

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.30),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Your information is securely protected',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.30),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===================================================================
          // SOCIAL LOADING
          // ===================================================================

          if (_socialLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.28),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD9A441),
                      ),
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

// =============================================================================
// FIELD LABEL
// =============================================================================

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFE3DFE1),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// =============================================================================
// SOCIAL BUTTON
// =============================================================================

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 53,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1A191D),
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Center(
                child: icon,
              ),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// GOOGLE ICON
// =============================================================================

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
      ),
    );
  }
}