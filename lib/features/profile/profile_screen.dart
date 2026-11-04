import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/api/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Controllers for editable fields
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _bioController;

  bool _isSaving = false;
  bool _incognitoMode = false;
  String _selectedTheme = 'Dark';
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfileImmediately();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImmediately() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    // Set initial placeholder/cached values immediately so UI components exist before data loads
    setState(() {
      _nameController.text = user.userMetadata?['first_name'] ?? user.email?.split('@').first ?? 'jking';
      _ageController.text = '27';
      _bioController.text = '1';
    });

    // Fetch fresh data from API /me immediately after signing in
    try {
      final apiClient = ApiClient();
      final data = await apiClient.get('/me');
      final profile = data is Map ? (data['profile'] ?? data) : null;

      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['first_name'] ?? profile['display_name'] ?? _nameController.text;
          _bioController.text = profile['bio'] ?? _bioController.text;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile via API: $e');
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _nameController.text = data['first_name'] ?? data['display_name'] ?? _nameController.text;
            _bioController.text = data['bio'] ?? _bioController.text;
          });
        }
      } catch (fallbackError) {
        debugPrint('Fallback error: $fallbackError');
      }
    }
  }

  Future<void> _saveDetails() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = ApiClient();
      await apiClient.patch('/me', data: {
        'first_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details saved successfully! 🎉'), backgroundColor: AppColors.gold),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authServiceProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'mrsinsj48@gmail.com';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Profile & Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================================
            // 1. BANNER & PROFILE HEADER CARD
            // ==========================================================
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: LinearGradient(
                            colors: [AppColors.gold.withValues(alpha: 0.3), const Color(0xFF242124)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.photo_camera_outlined, color: Colors.white.withValues(alpha: 0.4), size: 36),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.camera_alt, size: 14),
                          label: const Text('Change banner', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -40),
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.gold, width: 3),
                                  color: Colors.grey.shade900,
                                  image: const DecorationImage(
                                    image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _saveDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit profile'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Albums'),
                            ),
                          ],
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_nameController.text}, ${_ageController.text}',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified, color: AppColors.gold, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('📍 Cameroon 🇨🇲', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${_nameController.text.toLowerCase().replaceAll(' ', '_')} • Member since September 2026',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
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

            const SizedBox(height: 20),

            // ==========================================================
            // 2. CREATOR EARNINGS CARD
            // ==========================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CREATOR EARNINGS', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text('25', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                              SizedBox(width: 6),
                              Text('coins', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.monetization_on, color: AppColors.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('125 FCFA • 80% split • paid by MoMo • 5 FCFA/coin', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('History'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================================
            // 3. BOOST DISCOVER CARD
            // ==========================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF382A10), Color(0xFF1E180A)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: AppColors.gold, size: 36),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get to the top of Discover', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('50 coins puts you first in everyone’s results for 1h.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Boost • 50', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================================
            // 4. PROFILE DETAILS • EDITABLE
            // ==========================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PROFILE DETAILS • EDITABLE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DISPLAY NAME', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black54,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AGE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _ageController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black54,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('BIO', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('INTERESTS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['🎵 Afrobeats', '🎹 Amapiano', '🙌 Gospel', '🎤 Hip-hop', '🎷 Jazz', '🍲 Ndolé', '⚽ Football', '🏀 Basketball'].map((interest) => Chip(
                      label: Text(interest, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Text('Profile 50% complete', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Spacer(),
                      Text('Add: more photos, voice note', style: TextStyle(color: AppColors.gold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(value: 0.5, color: AppColors.gold, backgroundColor: Colors.white10, minHeight: 6),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Save details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================================
            // 5. SETTINGS & PREFERENCES (Web Version Match)
            // ==========================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SETTINGS & PREFERENCES', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  const Text('ACCOUNT EMAIL', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(userEmail, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  const Text('APPEARANCE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Light', 'Dark', 'System'].map((theme) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(theme)),
                          selected: _selectedTheme == theme,
                          onSelected: (selected) => setState(() => _selectedTheme = theme),
                          selectedColor: AppColors.gold,
                          backgroundColor: Colors.black54,
                          labelStyle: TextStyle(color: _selectedTheme == theme ? Colors.black : Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('LANGUAGE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['English', 'Français'].map((lang) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(lang)),
                          selected: _selectedLanguage == lang,
                          onSelected: (selected) => setState(() => _selectedLanguage = lang),
                          selectedColor: AppColors.gold,
                          backgroundColor: Colors.black54,
                          labelStyle: TextStyle(color: _selectedLanguage == lang ? Colors.black : Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Incognito mode', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('Browse without appearing in Discover. Only people you like can see you. Diva Plus.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _incognitoMode,
                        onChanged: (val) => setState(() => _incognitoMode = val),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 32),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Privacy controls', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Who can see your profile, photos and activity', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {},
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Blocked members', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: const Text('You haven’t blocked anyone.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white12, height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
