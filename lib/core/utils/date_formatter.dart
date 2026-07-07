/// Lightweight date/time formatting helpers (no `intl` dependency).
class DateFormatter {
  DateFormatter._();

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// `08:02`
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// `Monday, 7 July`
  static String fullDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

  /// `7 July 2026`
  static String shortDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// `Today`, `Yesterday`, or `Fri, 3 Jul`
  static String dayLabel(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${_weekdays[d.weekday - 1].substring(0, 3)}, '
        '${d.day} ${_months[d.month - 1].substring(0, 3)}';
  }

  /// `7h 58m`
  static String duration(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  /// `Good morning` / `Good afternoon` / `Good evening`
  static String greeting(DateTime d) {
    if (d.hour < 12) return 'Good morning';
    if (d.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
