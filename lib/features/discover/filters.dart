import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../content/profile_content.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/common.dart';
import '../../models/profile_options.dart';
import '../profile/forms/form_bits.dart';

/// Filters shared by Discover (`GET /discover`, free keys only) and Search
/// (`POST /search`, everything). The advanced keys are Platinum's
/// `advanced_search`; the database refuses them otherwise, so they render
/// locked rather than failing on submit.
class SearchFilters {
  const SearchFilters({
    this.minAge = 18,
    this.maxAge = 60,
    this.radiusKm,
    this.online = false,
    this.verified = false,
    this.gender,
    this.country,
    this.city,
    this.tribe,
    this.interests = const {},
    this.goal,
    this.religion,
    this.region,
    this.languages = const {},
    this.heightMin,
    this.heightMax,
    this.attrs = const {},
  });

  final int minAge;
  final int maxAge;
  final int? radiusKm;
  final bool online;
  final bool verified;
  final String? gender;
  final String? country;
  final String? city;
  final String? tribe;
  final Set<String> interests;
  // advanced
  final String? goal;
  final String? religion;
  final String? region;
  final Set<String> languages;
  final int? heightMin;
  final int? heightMax;
  final Map<String, String> attrs;

  bool get hasAdvanced =>
      goal != null || religion != null || region != null || languages.isNotEmpty || heightMin != null || heightMax != null || attrs.isNotEmpty;

  int get activeCount => [
        minAge != 18 || maxAge != 60,
        radiusKm != null,
        online,
        verified,
        gender != null,
        country != null,
        city != null,
        tribe != null,
        interests.isNotEmpty,
        hasAdvanced,
      ].where((x) => x).length;

  /// Query for `GET /discover`.
  Map<String, dynamic> toDiscoverQuery() => {
        'min_age': minAge,
        'max_age': maxAge,
        'radius_km': radiusKm,
        'online': online ? 'true' : null,
        'verified': verified ? 'true' : null,
        'gender': gender,
        'country': country,
        'city': city,
        'tribe': tribe,
        'interests': interests.isEmpty ? null : interests.join(','),
      };

  /// Body `filters` for `POST /search`.
  Map<String, dynamic> toSearchFilters() => {
        'min_age': minAge,
        'max_age': maxAge,
        'radius_km': ?radiusKm,
        if (online) 'online': true,
        if (verified) 'verified': true,
        'gender': ?gender,
        'country': ?country,
        'city': ?city,
        'tribe': ?tribe,
        if (interests.isNotEmpty) 'interests': interests.toList(),
        'goal': ?goal,
        'religion': ?religion,
        'region': ?region,
        if (languages.isNotEmpty) 'languages': languages.toList(),
        'height_min': ?heightMin,
        'height_max': ?heightMax,
        if (attrs.isNotEmpty) 'attrs': attrs,
      };

  factory SearchFilters.fromJson(Map<String, dynamic> j) => SearchFilters(
        minAge: (j['min_age'] as num?)?.toInt() ?? 18,
        maxAge: (j['max_age'] as num?)?.toInt() ?? 60,
        radiusKm: (j['radius_km'] as num?)?.toInt(),
        online: j['online'] == true,
        verified: j['verified'] == true,
        gender: j['gender'] as String?,
        country: j['country'] as String?,
        city: j['city'] as String?,
        tribe: j['tribe'] as String?,
        interests: {...?(j['interests'] as List?)?.map((e) => '$e')},
        goal: j['goal'] as String?,
        religion: j['religion'] as String?,
        region: j['region'] as String?,
        languages: {...?(j['languages'] as List?)?.map((e) => '$e')},
        heightMin: (j['height_min'] as num?)?.toInt(),
        heightMax: (j['height_max'] as num?)?.toInt(),
        attrs: {...?(j['attrs'] as Map?)?.map((k, v) => MapEntry('$k', '$v'))},
      );
}

