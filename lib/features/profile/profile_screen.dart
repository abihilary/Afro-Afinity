import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../../core/services/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        context.go('/login');
        return;
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () {
              // Edit profile implementation
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _profileData == null
              ? const Center(
                  child: Text('Profile not found', style: TextStyle(color: Colors.white)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('About Me'),
                      _buildInfoTile('Display Name', _profileData?['display_name']),
                      _buildInfoTile('Pronouns', _profileData?['pronouns']),
                      _buildInfoTile('Looking For', _profileData?['looking_for']),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Bio'),
                      _buildBioTile(_profileData?['bio']),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Interests'),
                      _buildInterestsTile(_profileData?['interests']),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleLogout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 3),
                  image: const DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/150'), // Placeholder
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _profileData?['display_name'] ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not specified',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioTile(dynamic bio) {
    return Text(
      bio?.toString() ?? 'No bio provided.',
      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
    );
  }

  Widget _buildInterestsTile(dynamic interests) {
    if (interests == null || interests is! List || interests.isEmpty) {
      return const Text('No interests listed.', style: TextStyle(color: Colors.white70, fontSize: 14));
    }
    final list = interests;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: list.map((interest) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          interest.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      )).toList(),
    );
  }
}
