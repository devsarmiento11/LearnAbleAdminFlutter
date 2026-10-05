import 'package:cloud_firestore/cloud_firestore.dart';

/// Legacy Unity results have a completion date but no explicit school year.
String legacyActivitySchoolYear(dynamic value, {int startMonth = 6}) {
  final DateTime? date = value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : DateTime.tryParse(value?.toString() ?? '');
  if (date == null || date.year < 2000) return '';
  // Use Philippine time consistently, regardless of the browser timezone.
  final local = date.toUtc().add(const Duration(hours: 8));
  final start = local.month >= startMonth ? local.year : local.year - 1;
  return '$start-${start + 1}';
}
