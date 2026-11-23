import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../content/profile_content.dart';
import '../../../core/api/api_client.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/api_errors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/common.dart';
import '../../../models/me.dart';
import 'form_bits.dart';

/// Username, name, birthday, gender, seeking, city and country — the fields
/// `/me/complete-onboarding` requires. Same body as the web's StepBasics.
class BasicsForm extends ConsumerStatefulWidget {
  const BasicsForm({super.key, required this.submitLabel, required this.onSaved, this.onboardingStep});
  final String submitLabel;
  final ValueChanged<Me> onSaved;
  final int? onboardingStep;
  @override
  ConsumerState<BasicsForm> createState() => _BasicsFormState();
}

class _BasicsFormState extends ConsumerState<BasicsForm> {
  late final Me _me = ref.read(meProvider).requireValue!;
  late final _username = TextEditingController(text: _me.username ?? '');
  late final _name = TextEditingController(text: _me.displayName ?? '');
  late final _city = TextEditingController(text: _me.city ?? '');
  late DateTime? _birth = _me.birthDate == null ? null : DateTime.tryParse(_me.birthDate!);
  late String? _gender = _me.gender;
  late final Set<String> _seeking = {..._me.seeking};
  late String _country = _me.countryCode ?? 'CM';
  String _avail = 'idle'; // idle | checking | ok | taken | bad
  Timer? _debounce;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_username.text.isNotEmpty) _avail = 'ok';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _username.dispose();
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  void _checkUsername(String raw) {
    final u = raw.toLowerCase();
    _debounce?.cancel();
    if (u == (_me.username ?? '')) return setState(() => _avail = 'ok');
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(u)) return setState(() => _avail = u.isEmpty ? 'idle' : 'bad');
    setState(() => _avail = 'checking');
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final r = await ref.read(apiClientProvider).getJson('/me/username-available', query: {'u': u});
        if (mounted && _username.text.toLowerCase() == u) setState(() => _avail = r['available'] == true ? 'ok' : 'taken');
      } catch (_) {
        if (mounted) setState(() => _avail = 'idle');
      }
    });
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 99),
      lastDate: latest,
      helpText: 'Your birthday — you must be 18+',
    );
    if (d != null) setState(() => _birth = d);
  }

  City? get _picked =>
      cities.where((c) => c.name.toLowerCase() == _city.text.trim().toLowerCase() && c.cc == _country).firstOrNull;

  Future<void> _submit() async {
    String? problem;
    if (_avail != 'ok') problem = _avail == 'taken' ? 'That username is taken.' : 'Choose a username: 3–24 letters, numbers or _.';
    if (_name.text.trim().isEmpty) problem ??= 'Add the name people will see.';
    if (_birth == null) problem ??= 'Add your birthday.';
    if (_gender == null || _seeking.isEmpty) problem ??= 'Say who you are and who you are looking for.';
    if (_city.text.trim().isEmpty) problem ??= 'Add your city.';
    if (problem != null) {
      showToast(context, problem, error: true);
      return;
    }
    setState(() => _busy = true);
    final b = _birth!;
    final picked = _picked;
    try {
      final me = await ref.read(meProvider.notifier).patch({
        'username': _username.text.toLowerCase(),
        'display_name': _name.text.trim(),
        'birth_date': '${b.year.toString().padLeft(4, '0')}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}',
        'gender': _gender,
        'seeking': _seeking.toList(),
        'city': _city.text.trim(),
        'country_code': _country,
        if (picked != null) 'lat': picked.lat,
        if (picked != null) 'lng': picked.lng,
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
    final q = _city.text.trim().toLowerCase();
    final suggestions = q.length < 2 || _picked != null ? const <City>[] : cities.where((c) => c.name.toLowerCase().startsWith(q)).take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FieldLabel('Username'),
      TextField(
        controller: _username,
        style: fieldText,
        autocorrect: false,
        maxLength: 24,
        onChanged: (v) {
          final clean = v.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
          if (clean != v) _username.value = TextEditingValue(text: clean, selection: TextSelection.collapsed(offset: clean.length));
          _checkUsername(clean);
        },
        decoration: fieldDecoration('yourname',
            suffix: switch (_avail) {
              'checking' => const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
              'ok' => const Icon(Icons.check_circle_rounded, color: AppColors.success),
              'taken' || 'bad' => const Icon(Icons.error_outline_rounded, color: AppColors.error),
              _ => null,
            },
            error: switch (_avail) { 'taken' => 'Taken — try another', 'bad' => '3–24 letters, numbers or _', _ => null }),
      ),
      const FieldLabel('First name'),
      TextField(controller: _name, style: fieldText, maxLength: 40, textCapitalization: TextCapitalization.words, decoration: fieldDecoration('What people call you')),
      const FieldLabel('Birthday'),
      InkWell(
        onTap: _pickBirth,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: fieldDecoration('Choose your birthday', suffix: const Icon(Icons.cake_outlined, color: Colors.white38)),
          child: Text(
            _birth == null ? 'Choose your birthday' : '${_birth!.day}/${_birth!.month}/${_birth!.year}',
            style: TextStyle(color: _birth == null ? Colors.white30 : Colors.white),
          ),
        ),
      ),
      const FieldLabel('I am'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final g in genderLabels.entries) Pill(g.value, selected: _gender == g.key, onTap: () => setState(() => _gender = g.key)),
      ]),
      const FieldLabel('Looking for', trailing: 'Pick any'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final g in genderLabels.entries)
          Pill(g.value, selected: _seeking.contains(g.key), onTap: () => setState(() => _seeking.contains(g.key) ? _seeking.remove(g.key) : _seeking.add(g.key))),
      ]),
      const FieldLabel('City'),
      TextField(controller: _city, style: fieldText, maxLength: 80, onChanged: (_) => setState(() {}), decoration: fieldDecoration('Douala, Paris, …')),
      for (final c in suggestions)
        ListTile(
          dense: true,
          leading: const Icon(Icons.place_outlined, color: AppColors.gold, size: 18),
          title: Text(c.name, style: const TextStyle(color: Colors.white)),
          trailing: Text(countryName(c.cc), style: const TextStyle(color: Colors.white38, fontSize: 12)),
          onTap: () => setState(() {
            _city.text = c.name;
            _country = c.cc;
            FocusScope.of(context).unfocus();
          }),
        ),
      const FieldLabel('Country'),
      ChoiceField(
        value: _country,
        options: {for (final e in countries.entries) e.key: e.value.$1},
        onChanged: (v) => setState(() => _country = v ?? _country),
      ),
      const SizedBox(height: 28),
      PrimaryButton(label: widget.submitLabel, loading: _busy, onPressed: _submit),
    ]);
  }
}
