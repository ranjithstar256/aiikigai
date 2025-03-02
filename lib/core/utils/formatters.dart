import 'package:intl/intl.dart';

/// Utility class for formatting different types of data
class Formatters {
  // Date formatters
  static final DateFormat _dateFormatter = DateFormat('MMM d, y');
  static final DateFormat _timeFormatter = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormatter = DateFormat('MMM d, y • h:mm a');
  static final DateFormat _shortDateFormatter = DateFormat('dd/MM/yy');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM y');
  static final DateFormat _weekdayFormatter = DateFormat('EEEE');
  static final DateFormat _isoFormatter = DateFormat('yyyy-MM-dd');

  // Number formatters
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );
  static final NumberFormat _compactCurrencyFormatter = NumberFormat.compactCurrency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );
  static final NumberFormat _percentFormatter = NumberFormat.percentPattern();
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.##');
  static final NumberFormat _integerFormatter = NumberFormat('#,##0');

  // Format date to string (e.g., "Jan 1, 2023")
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  // Format time to string (e.g., "2:30 PM")
  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  // Format date and time to string (e.g., "Jan 1, 2023 • 2:30 PM")
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  // Format date to short format (e.g., "01/01/23")
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  // Format date to month and year (e.g., "January 2023")
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  // Format date to weekday (e.g., "Monday")
  static String formatWeekday(DateTime date) {
    return _weekdayFormatter.format(date);
  }

  // Format date to ISO format (e.g., "2023-01-01")
  static String formatIsoDate(DateTime date) {
    return _isoFormatter.format(date);
  }

  // Format currency (e.g., "₹1,234.56")
  static String formatCurrency(num amount) {
    return _currencyFormatter.format(amount);
  }

  // Format compact currency (e.g., "₹1.2K")
  static String formatCompactCurrency(num amount) {
    return _compactCurrencyFormatter.format(amount);
  }

  // Format percentage (e.g., "12.34%")
  static String formatPercentage(num value) {
    return _percentFormatter.format(value / 100);
  }

  // Format decimal (e.g., "1,234.56")
  static String formatDecimal(num value) {
    return _decimalFormatter.format(value);
  }

  // Format integer (e.g., "1,234")
  static String formatInteger(num value) {
    return _integerFormatter.format(value);
  }

  // Format file size (e.g., "1.2 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Format duration (e.g., "1h 30m")
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      final seconds = duration.inSeconds % 60;
      return '${duration.inMinutes}m${seconds > 0 ? ' ${seconds}s' : ''}';
    } else if (duration.inHours < 24) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours}h${minutes > 0 ? ' ${minutes}m' : ''}';
    } else {
      final hours = duration.inHours % 24;
      return '${duration.inDays}d${hours > 0 ? ' ${hours}h' : ''}';
    }
  }

  // Format time ago (e.g., "2 hours ago")
  static String formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  // Format name to initials (e.g., "John Doe" -> "JD")
  static String formatNameToInitials(String name) {
    if (name.isEmpty) {
      return '';
    }

    final nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return nameParts[0][0].toUpperCase() + nameParts.last[0].toUpperCase();
  }

  // Format string to capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) {
      return '';
    }

    return text.split(' ')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : '')
        .join(' ');
  }

  // Format phone number (e.g., "+91 98765 43210")
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return '';
    }

    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      // Format as: 98765 43210
      return '${digits.substring(0, 5)} ${digits.substring(5)}';
    } else if (digits.length > 10) {
      // Format with country code
      final countryCode = digits.substring(0, digits.length - 10);
      final number = digits.substring(digits.length - 10);
      return '+$countryCode ${number.substring(0, 5)} ${number.substring(5)}';
    }

    // Return original if can't format
    return phoneNumber;
  }

  // Format email to mask middle part (e.g., "jo***@gmail.com")
  static String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) {
      return email;
    }

    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return email;
    }

    final visible = username.substring(0, 2);
    final masked = '*' * (username.length - 2);

    return '$visible$masked@$domain';
  }
}