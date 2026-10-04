import 'package:intl/intl.dart';

class DateFormatter {
  static const String _defaultFormat = 'dd MMMM yyyy';
  static const String _dateTimeFormat = 'dd MMMM yyyy, HH:mm';

  static String format(DateTime? date, {String? format}) {
    if (date == null) return '-';
    return DateFormat(format ?? _defaultFormat, 'id_ID').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat(_dateTimeFormat, 'id_ID').format(date);
  }

  /// "Hari ini" / "Kemarin" / tanggal biasa
  static String relative(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff hari lalu';
    return format(date);
  }

  static String dayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Kemarin';
    return format(date);
  }

  static String timestampToId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