/// Opens the filter sheet; resolves to the new filters, or null if dismissed.
Future<SearchFilters?> showFiltersSheet(BuildContext context, SearchFilters current, {bool advanced = false}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      maxChildSize: .95,
      builder: (_, scroll) => _FiltersSheet(initial: current, showAdvanced: advanced, scroll: scroll),
    ),
  );
}

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet({required this.initial, required this.showAdvanced, required this.scroll});
  final SearchFilters initial;
  final bool showAdvanced;
  final ScrollController scroll;
  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late RangeValues _age = RangeValues(widget.initial.minAge.toDouble(), widget.initial.maxAge.toDouble());
  late int? _radius = widget.initial.radiusKm;
  late bool _online = widget.initial.online;
  late bool _verified = widget.initial.verified;
  late String? _gender = widget.initial.gender;
  late String? _country = widget.initial.country;
  late final _city = TextEditingController(text: widget.initial.city ?? '');
  late final _tribe = TextEditingController(text: widget.initial.tribe ?? '');
  late final Set<String> _interests = {...widget.initial.interests};
  late String? _goal = widget.initial.goal;
  late final _religion = TextEditingController(text: widget.initial.religion ?? '');
  late final _region = TextEditingController(text: widget.initial.region ?? '');
  late final Set<String> _languages = {...widget.initial.languages};
  late RangeValues? _height = widget.initial.heightMin == null && widget.initial.heightMax == null
      ? null
      : RangeValues((widget.initial.heightMin ?? 140).toDouble(), (widget.initial.heightMax ?? 210).toDouble());
  late final Map<String, String> _attrs = {...widget.initial.attrs};

  @override
  void dispose() {
    for (final c in [_city, _tribe, _religion, _region]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  SearchFilters _build(bool allowAdvanced) => SearchFilters(
        minAge: _age.start.round(),
        maxAge: _age.end.round(),
        radiusKm: _radius,
        online: _online,
        verified: _verified,
        gender: _gender,
        country: _country,
        city: _t(_city),
        tribe: _t(_tribe),
        interests: _interests,
        goal: allowAdvanced ? _goal : null,
        religion: allowAdvanced ? _t(_religion) : null,
        region: allowAdvanced ? _t(_region) : null,
        languages: allowAdvanced ? _languages : const {},
        heightMin: allowAdvanced ? _height?.start.round() : null,
        heightMax: allowAdvanced ? _height?.end.round() : null,
        attrs: allowAdvanced ? _attrs : const {},
      );

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final unlocked = ref.watch(meProvider).valueOrNull?.perks.advancedSearch ?? false;
    final options = ref.watch(profileOptionsProvider).valueOrNull;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
        child: Column(children: [
          const SheetHandle(),
          Row(children: [
            const Text('Filters', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context, const SearchFilters()), child: const Text('Reset', style: TextStyle(color: Colors.white54))),
          ]),
        ]),
      ),
      Expanded(
        child: ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
          FieldLabel('Age', trailing: '${_age.start.round()} – ${_age.end.round()}'),
          RangeSlider(
            values: _age,
            min: 18,
            max: 99,
            divisions: 81,
            activeColor: AppColors.gold,
            onChanged: (v) => setState(() => _age = v),
          ),
          FieldLabel('Distance', trailing: _radius == null ? 'Anywhere' : 'Within $_radius km'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in [null, 10, 25, 50, 100, 500])
              Pill(r == null ? 'Anywhere' : '$r km', selected: _radius == r, onTap: () => setState(() => _radius = r)),
          ]),
          const FieldLabel('Show me'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Pill('Everyone I am looking for', selected: _gender == null, onTap: () => setState(() => _gender = null)),
            for (final g in genderLabels.entries) Pill(g.value, selected: _gender == g.key, onTap: () => setState(() => _gender = g.key)),
          ]),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _online,
            onChanged: (v) => setState(() => _online = v),
            activeThumbColor: AppColors.gold,
            contentPadding: EdgeInsets.zero,
            title: const Text('Online now', style: TextStyle(color: Colors.white)),
          ),
          SwitchListTile(
            value: _verified,
            onChanged: (v) => setState(() => _verified = v),
            activeThumbColor: AppColors.gold,
            contentPadding: EdgeInsets.zero,
            title: const Text('Verified only', style: TextStyle(color: Colors.white)),
          ),
          const FieldLabel('Country'),
          ChoiceField(
            value: _country,
            hint: 'Any country',
            options: {for (final e in countries.entries) e.key: e.value.$1},
            onChanged: (v) => setState(() => _country = v),
          ),
          const FieldLabel('City'),
          TextField(controller: _city, style: fieldText, decoration: fieldDecoration('Any city')),
          const FieldLabel('Tribe / heritage'),
          TextField(controller: _tribe, style: fieldText, decoration: fieldDecoration('Any')),
          FieldLabel('Interests', trailing: _interests.isEmpty ? 'Any' : '${_interests.length}'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in interestLabels.entries)
              Pill('${e.value.emoji} ${e.value.label(locale)}',
                  selected: _interests.contains(e.key),
                  onTap: () => setState(() => _interests.contains(e.key) ? _interests.remove(e.key) : _interests.add(e.key))),
          ]),
          if (widget.showAdvanced) ...[
            const SizedBox(height: 26),
            Row(children: [
              Icon(unlocked ? Icons.tune_rounded : Icons.lock_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              const Text('Advanced', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              if (!unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Platinum', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ]),
            if (!unlocked) ...[
              const SizedBox(height: 8),
              const Text('Search by what they are looking for, religion, languages, height and more with Platinum.',
                  style: TextStyle(color: Colors.white54, height: 1.4)),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'See Platinum',
                icon: Icons.workspace_premium_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/premium');
                },
              ),
            ] else ...[
              const FieldLabel('Looking for'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in goalLabels.entries) Pill(g.value, selected: _goal == g.key, onTap: () => setState(() => _goal = _goal == g.key ? null : g.key)),
              ]),
              const FieldLabel('Religion'),
              TextField(controller: _religion, style: fieldText, decoration: fieldDecoration('Any')),
              const FieldLabel('Region'),
              TextField(controller: _region, style: fieldText, decoration: fieldDecoration('Any')),
              const FieldLabel('Speaks'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final l in languageLabels.entries)
                  Pill(l.value, selected: _languages.contains(l.key), onTap: () => setState(() => _languages.contains(l.key) ? _languages.remove(l.key) : _languages.add(l.key))),
              ]),
              FieldLabel('Height', trailing: _height == null ? 'Any' : '${_height!.start.round()}–${_height!.end.round()} cm'),
              RangeSlider(
                values: _height ?? const RangeValues(140, 210),
                min: 120,
                max: 230,
                divisions: 110,
                activeColor: _height == null ? Colors.white24 : AppColors.gold,
                onChanged: (v) => setState(() => _height = v),
              ),
              if (options != null)
                for (final f in ProfileOptions.fieldLabels.entries)
                  // income_band is display-only; the search refuses it.
                  if (f.key != 'income_band' && options.of(f.key).isNotEmpty) ...[
                    FieldLabel(f.value),
                    ChoiceField(
                      value: _attrs[f.key],
                      hint: 'Any',
                      options: {for (final o in options.of(f.key)) o.value: o.label(locale)},
                      onChanged: (v) => setState(() => v == null ? _attrs.remove(f.key) : _attrs[f.key] = v),
                    ),
                  ],
            ],
          ],
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: PrimaryButton(label: 'Show results', onPressed: () => Navigator.pop(context, _build(unlocked))),
        ),
      ),
    ]);
  }
}
