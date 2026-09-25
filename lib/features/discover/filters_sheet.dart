import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../core/widgets/pressable.dart';
import 'discover_profiles.dart';

class DiscoveryFilters {
  const DiscoveryFilters({
    required this.ageRange,
    required this.location,
    required this.smoking,
    required this.drinking,
    required this.relationshipGoal,
  });

  final RangeValues ageRange;
  final String location;
  final String smoking;
  final String drinking;
  final String relationshipGoal;

  static const defaultFilters = DiscoveryFilters(
    ageRange: RangeValues(18, 40),
    location: '',
    smoking: 'All',
    drinking: 'All',
    relationshipGoal: 'All',
  );

  bool get isDefault =>
      ageRange.start == 18 &&
      ageRange.end == 40 &&
      location.trim().isEmpty &&
      smoking == 'All' &&
      drinking == 'All' &&
      relationshipGoal == 'All';

  int get activeFilterCount {
    int count = 0;
    if (ageRange.start != 18 || ageRange.end != 40) count++;
    if (location.trim().isNotEmpty) count++;
    if (smoking != 'All') count++;
    if (drinking != 'All') count++;
    if (relationshipGoal != 'All') count++;
    return count;
  }
}

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  final DiscoveryFilters initialFilters;
  final ValueChanged<DiscoveryFilters> onApply;

  static Future<void> show(
    BuildContext context, {
    required DiscoveryFilters initialFilters,
    required ValueChanged<DiscoveryFilters> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltersSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late RangeValues _ageRange;
  late String _smoking;
  late String _drinking;
  late String _relationshipGoal;
  late TextEditingController _locationController;

  final List<String> _smokingOptions = const [
    'All',
    'Non-smoker',
    'Social smoker',
    'Smoker',
  ];

  final List<String> _drinkingOptions = const [
    'All',
    'Non-drinker',
    'Social drinker',
    'Drinker',
  ];

  final List<String> _relationshipOptions = const [
    'All',
    'Long-term',
    'Marriage',
    'Dating',
    'Casual',
  ];

  @override
  void initState() {
    super.initState();
    _ageRange = widget.initialFilters.ageRange;
    _smoking = widget.initialFilters.smoking;
    _drinking = widget.initialFilters.drinking;
    _relationshipGoal = widget.initialFilters.relationshipGoal;
    _locationController =
        TextEditingController(text: widget.initialFilters.location);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  int get _matchingCount {
    final loc = _locationController.text.trim().toLowerCase();
    return discoverProfiles.where((p) {
      final matchesAge = p.age >= _ageRange.start && p.age <= _ageRange.end;
      final matchesLoc = loc.isEmpty || p.location.toLowerCase().contains(loc);
      final matchesSmoke = _smoking == 'All' || p.smoking == _smoking;
      final matchesDrink = _drinking == 'All' || p.drinking == _drinking;
      final matchesGoal =
          _relationshipGoal == 'All' || p.relationshipGoal == _relationshipGoal;
      return matchesAge && matchesLoc && matchesSmoke && matchesDrink && matchesGoal;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ThemeColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.mutedText(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deep Search Filters',
                        style: TextStyle(
                          color: ThemeColors.text(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      // Animated Live Match Count Pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.purple,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$_matchingCount matches',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Age Range Slider
                  Text(
                    'AGE RANGE: ${_ageRange.start.round()} – ${_ageRange.end.round()}',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 60,
                    divisions: 42,
                    activeColor: AppColors.gold,
                    onChanged: (val) => setState(() => _ageRange = val),
                  ),
                  const SizedBox(height: 16),

                  // Location Search Field
                  Text(
                    'LOCATION / CITY',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ThemeColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ThemeColors.border(context)),
                    ),
                    child: TextField(
                      controller: _locationController,
                      style: TextStyle(color: ThemeColors.text(context)),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Nairobi, Lagos, Yaoundé',
                        hintStyle: TextStyle(
                          color: ThemeColors.mutedText(context),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        icon: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Smoking Habits Filter
                  Text(
                    'SMOKING HABITS',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _smokingOptions.map((opt) {
                      final selected = _smoking == opt;
                      return PressableScale(
                        onTap: () => setState(() => _smoking = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.gold
                                : ThemeColors.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.gold
                                  : ThemeColors.border(context),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : ThemeColors.text(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Drinking Habits Filter
                  Text(
                    'DRINKING HABITS',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _drinkingOptions.map((opt) {
                      final selected = _drinking == opt;
                      return PressableScale(
                        onTap: () => setState(() => _drinking = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.gold
                                : ThemeColors.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.gold
                                  : ThemeColors.border(context),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : ThemeColors.text(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Relationship Goals Filter
                  Text(
                    'LOOKING FOR / RELATIONSHIP GOAL',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _relationshipOptions.map((opt) {
                      final selected = _relationshipGoal == opt;
                      return PressableScale(
                        onTap: () => setState(() => _relationshipGoal = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.pink
                                : ThemeColors.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.pink
                                  : ThemeColors.border(context),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : ThemeColors.text(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _ageRange = const RangeValues(18, 40);
                            _smoking = 'All';
                            _drinking = 'All';
                            _relationshipGoal = 'All';
                            _locationController.clear();
                          });
                        },
                        child: const Text('Reset All'),
                      ),
                      const Spacer(),
                      PressableScale(
                        onTap: () {
                          final updatedFilters = DiscoveryFilters(
                            ageRange: _ageRange,
                            location: _locationController.text.trim(),
                            smoking: _smoking,
                            drinking: _drinking,
                            relationshipGoal: _relationshipGoal,
                          );
                          widget.onApply(updatedFilters);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.pink, AppColors.purple],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pink.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Apply Filters ($_matchingCount)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
