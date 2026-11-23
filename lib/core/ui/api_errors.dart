import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../api/api_client.dart';
import '../widgets/app_toast.dart';

/// Plain words for the codes a member can trip. Anything not listed falls
/// back to the server's message.
const _messages = <String, String>{
  'verification_required': 'Verify your identity to do that.',
  'account_restricted': 'Your account is restricted. You can look around, but not act.',
  'plus_required': 'That is a premium feature.',
  'upgrade_required': 'That needs a higher plan.',
  'insufficient_coins': 'Not enough coins.',
  'rate_limited': 'You are going a bit fast. Try again in a moment.',
  'blocked': 'This conversation is closed.',
  'not_accepting_messages': 'This member is not accepting messages right now.',
  'friend_requests_off': 'This member is not accepting friend requests.',
  'already_friends': 'You are already friends.',
  'recipient_unavailable': 'That member is no longer available.',
  'wink_limit': 'You have used today\'s winks.',
  'username_taken': 'That username is taken.',
  'underage': 'You must be at least 18.',
  'photo_limit_reached': 'You can have up to 6 photos.',
  'album_limit_reached': 'You have reached the album limit.',
  'album_full': 'That album is full.',
  'promo_invalid': 'That code is not valid.',
  'promo_expired': 'That code has expired.',
  'promo_exhausted': 'That code has been used up.',
  'transfers_not_allowed': 'Coin transfers are switched off.',
  'transfer_limit': 'You have reached today\'s transfer limit.',
  'below_minimum': 'That is below the minimum.',
  'exceeds_earnings': 'You can only cash out coins you earned.',
  'plan_downgrade_blocked': 'You are already on a higher plan.',
  'already_verified': 'You are already verified.',
  'saved_search_limit': 'You have saved the maximum number of searches.',
  'message_quota_reached': 'You have used your free messages in this chat.',
};

String errorText(Object e) {
  if (e is NetworkException) return 'You are offline. Check your connection and try again.';
  if (e is ApiException) {
    if (e.code == 'daily_limit') {
      final cap = e.details['cap'];
      return cap == null ? 'You have used today\'s likes.' : 'You have used today\'s $cap likes.';
    }
    if (e.code == 'invalid_body' && e.fieldErrors.isNotEmpty) {
      final f = e.fieldErrors.entries.first;
      return '${f.key.replaceAll('_', ' ')}: ${f.value.isEmpty ? 'invalid' : f.value.first}';
    }
    if (e.code == 'incomplete') {
      final missing = (e.details['missing'] as List?)?.join(', ');
      return missing == null ? 'Some required fields are missing.' : 'Still missing: $missing';
    }
    return _messages[e.code] ?? e.message;
  }
  return 'Something went wrong.';
}

/// The one place a failed call turns into something the member can act on.
/// Returns true when it routed somewhere (so the caller need not also toast).
bool handleApiError(BuildContext context, Object e) {
  if (!context.mounted) return false;
  final code = e is ApiException ? e.code : null;
  switch (code) {
    case 'verification_required':
      showToast(context, errorText(e),
          action: SnackBarAction(textColor: AppColors.gold, label: 'Verify', onPressed: () => context.push('/verification')));
      return true;
    case 'plus_required':
    case 'upgrade_required':
    case 'daily_limit':
      showToast(context, errorText(e),
          action: SnackBarAction(textColor: AppColors.gold, label: 'Upgrade', onPressed: () => context.push('/premium')));
      return true;
    case 'insufficient_coins':
    case 'message_quota_reached':
      showToast(context, errorText(e),
          action: SnackBarAction(textColor: AppColors.gold, label: 'Top up', onPressed: () => context.push('/wallet')));
      return true;
    case 'account_restricted':
      context.go('/suspended');
      return true;
  }
  showToast(context, errorText(e), error: true);
  return false;
}
