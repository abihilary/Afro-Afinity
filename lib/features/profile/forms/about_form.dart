import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/profile_content.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/api_errors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/common.dart';
import '../../../models/me.dart';
import '../../../models/profile_options.dart';
import 'form_bits.dart';

/// Bio, interests, languages, goal, tribe, height, religion — and, outside
/// onboarding, the ten structured attributes from `/profile-options`.
class AboutForm extends ConsumerStatefulWidget {
  const AboutForm({super.key, required this.submitLabel, required this.onSaved, this.onboardingStep, this.showAttributes = false});
  final String submitLabel;
  final ValueChanged<Me> onSaved;
  final int? onboardingStep;
  final bool showAttributes;
  @override
  ConsumerState<AboutForm> createState() => _AboutFormState();
}

class _AboutFormState extends ConsumerState<AboutForm> {
  late final Me _me = ref.read(meProvider).requireValue!;
  late final _bio = TextEditingController(text: _me.bio ?? '');
  late final _tribe = TextEditingController(text: _me.tribe ?? '');
  late final _religion = TextEditingController(text: _me.religion ?? '');
  late final _region = TextEditingController(text: _me.region ?? '');
  late final _height = TextEditingController(text: _me.heightCm?.toString() ?? '');
  late final Set<String> _interests = {..._me.interests.where(interestLabels.containsKey)};
  late final Set<String> _languages = {...(_me.languages.isEmpty ? [_me.locale] : _me.languages)};
  late String? _goal = _me.goal;
  late final Map<String, String?> _attrs = {for (final f in ProfileOptions.fieldLabels.keys) f: _me.attribute(f)};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_bio, _tribe, _religion, _region, _height]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final h = int.tryParse(_height.text.trim());
    if (_height.text.trim().isNotEmpty && (h == null || h < 120 || h > 230)) {
      showToast(context, 'Height should be between 120 and 230 cm.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final me = await ref.read(meProvider.notifier).patch({
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'interests': _interests.toList(),
        'languages': _languages.toList(),
        'goal': _goal,
        'tribe': _tribe.text.trim().isEmpty ? null : _tribe.text.trim(),
        'religion': _religion.text.trim().isEmpty ? null : _religion.text.trim(),
        'height_cm': h,
        if (widget.showAttributes) 'region': _region.text.trim().isEmpty ? null : _region.text.trim(),
        if (widget.showAttributes) ..._attrs,
        if (widget.onboardingStep != null) 'onboarding_step': widget.onboardingStep,
      });
      widget.onSaved(me);
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final options = ref.watch(profileOptionsProvider).valueOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FieldLabel('About me', trailing: '${_bio.text.length}/500'),
      TextField(
        controller: _bio,
        style: fieldText,
        maxLines: 4,
        maxLength: 500,
        onChanged: (_) => setState(() {}),
        decoration: fieldDecoration('A few lines about you, what you love, what you are looking for'),
      ),
      FieldLabel('Interests', trailing: '${_interests.length}/12'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in interestLabels.entries)
          Pill('${e.value.emoji} ${e.value.label(locale)}',
              selected: _interests.contains(e.key),
              onTap: () => setState(() {
                    if (_interests.contains(e.key)) {
                      _interests.remove(e.key);
                    } else if (_interests.length < 12) {
                      _interests.add(e.key);
                    }
                  })),
      ]),
      const FieldLabel('Looking for'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final g in goalLabels.entries) Pill(g.value, selected: _goal == g.key, onTap: () => setState(() => _goal = _goal == g.key ? null : g.key)),
      ]),
      FieldLabel('Languages', trailing: '${_languages.length}/8'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final l in languageLabels.entries)
          Pill(l.value,
              selected: _languages.contains(l.key),
              onTap: () => setState(() {
                    if (_languages.contains(l.key)) {
                      if (_languages.length > 1) _languages.remove(l.key);
                    } else if (_languages.length < 8) {
                      _languages.add(l.key);
                    }
                  })),
      ]),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const FieldLabel('Tribe / heritage'),
            TextField(controller: _tribe, style: fieldText, maxLength: 60, decoration: fieldDecoration('Optional')),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const FieldLabel('Height (cm)'),
            TextField(controller: _height, style: fieldText, keyboardType: TextInputType.number, maxLength: 3, decoration: fieldDecoration('Optional')),
          ]),
        ),
      ]),
      const FieldLabel('Religion'),
      TextField(controller: _religion, style: fieldText, maxLength: 40, decoration: fieldDecoration('Optional')),
      if (widget.showAttributes) ...[
        const FieldLabel('Region'),
        TextField(controller: _region, style: fieldText, maxLength: 60, decoration: fieldDecoration('Optional')),
        if (options != null)
          for (final f in ProfileOptions.fieldLabels.entries)
            if (options.of(f.key).isNotEmpty) ...[
              FieldLabel(f.value),
              ChoiceField(
                value: _attrs[f.key],
                options: {for (final o in options.of(f.key)) o.value: o.label(locale)},
                onChanged: (v) => setState(() => _attrs[f.key] = v),
              ),
            ],
      ],
      const SizedBox(height: 28),
      PrimaryButton(label: widget.submitLabel, loading: _busy, onPressed: _submit),
    ]);
  }
}
