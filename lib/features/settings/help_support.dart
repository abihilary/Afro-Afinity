import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/util/links.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';
import '../profile/forms/form_bits.dart';

/// Contact form (`POST /contact`) plus the support channels from `/config`.
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final me = ref.read(meProvider).valueOrNull;
    if (_body.text.trim().length < 10) {
      showToast(context, 'Tell us a little more (at least 10 characters).', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/contact', data: {
        'name': me?.displayName ?? me?.username ?? 'Member',
        'email': supabase.auth.currentUser?.email ?? '',
        if (_subject.text.trim().isNotEmpty) 'subject': _subject.text.trim(),
        'body': _body.text.trim(),
        'locale': me?.locale ?? 'en',
      });
      if (!mounted) return;
      _subject.clear();
      _body.clear();
      showToast(context, 'Message sent. We reply by email.');
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(configProvider).valueOrNull ?? const {};
    final email = asString(cfg['support.email']) ?? 'support@afroaffinity.com';
    final whatsapp = asString(cfg['support.whatsapp']) ?? '';
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, foregroundColor: Colors.white, title: const Text('Help & contact')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
        SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(children: [
            ActionRow(icon: Icons.mail_outline_rounded, label: 'Email us', subtitle: email, onTap: () => openUrl('mailto:$email')),
            if (whatsapp.isNotEmpty)
              ActionRow(icon: Icons.chat_outlined, label: 'WhatsApp', subtitle: whatsapp, onTap: () => openUrl('https://wa.me/${whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}')),
            ActionRow(icon: Icons.shield_outlined, label: 'Staying safe', onTap: () => openWeb('/safety')),
          ]),
        ),
        const FieldLabel('Send us a message'),
        TextField(controller: _subject, maxLength: 140, style: fieldText, decoration: fieldDecoration('Subject (optional)')),
        const SizedBox(height: 8),
        TextField(controller: _body, maxLength: 2000, maxLines: 6, style: fieldText, decoration: fieldDecoration('How can we help?')),
        const SizedBox(height: 14),
        PrimaryButton(label: 'Send', loading: _busy, onPressed: _send),
      ]),
    );
  }
}
