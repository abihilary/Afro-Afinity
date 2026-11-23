import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../content/profile_content.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/api_errors.dart';
import '../../../core/widgets/common.dart';
import '../../../models/me.dart';
import '../widgets/voice_prompt.dart';
import 'form_bits.dart';

/// Up to three prompt answers, plus the optional voice prompt.
class PromptsForm extends ConsumerStatefulWidget {
  const PromptsForm({super.key, required this.submitLabel, required this.onSaved, this.onboardingStep});
  final String submitLabel;
  final ValueChanged<Me> onSaved;
  final int? onboardingStep;
  @override
  ConsumerState<PromptsForm> createState() => _PromptsFormState();
}

class _PromptsFormState extends ConsumerState<PromptsForm> {
  late final Me _me = ref.read(meProvider).requireValue!;
  late final List<String?> _q = List.generate(3, (i) => i < _me.prompts.length ? _me.prompts[i].q : null);
  late final List<TextEditingController> _a =
      List.generate(3, (i) => TextEditingController(text: i < _me.prompts.length ? _me.prompts[i].a : ''));
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _a) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(int i) async {
    final list = promptsFor(ref.read(localeProvider));
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 12), children: [
          for (final q in list)
            if (!_q.contains(q) || _q[i] == q)
              ListTile(title: Text(q, style: const TextStyle(color: Colors.white)), onTap: () => Navigator.pop(ctx, q)),
        ]),
      ),
    );
    if (picked != null) setState(() => _q[i] = picked);
  }

  Future<void> _submit() async {
    final filled = [
      for (var i = 0; i < 3; i++)
        if (_q[i] != null && _a[i].text.trim().isNotEmpty) {'q': _q[i], 'a': _a[i].text.trim()},
    ];
    setState(() => _busy = true);
    try {
      final me = await ref.read(meProvider.notifier).patch({
        'prompts': filled,
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < 3; i++) ...[
        const SizedBox(height: 14),
        SectionCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
              onTap: () => _pick(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(
                    child: Text(_q[i] ?? 'Choose a prompt',
                        style: TextStyle(color: _q[i] == null ? AppColors.gold : Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.expand_more_rounded, color: Colors.white38),
                ]),
              ),
            ),
            if (_q[i] != null)
              TextField(
                controller: _a[i],
                style: fieldText,
                maxLength: 280,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Your answer',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
          ]),
        ),
      ],
      const FieldLabel('Voice prompt', trailing: 'Optional'),
      const VoicePrompt(),
      const SizedBox(height: 28),
      PrimaryButton(label: widget.submitLabel, loading: _busy, onPressed: _submit),
    ]);
  }
}
