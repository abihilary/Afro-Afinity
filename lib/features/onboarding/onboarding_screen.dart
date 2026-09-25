import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../models/user_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _pronouns;
  String? _lookingFor;

  final Set<String> _interests = {};

  late AnimationController _animationController;

  final List<String> _interestOptions = [
    'Afrobeats',
    'Amapiano',
    'Jollof',
    'Ankara',
    'Safari',
    'Pidgin',
    'Highlife',
    'Braids',
    'Palm Wine',
    'Waakye',
    'Fufu',
    'Azonto',
    'Kente',
    'Dashiki',
    'Djembe',
    'Suuya',
    'Banku',
    'Gele',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  void _next() async {
    if (!_validateStep()) return;

    if (_step < 3) {
      setState(() {
        _step++;
      });

      _animationController
        ..reset()
        ..forward();
    } else {
      setState(() => _isLoading = true);
      try {
        final profile = UserProfile(
          displayName: _nameController.text.trim(),
          pronouns: _pronouns ?? '',
          lookingFor: _lookingFor ?? '',
          interests: _interests.toList(),
          bio: _bioController.text.trim(),
        );

        final success = await ref
            .read(authServiceProvider.notifier)
            .updateUserProfile(profile);

        if (!mounted) return;

        if (success) {
          context.go('/home');
        } else {
          _showMessage('Failed to save profile. Please try again.');
        }
      } catch (e) {
        _showMessage('An error occurred: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }

    setState(() {
      _step--;
    });

    _animationController
      ..reset()
      ..forward();
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showMessage('Please enter your name.');
        return false;
      }

      if (_pronouns == null) {
        _showMessage('Please select your pronouns.');
        return false;
      }
    }

    if (_step == 1 && _lookingFor == null) {
      _showMessage('Please choose who you want to meet.');
      return false;
    }

    if (_step == 2 && _interests.length < 3) {
      _showMessage('Choose at least 3 interests.');
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF242124),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF121216);
    const gold = Color(0xFFDAA520);
    const terracotta = Color(0xFFC17C3C);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(gold),
                Expanded(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: _buildStep(
                        gold: gold,
                        terracotta: terracotta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFDAA520)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color gold) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _back,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'AFFINITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_step + 1}/4',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(
              4,
              (index) {
                final active = index <= _step;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    margin: EdgeInsets.only(
                      right: index == 3 ? 0 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? gold
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required Color gold,
    required Color terracotta,
  }) {
    switch (_step) {
      case 0:
        return _buildIdentity(gold, terracotta);
      case 1:
        return _buildLookingFor(gold);
      case 2:
        return _buildInterests(gold);
      default:
        return _buildProfile(gold, terracotta);
    }
  }

  Widget _buildIdentity(Color gold, Color terracotta) {
    return _page(
      title: 'Tell us about you',
      subtitle: 'This helps people know who they are meeting.',
      buttonText: 'Continue',
      onPressed: _next,
      children: [
        _label('Display name'),
        _field(
          controller: _nameController,
          hint: 'Your name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 22),
        _label('Birthday'),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _fieldDecoration(),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF8F8A91),
                size: 19,
              ),
              const SizedBox(width: 12),
              const Text(
                'Your birthday',
                style: TextStyle(
                  color: Color(0xFF858087),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: gold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _label('Pronouns'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'He/Him',
            'She/Her',
            'They/Them',
            'Non-binary',
            'Prefer not to say',
          ].map((value) {
            return _choiceChip(
              value,
              _pronouns == value,
              gold,
              () {
                setState(() => _pronouns = value);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLookingFor(Color gold) {
    return _page(
      title: 'Who are you looking to meet?',
      subtitle: 'You can change this anytime.',
      buttonText: 'Continue',
      onPressed: _next,
      children: [
        const SizedBox(height: 8),
        ...[
          ('Male', 'Show me men', '♂'),
          ('Female', 'Show me women', '♀'),
          ('Both', 'Show me everyone', '⚧'),
        ].map(
          (item) => _lookingCard(
            title: item.$1,
            subtitle: item.$2,
            symbol: item.$3,
            selected: _lookingFor == item.$1,
            gold: gold,
            onTap: () {
              setState(() => _lookingFor = item.$1);
            },
          ),
        ),
        const SizedBox(height: 28),
        _label('Age range 18–65'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _rangeBox('Min', '18')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 18,
                child: Divider(color: Colors.white24),
              ),
            ),
            Expanded(child: _rangeBox('Max', '65')),
          ],
        ),
      ],
    );
  }

  Widget _buildInterests(Color gold) {
    return _page(
      title: 'What are you into?',
      subtitle: 'Pick at least 3 interests that feel like you.',
      buttonText: 'Continue',
      onPressed: _next,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 9,
          runSpacing: 10,
          children: _interestOptions.map((interest) {
            final selected = _interests.contains(interest);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _interests.remove(interest);
                  } else {
                    _interests.add(interest);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.11),
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: selected
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          '${_interests.length} selected',
          style: TextStyle(
            color: gold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildProfile(Color gold, Color terracotta) {
    return _page(
      title: 'Make your profile yours',
      subtitle: 'Add a little personality before you start meeting people.',
      buttonText: 'Finish profile',
      onPressed: _next,
      children: [
        const SizedBox(height: 8),
        _label('Photos'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showMessage(
                'Photo picker will be connected here.',
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: index == 0
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              terracotta.withValues(alpha: 0.32),
                              gold.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: Colors.white,
                          size: 27,
                        ),
                      )
                    : const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF777279),
                        size: 25,
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _label('Bio'),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 160,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Tell people something about you...',
            hintStyle: const TextStyle(
              color: Color(0xFF68636A),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.045),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: gold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _page({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8F8A91),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                ...children,
                const SizedBox(height: 30),
                _gradientButton(
                  text: buttonText,
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF777279),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: _fieldDecoration(),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF68636A),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF858087),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 14,
          ),
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _choiceChip(
    String text,
    bool selected,
    Color gold,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? gold : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? gold
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _lookingCard({
    required String title,
    required String subtitle,
    required String symbol,
    required bool selected,
    required Color gold,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: selected ? Colors.black : gold,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected
                          ? Colors.black54
                          : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.black : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? Colors.black
                      : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeBox(String label, String value) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF777279),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC17C3C),
            Color(0xFFDAA520),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDAA520).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
