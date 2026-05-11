class DateFormatter {
  static String formatDateTime(int? millis) {
    return _format(millis, _dateTimePattern);
  }

  static String formatDate(int? millis) {
    return _format(millis, _datePattern);
  }

  static String formatTime(int? millis) {
    return _format(millis, _timePattern);
  }

  static const String _dateTimePattern = 'dd/MM/yyyy HH:mm';
  static const String _datePattern = 'dd/MM/yyyy';
  static const String _timePattern = 'HH:mm';

  static String _format(int? millis, String pattern) {
    if (millis == null || millis < 0) {
      return 'Invalid timestamp';
    }

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      switch (pattern) {
        case _dateTimePattern:
          return '$day/$month/$year $hour:$minute';
        case _datePattern:
          return '$day/$month/$year';
        case _timePattern:
          return '$hour:$minute';
        default:
          return 'Invalid timestamp';
      }
    } catch (_) {
      return 'Invalid timestamp';
    }
  }
}
