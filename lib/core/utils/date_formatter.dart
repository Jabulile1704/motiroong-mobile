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

  /// `Jul 9, 2026`
  static String shortDate(DateTime d) =>
      '${_months[d.month - 1].substring(0, 3)} ${d.day}, ${d.year}';

  /// `9:02 AM`
  static String time12(DateTime d) {
    final int h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// `TUESDAY, JUL 9` — screen eyebrow style.
  static String eyebrowDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1].substring(0, 3)} ${d.day}'
          .toUpperCase();

  /// `Today`, `Yesterday`, or `Mon, Jul 7`
  static String dayLabel(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${_weekdays[d.weekday - 1].substring(0, 3)}, '
        '${_months[d.month - 1].substring(0, 3)} ${d.day}';
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
