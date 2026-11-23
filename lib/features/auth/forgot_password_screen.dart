import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/api_config.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';

/// Sends the reset link. The link opens the website's reset page, which is
/// where the new password is set; the member then signs in here.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showToast(context, 'Enter the email you signed up with.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email, redirectTo: '${ApiConfig.webUrl}/auth/callback?next=%2Freset');
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } catch (_) {
      if (mounted) showToast(context, 'Could not send the link. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _sent
              ? EmptyState(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Check your inbox',
                  body: 'If an account exists for ${_email.text.trim()}, a reset link is on its way. Set a new password from the link, then sign in.',
                  action: 'Back to sign in',
                  onAction: () => Navigator.of(context).pop(),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Reset your password',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('We will email you a link to choose a new one.', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'you@example.com', hintStyle: TextStyle(color: Colors.white30)),
                    onSubmitted: (_) => _send(),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Send reset link', loading: _busy, onPressed: _send),
                ]),
        ),
      ),
    );
  }
}
