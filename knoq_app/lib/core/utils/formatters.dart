import 'package:intl/intl.dart';

class Formatters {
  static String formatPercentage(double value) {
    return '${value.clamp(0.0, 100.0).round()}%';
  }

  static String formatPower(int value) {
    return '${value.clamp(0, 100)}';
  }

  static String formatSwingSpeed(double value) {
    return '${value.toStringAsFixed(1)} °/s';
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${twoDigitMinutes}m ${twoDigitSeconds}s';
    }
    return '${duration.inMinutes}m ${twoDigitSeconds}s';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, h:mm a').format(date);
  }

  static String formatTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 8) return formatDate(date);
    if (difference.inDays > 1) return '${difference.inDays} days ago';
    if (difference.inDays == 1) return '1 day ago';
    if (difference.inHours > 1) return '${difference.inHours} hours ago';
    if (difference.inHours == 1) return '1 hour ago';
    if (difference.inMinutes > 1) return '${difference.inMinutes} minutes ago';
    if (difference.inMinutes == 1) return '1 minute ago';
    return 'Just now';
  }
}
