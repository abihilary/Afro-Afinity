import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_controller.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/pulsing_indicator.dart';
import '../../core/widgets/safe_image.dart';
import '../../models/user.dart';
import '../wallet/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppUser _user = AppUser.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _user.addListener(_refresh);
  }

  @override
  void dispose() {
    _user.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickPhoto({int? replaceIndex}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1B1C22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  replaceIndex != null ? 'Replace photo' : 'Profile photo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.gold,
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.gold,
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (image == null) return;

    if (replaceIndex != null && replaceIndex < _user.photos.length) {
      _user.photos[replaceIndex] = image.path;
      _user.updateProfile();
    } else {
      _user.addPhoto(image.path);
    }
  }

  Future<void> _pickBannerPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (image == null) return;
    _user.setBannerPhoto(image.path);
  }

  Future<void> _removePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF202129),
          title: const Text(
            'Remove photo?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This photo will be removed from your profile.',
            style: TextStyle(color: Colors.white60),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _user.removePhotoAt(index);
    }
  }

  void _showEditBannerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit banner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '180px premium banner • gradient, photo, or mesh pattern',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                // Option 1: Change Banner Photo
                _buildBannerOptionTile(
                  icon: Icons.image_outlined,
                  title: 'Change Banner Photo',
                  subtitle: 'Upload cover like Instagram • 180px height',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickBannerPhoto();
                  },
                ),
                const SizedBox(height: 10),
                // Option 2: Choose Gradient
                _buildBannerOptionTile(
                  icon: Icons.palette_outlined,
                  title: 'Choose Gradient • 6 styles',
                  subtitle: 'Pink violet, Sunset, Ocean, Midnight, Golden, Forest',
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.pink, AppColors.purple],
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showGradientStylePicker();
                  },
                ),
                const SizedBox(height: 10),
                // Option 3: Pattern Mesh
                _buildBannerOptionTile(
                  icon: Icons.grid_on_rounded,
                  title: 'Pattern Mesh',
                  subtitle: 'Subtle dot mesh over gradient',
                  trailing: Switch.adaptive(
                    value: _user.hasPatternMesh,
                    activeTrackColor: AppColors.gold,
                    onChanged: (val) {
                      _user.togglePatternMesh(val);
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    _user.togglePatternMesh(!_user.hasPatternMesh);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                // Option 4: Remove banner
                InkWell(
                  onTap: () {
                    _user.removeBanner();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.pink.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.pink,
                          size: 20,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remove banner',
                                style: TextStyle(
                                  color: AppColors.pink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Back to default gradient',
                                style: TextStyle(
                                  color: AppColors.pink,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildBannerOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showGradientStylePicker() {
    final styles = [
      'Pink Violet',
      'Sunset',
      'Ocean',
      'Midnight',
      'Golden',
      'Forest',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose Gradient',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: styles.map((style) {
                    final selected = _user.bannerGradientStyle == style;
                    return GestureDetector(
                      onTap: () {
                        _user.setBannerGradient(style);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 64) / 2,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.gold
                                : Colors.white.withValues(alpha: 0.08),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _getGradientForStyle(style),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              style,
                              style: TextStyle(
                                color: selected ? AppColors.gold : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getGradientForStyle(String style) {
    switch (style) {
      case 'Sunset':
        return const LinearGradient(
          colors: [Color(0xFF3B1D1D), Color(0xFF1A0F1A)],
        );
      case 'Ocean':
        return const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43)],
        );
      case 'Midnight':
        return const LinearGradient(
          colors: [Color(0xFF0D0D11), Color(0xFF1A1A24)],
        );
      case 'Golden':
        return const LinearGradient(
          colors: [Color(0xFF2B220A), Color(0xFF141005)],
        );
      case 'Forest':
        return const LinearGradient(
          colors: [Color(0xFF0A2216), Color(0xFF05120B)],
        );
      case 'Pink Violet':
      default:
        return const LinearGradient(
          colors: [Color(0xFF1E1022), Color(0xFF0F0A18)],
        );
    }
  }



  void _editProfile() {
    final nameController = TextEditingController(text: _user.name);
    final ageController = TextEditingController(text: _user.age.toString());
    final handleController = TextEditingController(text: _user.handle);
    final locationController = TextEditingController(text: _user.location);
    final heightController = TextEditingController(text: _user.height);
    final jobController = TextEditingController(text: _user.job);
    final educationController = TextEditingController(text: _user.education);
    final pronounsController = TextEditingController(text: _user.pronouns);
    final bioController = TextEditingController(text: _user.bio);
    final promptQController = TextEditingController(text: _user.promptQuestion);
    final promptAController = TextEditingController(text: _user.promptAnswer);
    final selectedInterests = _user.interests.toSet();

    const availableInterests = [
      'Architecture',
      'Climbing',
      'Natural wine',
      'Film photo',
      'Design',
      'Cycling',
      'Museums',
      'Jazz',
      'Afrobeats',
      'Travel',
      'Food',
      'Fashion',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            20,
            22,
            MediaQuery.of(context).viewInsets.bottom + 25,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Edit profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _input(controller: nameController, label: 'Name'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        controller: ageController,
                        label: 'Age',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _input(
                        controller: handleController,
                        label: 'Handle',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        controller: locationController,
                        label: 'Location',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _input(
                        controller: heightController,
                        label: 'Height',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        controller: jobController,
                        label: 'Job',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _input(
                        controller: pronounsController,
                        label: 'Pronouns',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _input(
                  controller: educationController,
                  label: 'Education',
                ),
                const SizedBox(height: 12),
                _input(
                  controller: bioController,
                  label: 'Bio / About me',
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PROMPT',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _input(
                  controller: promptQController,
                  label: 'Prompt Question',
                ),
                const SizedBox(height: 10),
                _input(
                  controller: promptAController,
                  label: 'Prompt Answer',
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'INTERESTS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder: (context, setSheetState) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableInterests.map((interest) {
                        final selected = selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: selected,
                          onSelected: (value) {
                            setSheetState(() {
                              if (value) {
                                selectedInterests.add(interest);
                              } else {
                                selectedInterests.remove(interest);
                              }
                            });
                          },
                          selectedColor: AppColors.gold,
                          backgroundColor: const Color(0xFF24252D),
                          labelStyle: TextStyle(
                            color: selected ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          checkmarkColor: Colors.black,
                          side: BorderSide(
                            color: selected
                                ? AppColors.gold
                                : Colors.white.withValues(alpha: .08),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      final age = int.tryParse(ageController.text.trim());
                      _user.updateProfile(
                        name: nameController.text.trim(),
                        age: age != null && age >= 18 && age <= 120
                            ? age
                            : _user.age,
                        handle: handleController.text.trim(),
                        location: locationController.text.trim(),
                        height: heightController.text.trim(),
                        job: jobController.text.trim(),
                        education: educationController.text.trim(),
                        pronouns: pronounsController.text.trim(),
                        bio: bioController.text.trim(),
                        promptQuestion: promptQController.text.trim(),
                        promptAnswer: promptAController.text.trim(),
                      );
                      _user.replaceInterests(selectedInterests);

                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'Save changes',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      ageController.dispose();
      handleController.dispose();
      locationController.dispose();
      heightController.dispose();
      jobController.dispose();
      educationController.dispose();
      pronounsController.dispose();
      bioController.dispose();
      promptQController.dispose();
      promptAController.dispose();
    });
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF24252D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showSettings() {
    _openSettingsSheet();
  }

  void _openPrivacy() {
    _openPreferencesSheet(
      title: 'Privacy',
      children: [
        _PreferenceTile(
          icon: Icons.visibility_outlined,
          title: 'Show distance',
          subtitle: 'Let people see how far away you are',
          value: () => _user.showDistance,
          onChanged: (value) => _user.updatePreferences(showDistance: value),
        ),
        _PreferenceTile(
          icon: Icons.visibility_off_outlined,
          title: 'Incognito mode',
          subtitle: 'Only appear to people you like',
          value: () => _user.incognitoMode,
          onChanged: (value) => _user.updatePreferences(incognitoMode: value),
        ),
      ],
    );
  }

  void _openNotifications() {
    _openPreferencesSheet(
      title: 'Notifications',
      children: [
        _PreferenceTile(
          icon: Icons.notifications_active_outlined,
          title: 'Push notifications',
          subtitle: 'Messages, likes, and matches',
          value: () => _user.notificationsEnabled,
          onChanged: (value) =>
              _user.updatePreferences(notificationsEnabled: value),
        ),
      ],
    );
  }

  void _openPaymentMethods() {
    _showPremium();
  }

  void _openHelpSupport() {
    _showMessage('Help & Support is available 24/7.');
  }

  void _openPreferencesSheet({
    required String title,
    required List<_PreferenceTile> children,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...children.map(
                      (tile) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(tile.icon, color: AppColors.gold),
                        title: Text(
                          tile.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          tile.subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        value: tile.value(),
                        activeThumbColor: AppColors.gold,
                        onChanged: (value) {
                          tile.onChanged(value);
                          setSheetState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.gold,
                ),
                title: const Text('Notifications',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Push, email',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _openNotifications();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.gold,
                ),
                title: const Text('Privacy',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Blocked, visibility',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _openPrivacy();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.gold,
                ),
                title: const Text('Payment Methods',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Apple Pay, cards',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _openPaymentMethods();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.gold,
                ),
                title: const Text('Help & Support',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('FAQ, contact',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _openHelpSupport();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  context.go("/login");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremium() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ProfileSheet(
        title: 'Premium',
        icon: Icons.workspace_premium_rounded,
        body: const Text(
          'Get unlimited likes, see who likes you, and use advanced filters.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
        actionLabel: 'View plans',
        onAction: () {
          Navigator.pop(context);
          _showMessage('Premium plans are coming soon.');
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final avatarPhoto = _user.photos.isNotEmpty
        ? _user.photos.first
        : _user.profileImagePath;

    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Stack with 180px Banner & Overlapping Avatar Layout
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Top Banner (180px height)
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _user.bannerImagePath == null
                        ? _getGradientForStyle(_user.bannerGradientStyle)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (_user.bannerImagePath != null)
                        SafeImage(
                          urlOrPath: _user.bannerImagePath,
                          width: double.infinity,
                          height: 180,
                        ),
                      if (_user.hasPatternMesh)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.15,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 20,
                              ),
                              itemCount: 200,
                              itemBuilder: (context, i) => Container(
                                margin: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Change Banner Button (Bottom Right of Banner)
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: GestureDetector(
                          onTap: _showEditBannerSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'switch banner',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Actions over banner (Back button & Moon icon left, Edit + Tune right)
                Positioned(
                  top: 52,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onBack ?? () => Navigator.maybePop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ThemeController.instance.toggle();
                              setState(() {});
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                ThemeColors.isDark(context)
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _editProfile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showSettings,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Overlapping Squircle Avatar & Badges
                Positioned(
                  top: 130,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Squircle Avatar Container with Gradient Ring Border
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [AppColors.pink, AppColors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: SafeImage(
                                urlOrPath: avatarPhoto,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          // Top-left online green dot
                          Positioned(
                            top: -2,
                            left: -2,
                            child: PulsingIndicator(
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.black,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-right Camera Icon Button for Avatar Upload
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: PressableScale(
                              onTap: () => _pickPhoto(),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.black,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Badges on the right of avatar (Verified, Premium, @handle)
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_user.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.purple,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_user.isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.pink, AppColors.purple],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Premium',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                _user.handle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
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

            // Main Content Below Avatar
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, Handle, Location Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${_user.name}, ${_user.age}',
                                    style: TextStyle(
                                      color: ThemeColors.text(context),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _editProfile,
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: ThemeColors.mutedText(context),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_user.handle} • ${_user.location}',
                              style: TextStyle(
                                color: ThemeColors.text(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '• ${_user.pronouns}',
                              style: TextStyle(
                                color: ThemeColors.mutedText(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF08A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_user.completionPercentage}% complete',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_user.handle} • verified',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pink-to-Purple Gradient Progress Bar Track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _user.completionPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.pink, AppColors.purple],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // "How you want to be seen" Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'How you want to be seen: ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Your display name and handle are public. First/last name help verification only. ',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Learn more',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ABOUT ME Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ABOUT ME',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: _editProfile,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.white54,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      _user.bio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PHOTOS Grid (3/6)
                  _buildPhotoGrid(),
                  const SizedBox(height: 24),

                  // PROMPT Card
                  _buildPromptCard(),
                  const SizedBox(height: 24),

                  // INTERESTS Section
                  _buildInterestsSection(),
                  const SizedBox(height: 24),

                  // BASICS Section
                  _buildBasicsSection(),
                  const SizedBox(height: 24),

                  // WALLET & LEVEL Card
                  _buildWalletCard(),
                  const SizedBox(height: 24),

                  // SETTINGS Section
                  _buildSettingsSection(),
                  const SizedBox(height: 28),

                  // App Footer
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final count = _user.photos.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHOTOS • $count/6',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            if (index < _user.photos.length) {
              final photoPath = _user.photos[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SafeImage(
                        urlOrPath: photoPath,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return GestureDetector(
                onTap: () => _pickPhoto(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white38,
                      size: 28,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPromptCard() {
    return GestureDetector(
      onTap: _editProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROMPT',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _user.promptQuestion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user.promptAnswer,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INTERESTS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._user.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: _editProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  '+ Add',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BASICS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              _buildBasicTile(
                icon: Icons.location_on_outlined,
                label: 'LOCATION',
                value: _user.location,
                onTap: _editProfile,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildBasicTile(
                icon: Icons.straighten_rounded,
                label: 'HEIGHT',
                value: _user.height,
                onTap: _editProfile,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildBasicTile(
                icon: Icons.work_outline_rounded,
                label: 'JOB',
                value: _user.job,
                onTap: _editProfile,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildBasicTile(
                icon: Icons.school_outlined,
                label: 'EDUCATION',
                value: _user.education,
                onTap: _editProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white70,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF08A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Wallet • ${_user.walletCoins} coins',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => WalletScreen.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _user.levelProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _user.userLevel,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(_user.levelProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SETTINGS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Push, email',
                onTap: _openNotifications,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildSettingTile(
                icon: Icons.shield_outlined,
                title: 'Privacy',
                subtitle: 'Blocked, visibility',
                onTap: _openPrivacy,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildSettingTile(
                icon: Icons.credit_card_rounded,
                title: 'Payment Methods',
                subtitle: 'Apple Pay, cards',
                onTap: _openPaymentMethods,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildSettingTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'FAQ, contact',
                onTap: _openHelpSupport,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildSettingTile(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                isDestructive: true,
                onTap: () => _showMessage('You have been logged out.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.pink.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.pink : AppColors.gold,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? AppColors.pink : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDestructive)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white30,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'african_affinity v2026.1 • Made with ♥ in SF',
        style: TextStyle(
          color: Colors.white24,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.title,
    required this.icon,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final Widget body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.gold.withValues(alpha: .16),
              child: Icon(icon, color: AppColors.gold, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            body,
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceTile {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool Function() value;
  final ValueChanged<bool> onChanged;
}
