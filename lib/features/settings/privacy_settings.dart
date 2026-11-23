import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../content/profile_content.dart';
import '../../core/api/api_client.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/widgets/common.dart';
import '../profile/forms/form_bits.dart';

const _levels = {'everyone': 'Everyone', 'members': 'Members only', 'connections': 'Matches & friends', 'only_me': 'Only me'};
const _contact = {'everyone': 'Everyone', 'connections': 'Matches & friends', 'nobody': 'Nobody'};

/// The eight privacy controls plus the gender gate, read through
/// `my_privacy()` so a member with no row still sees the real defaults.
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});
  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  Json? _p;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final j = await ref.read(apiClientProvider).getJson('/me/privacy');
      if (mounted) setState(() => _p = asMap(j['privacy']));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _set(String key, Object value) async {
    final before = _p;
    setState(() => _p = {...?_p, key: value});
    try {
      final j = await ref.read(apiClientProvider).patch('/me/privacy', data: {key: value});
      if (mounted) setState(() => _p = asMap(asMap(j)['privacy']));
    } catch (e) {
      if (!mounted) return;
      setState(() => _p = before);
      handleApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, foregroundColor: Colors.white, title: const Text('Privacy')),
      body: p == null
          ? (_error != null ? ErrorView(error: _error!, onRetry: _load) : const LoadingView())
          : ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 30), children: [
              const FieldLabel('Who can see my profile'),
              ChoiceField(value: asString(p['profile_visibility']), options: _levels, onChanged: (v) => v == null ? null : _set('profile_visibility', v)),
              const FieldLabel('Who can see all my photos'),
              ChoiceField(value: asString(p['photos_visibility']), options: _levels, onChanged: (v) => v == null ? null : _set('photos_visibility', v)),
              const FieldLabel('Who can hear my voice prompt'),
              ChoiceField(value: asString(p['audio_visibility']), options: _levels, onChanged: (v) => v == null ? null : _set('audio_visibility', v)),
              const FieldLabel('Who can message me'),
              ChoiceField(value: asString(p['who_can_message']), options: _contact, onChanged: (v) => v == null ? null : _set('who_can_message', v)),
              const FieldLabel('Who can send me friend requests'),
              ChoiceField(value: asString(p['who_can_friend']), options: _contact, onChanged: (v) => v == null ? null : _set('who_can_friend', v)),
              const FieldLabel('Only let these contact me', trailing: 'None picked = anyone'),
              Wrap(spacing: 8, children: [
                for (final g in genderLabels.entries)
                  Pill(g.value, selected: asStringList(p['contact_genders']).contains(g.key), onTap: () {
                    final cur = asStringList(p['contact_genders']).toSet();
                    cur.contains(g.key) ? cur.remove(g.key) : cur.add(g.key);
                    _set('contact_genders', cur.toList());
                  }),
              ]),
              const SizedBox(height: 14),
              SwitchListTile(
                value: asBool(p['show_online'], true),
                onChanged: (v) => _set('show_online', v),
                activeThumbColor: AppColors.gold,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show when I am online', style: TextStyle(color: Colors.white)),
              ),
              SwitchListTile(
                value: asBool(p['show_last_seen'], true),
                onChanged: (v) => _set('show_last_seen', v),
                activeThumbColor: AppColors.gold,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show when I was last active', style: TextStyle(color: Colors.white)),
              ),
              SwitchListTile(
                value: asBool(p['show_distance'], true),
                onChanged: (v) => _set('show_distance', v),
                activeThumbColor: AppColors.gold,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show my distance', style: TextStyle(color: Colors.white)),
              ),
            ]),
    );
  }
}
