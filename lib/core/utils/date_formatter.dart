import 'package:intl/intl.dart';

/// Utility class thống nhất format ngày tháng trên toàn ứng dụng
class DateFormatter {
  static final DateFormat _fullDateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateOnly = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeOnly = DateFormat('HH:mm');

  static final List<String> _months = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
    'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
    'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

  /// Ví dụ: 20/05/2026 14:30
  static String fullDateTime(DateTime date) => _fullDateTime.format(date);

  /// Ví dụ: 20/05/2026
  static String dateOnly(DateTime date) => _dateOnly.format(date);

  /// Ví dụ: 14:30
  static String timeOnly(DateTime date) => _timeOnly.format(date);

  /// Ví dụ: 20 Tháng 5 2026
  static String dateVietnamese(DateTime date) {
    return "${date.day} ${_months[date.month - 1]} ${date.year}";
  }

  /// Ví dụ: "20/5/2026" (format ngắn không pad zero)
  static String dateShort(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  /// Parse chuỗi ISO 8601 an toàn
  static DateTime? tryParse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Cắt chuỗi datetime thành "dd/MM/yyyy HH:mm" an toàn
  static String formatIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "N/A";
    final date = DateTime.tryParse(isoString);
    if (date == null) return isoString;
    return fullDateTime(date);
  }
}
