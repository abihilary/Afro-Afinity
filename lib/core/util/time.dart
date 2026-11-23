import 'package:intl/intl.dart';

/// "now", "5m", "3h", "Tue", "12 Mar" — for lists.
String shortAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  if (d.inDays < 7) return DateFormat.E().format(t);
  return DateFormat('d MMM').format(t);
}

String clockTime(DateTime t) => DateFormat.Hm().format(t);

String dayLabel(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat.EEEE().format(t);
  return DateFormat('d MMMM y').format(t);
}

String longDate(DateTime? t) => t == null ? '' : DateFormat('d MMM y').format(t);
