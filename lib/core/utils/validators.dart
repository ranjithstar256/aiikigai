/// Utility class for form field validation
class Validators {
  // Email validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Regular expression for email validation
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // Password validator
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // Simple password validator (less strict)
  static String? validateSimplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Password confirmation validator
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validator
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Phone number validator
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 10) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  // Indian phone number validator
  static String? validateIndianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Check if the number starts with valid Indian prefixes
    if (digits.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(digits)) {
        return 'Enter a valid Indian mobile number';
      }
    } else if (digits.length == 11 && digits.startsWith('0')) {
      if (!RegExp(r'^0[6-9]').hasMatch(digits)) {
        return 'Enter a valid Indian mobile number';
      }
    } else if (digits.length == 12 && digits.startsWith('91')) {
      if (!RegExp(r'^91[6-9]').hasMatch(digits)) {
        return 'Enter a valid Indian mobile number';
      }
    } else if (digits.length == 13 && digits.startsWith('+91')) {
      if (!RegExp(r'^+91[6-9]').hasMatch(digits)) {
        return 'Enter a valid Indian mobile number';
      }
    } else {
      return 'Enter a valid Indian mobile number';
    }

    return null;
  }

  // Required field validator
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    return null;
  }

  // Min length validator
  static String? validateMinLength(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }

    return null;
  }

  // Max length validator
  static String? validateMaxLength(String? value, int maxLength, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Not required
    }

    if (value.length > maxLength) {
      return '${fieldName ?? 'This field'} must be at most $maxLength characters';
    }

    return null;
  }

  // URL validator
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Not required
    }

    // Regular expression for URL validation
    final urlRegExp = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );

    if (!urlRegExp.hasMatch(value)) {
      return 'Enter a valid URL';
    }

    return null;
  }

  // Numeric validator
  static String? validateNumeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Not required
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '${fieldName ?? 'This field'} must contain only numbers';
    }

    return null;
  }

  // Decimal validator
  static String? validateDecimal(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Not required
    }

    if (!RegExp(r'^\d*\.?\d+$').hasMatch(value)) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }

    return null;
  }

  // Alphabetic validator
  static String? validateAlphabetic(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Not required
    }

    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return '${fieldName ?? 'This field'} must contain only letters';
    }

    return null;
  }

  // Alphanumeric validator
  static String? validateAlphanumeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Not required
    }

    if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
      return '${fieldName ?? 'This field'} must contain only letters and numbers';
    }

    return null;
  }

  // Validation for ikigai answers (minimum length requirement)
  static String? validateIkigaiAnswer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please provide an answer';
    }

    if (value.length < 10) {
      return 'Please provide a more detailed answer (at least 10 characters)';
    }

    return null;
  }

  // Validate that a text doesn't contain profanity or inappropriate content
  static String? validateAppropriateContent(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Not required
    }

    // Basic inappropriate words list (expand as needed)
    final inappropriateWords = [
      'profanity1',
      'profanity2',
      // Add more inappropriate words here
    ];

    final lowercaseValue = value.toLowerCase();

    for (final word in inappropriateWords) {
      if (lowercaseValue.contains(word)) {
        return 'Please remove inappropriate content';
      }
    }

    return null;
  }
}