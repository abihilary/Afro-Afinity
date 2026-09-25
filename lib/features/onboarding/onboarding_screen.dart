import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String? _pronouns;
  String? _lookingFor;
  DateTime? _birthday;

  final Set<String> _interests = <String>{};

  final List<XFile> _photos = <XFile>[];

  late AnimationController _animationController;

  bool _isPickingPhotos = false;

  final List<String> _interestOptions = <String>[
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
    'Suya',
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

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  void _next() {
    if (!_validateStep()) {
      return;
    }

    if (_step < 3) {
      setState(() {
        _step++;
      });

      _animationController
        ..reset()
        ..forward();
    } else {
      _finishOnboarding();
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

  void _finishOnboarding() {
    // At this stage the profile information is ready.
    //
    // Later this is where we can save the completed profile
    // to Riverpod/backend/storage.
    //
    // For now we proceed directly to Discover.

    context.go('/discover');
  }

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------

  bool _validateStep() {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showMessage('Please enter your name.');
        return false;
      }

      if (_birthday == null) {
        _showMessage('Please select your birthday.');
        return false;
      }

      if (_calculateAge(_birthday!) < 18) {
        _showMessage('You must be at least 18 years old.');
        return false;
      }

      if (_pronouns == null) {
        _showMessage('Please select your pronouns.');
        return false;
      }
    }

    if (_step == 1) {
      if (_lookingFor == null) {
        _showMessage('Please choose who you want to meet.');
        return false;
      }
    }

    if (_step == 2) {
      if (_interests.length < 3) {
        _showMessage('Choose at least 3 interests.');
        return false;
      }
    }

    if (_step == 3) {
      if (_photos.isEmpty) {
        _showMessage('Please add at least one profile photo.');
        return false;
      }

      if (_bioController.text.trim().length < 10) {
        _showMessage(
          'Add a short bio of at least 10 characters.',
        );
        return false;
      }
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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

  // ------------------------------------------------------------
  // BIRTHDAY
  // ------------------------------------------------------------

  Future<void> _pickBirthday() async {
    final now = DateTime.now();

    final DateTime maximumDate = DateTime(
      now.year - 18,
      now.month,
      now.day,
    );

    final DateTime minimumDate = DateTime(
      now.year - 100,
      now.month,
      now.day,
    );

    final DateTime defaultDate = DateTime(
      now.year - 25,
      now.month,
      now.day,
    );

    DateTime initialDate = _birthday ?? defaultDate;

    if (initialDate.isAfter(maximumDate)) {
      initialDate = maximumDate;
    }

    if (initialDate.isBefore(minimumDate)) {
      initialDate = minimumDate;
    }

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minimumDate,
      lastDate: maximumDate,
      helpText: 'Select your birthday',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD9A441),
              onPrimary: Color(0xFF171519),
              surface: Color(0xFF1A191D),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _birthday = selectedDate;
    });
  }

  int _calculateAge(DateTime birthday) {
    final DateTime today = DateTime.now();

    int age = today.year - birthday.year;

    if (today.month < birthday.month ||
        (today.month == birthday.month &&
            today.day < birthday.day)) {
      age--;
    }

    return age;
  }

  // ------------------------------------------------------------
  // PHOTO PICKER
  // ------------------------------------------------------------

  Future<void> _pickPhotos() async {
    if (_isPickingPhotos) {
      return;
    }

    if (_photos.length >= 6) {
      _showMessage('You can add up to 6 photos.');
      return;
    }

    setState(() {
      _isPickingPhotos = true;
    });

    try {
      final List<XFile> selectedImages =
      await _imagePicker.pickMultiImage(
        imageQuality: 90,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (!mounted) {
        return;
      }

      if (selectedImages.isEmpty) {
        setState(() {
          _isPickingPhotos = false;
        });
        return;
      }

      final int remainingSlots = 6 - _photos.length;

      final List<XFile> imagesToAdd =
      selectedImages.take(remainingSlots).toList();

      setState(() {
        _photos.addAll(imagesToAdd);
        _isPickingPhotos = false;
      });

      if (selectedImages.length > remainingSlots) {
        _showMessage('Only 6 photos can be added to your profile.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPickingPhotos = false;
      });

      _showMessage('Unable to select photos. Please try again.');
    }
  }

  Future<void> _replacePhoto(int index) async {
    try {
      final XFile? selectedImage =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (selectedImage == null || !mounted) {
        return;
      }

      setState(() {
        _photos[index] = selectedImage;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to replace this photo.');
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photos.length) {
      return;
    }

    setState(() {
      _photos.removeAt(index);
    });
  }

  void _movePhoto(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _photos.length ||
        newIndex < 0 ||
        newIndex >= _photos.length) {
      return;
    }

    setState(() {
      final XFile photo = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, photo);
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF121216);
    const Color gold = Color(0xFFDAA520);
    const Color terracotta = Color(0xFFC17C3C);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
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
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

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
                final bool active = index <= _step;

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

  // ------------------------------------------------------------
  // STEP SWITCHER
  // ------------------------------------------------------------

  Widget _buildStep({
    required Color gold,
    required Color terracotta,
  }) {
    switch (_step) {
      case 0:
        return _buildIdentity(gold);

      case 1:
        return _buildLookingFor(gold);

      case 2:
        return _buildInterests(gold);

      default:
        return _buildProfile(gold, terracotta);
    }
  }

  // ------------------------------------------------------------
  // STEP 1 — IDENTITY
  // ------------------------------------------------------------

  Widget _buildIdentity(Color gold) {
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

        const SizedBox(height: 8),

        GestureDetector(
          onTap: _pickBirthday,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _fieldDecoration(
              highlighted: _birthday != null,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF8F8A91),
                  size: 19,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: _birthday == null
                      ? const Text(
                    'Your birthday',
                    style: TextStyle(
                      color: Color(0xFF858087),
                      fontSize: 14,
                    ),
                  )
                      : Text(
                    '${_birthday!.day.toString().padLeft(2, '0')}/'
                        '${_birthday!.month.toString().padLeft(2, '0')}/'
                        '${_birthday!.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (_birthday != null)
                  Text(
                    '${_calculateAge(_birthday!)}',
                    style: TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                const SizedBox(width: 8),

                Icon(
                  Icons.chevron_right_rounded,
                  color: gold,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        _label('Pronouns'),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'He/Him',
            'She/Her',
            'They/Them',
            'Non-binary',
            'Prefer not to say',
          ].map(
                (value) {
              return _choiceChip(
                value,
                _pronouns == value,
                gold,
                    () {
                  setState(() {
                    _pronouns = value;
                  });
                },
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // STEP 2 — LOOKING FOR
  // ------------------------------------------------------------

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
              setState(() {
                _lookingFor = item.$1;
              });
            },
          ),
        ),

        const SizedBox(height: 28),

        _label('Age range 18–65'),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _rangeBox('Min', '18'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 18,
                child: Divider(
                  color: Colors.white24,
                ),
              ),
            ),
            Expanded(
              child: _rangeBox('Max', '65'),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // STEP 3 — INTERESTS
  // ------------------------------------------------------------

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
          children: _interestOptions.map(
                (interest) {
              final bool selected =
              _interests.contains(interest);

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
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ).toList(),
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

  // ------------------------------------------------------------
  // STEP 4 — PHOTOS + BIO
  // ------------------------------------------------------------

  Widget _buildProfile(
      Color gold,
      Color terracotta,
      ) {
    return _page(
      title: 'Make your profile yours',
      subtitle:
      'Add a little personality before you start meeting people.',
      buttonText: 'Finish profile',
      onPressed: _next,
      children: [
        const SizedBox(height: 8),

        _label('Photos'),

        const SizedBox(height: 10),

        _buildPhotoGrid(
          gold: gold,
          terracotta: terracotta,
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Add up to 6 photos. Your first photo is your main profile photo.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
            hintText:
            'Tell people something about you...',
            hintStyle: const TextStyle(
              color: Color(0xFF68636A),
            ),
            filled: true,
            fillColor:
            Colors.white.withValues(alpha: 0.045),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(18),
              borderSide: BorderSide(
                color:
                Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(18),
              borderSide: BorderSide(
                color:
                Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(18),
              borderSide: BorderSide(
                color: gold,
              ),
            ),
            counterStyle: const TextStyle(
              color: Color(0xFF777279),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PHOTO GRID
  // ------------------------------------------------------------

  Widget _buildPhotoGrid({
    required Color gold,
    required Color terracotta,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final bool hasPhoto =
            index < _photos.length;

        if (hasPhoto) {
          return _photoTile(
            index,
            gold,
          );
        }

        return _addPhotoTile(
          index,
          gold,
          terracotta,
        );
      },
    );
  }

  Widget _addPhotoTile(
      int index,
      Color gold,
      Color terracotta,
      ) {
    return GestureDetector(
      onTap: _pickPhotos,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.035,
          ),
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.1,
            ),
          ),
          gradient: index == 0
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              terracotta.withValues(
                alpha: 0.32,
              ),
              gold.withValues(
                alpha: 0.15,
              ),
            ],
          )
              : null,
        ),
        child: _isPickingPhotos && index == 0
            ? const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        )
            : Icon(
          index == 0
              ? Icons.add_a_photo_outlined
              : Icons.add_rounded,
          color: index == 0
              ? Colors.white
              : const Color(0xFF777279),
          size: index == 0 ? 27 : 25,
        ),
      ),
    );
  }

  Widget _photoTile(
      int index,
      Color gold,
      ) {
    final XFile photo = _photos[index];

    return GestureDetector(
      onTap: () => _showPhotoOptions(index),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  color: Colors.white
                      .withValues(alpha: 0.06),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                  ),
                );
              },
            ),

            // Dark bottom gradient.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 65,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black
                          .withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            if (index == 0)
              Positioned(
                left: 7,
                bottom: 7,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MAIN',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: Colors.black
                      .withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

            Positioned(
              bottom: 7,
              right: 7,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PHOTO OPTIONS
  // ------------------------------------------------------------

  void _showPhotoOptions(int index) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
      const Color(0xFF1A191D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Photo options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 15),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Replace photo',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _replacePhoto(index);
                  },
                ),

                if (index > 0)
                  ListTile(
                    leading: const Icon(
                      Icons.star_outline_rounded,
                      color: Color(0xFFDAA520),
                    ),
                    title: const Text(
                      'Make main photo',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _movePhoto(index, 0);
                    },
                  ),

                if (index > 0)
                  ListTile(
                    leading: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Move left',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      if (index > 0) {
                        _movePhoto(index, index - 1);
                      }
                    },
                  ),

                if (index < _photos.length - 1)
                  ListTile(
                    leading: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Move right',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      if (index <
                          _photos.length - 1) {
                        _movePhoto(index, index + 1);
                      }
                    },
                  ),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto(index);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // PAGE
  // ------------------------------------------------------------

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
          padding:
          const EdgeInsets.fromLTRB(
            20,
            26,
            20,
            28,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
              constraints.maxHeight - 10,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
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

  // ------------------------------------------------------------
  // LABEL
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

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
          color: Colors.black,
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
          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 14,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FIELD DECORATION
  // ------------------------------------------------------------

  BoxDecoration _fieldDecoration({
    bool highlighted = false,
  }) {
    return BoxDecoration(
      color:
      Colors.white.withValues(alpha: 0.045),
      borderRadius:
      BorderRadius.circular(16),
      border: Border.all(
        color: highlighted
            ? const Color(0xFFDAA520)
            .withValues(alpha: 0.65)
            : Colors.white
            .withValues(alpha: 0.08),
      ),
    );
  }

  // ------------------------------------------------------------
  // CHOICE CHIP
  // ------------------------------------------------------------

  Widget _choiceChip(
      String text,
      bool selected,
      Color gold,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? gold
              : Colors.white
              .withValues(alpha: 0.045),
          borderRadius:
          BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? gold
                : Colors.white
                .withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Colors.black
                : Colors.white70,
            fontSize: 12,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOOKING CARD
  // ------------------------------------------------------------

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
        duration:
        const Duration(milliseconds: 200),
        margin:
        const EdgeInsets.only(bottom: 10),
        height: 72,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white
              .withValues(alpha: 0.045),
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white
                .withValues(alpha: 0.09),
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
                    ? Colors.black
                    .withValues(alpha: 0.08)
                    : Colors.white
                    .withValues(alpha: 0.06),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: selected
                        ? Colors.black
                        : gold,
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? Colors.black
                          : Colors.white,
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w700,
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
                color: selected
                    ? Colors.black
                    : Colors.transparent,
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

  // ------------------------------------------------------------
  // RANGE BOX
  // ------------------------------------------------------------

  Widget _rangeBox(
      String label,
      String value,
      ) {
    return Container(
      height: 50,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
      ),
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

  // ------------------------------------------------------------
  // GRADIENT BUTTON
  // ------------------------------------------------------------

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
        borderRadius:
        BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDAA520)
                .withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor:
          Colors.transparent,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(17),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
    );
  }
}