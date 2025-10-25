// Simple phone validation test without Flutter dependencies
String? validatePhoneOptional(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final trimmed = value.trim();

  // Check for invalid characters - only allow digits, spaces, +, -, (, )
  if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(trimmed)) {
    return 'Phone validation failed - contains invalid characters';
  }

  final cleaned = trimmed.replaceAll(RegExp(r'\D'), '');
  if (cleaned.length < 7 || cleaned.length > 25) {
    return 'Phone validation failed - length ${cleaned.length} not between 7-25 digits';
  }
  // Allow international numbers that may start with 0 (like Moroccan numbers: 0612345678)
  // Only reject if the number is suspiciously short and starts with 0
  if (cleaned.length < 7 && cleaned.startsWith('0')) {
    return 'Phone validation failed - suspiciously short number starting with 0';
  }
  return null;
}

void main() {
  // Test cases for phone validation
  final testCases = [
    // Valid cases
    ('+212 6 41 17 00 12', true, 'Moroccan phone with correct formatting'),
    ('+212 64 11 70 01', true, 'Moroccan phone with formatting'),
    ('+21264117001', true, 'Moroccan phone without formatting'),
    ('064117001', true, 'Moroccan phone starting with 0'),
    ('+1 555 123 4567', true, 'US phone number'),
    ('+44 20 7123 4567', true, 'UK phone number'),
    ('123456789', true, '9-digit number'),

    // Invalid cases
    ('12345678', false, '8-digit number (too short)'),
    ('', false, 'Empty string'),
    ('abc1234567', false, 'Contains letters'),
    ('+212 64 11 70 01 extra', false, 'Too long with formatting'),
    ('+212 64 11 70 01', false, 'Current wrong number that should be rejected'),
  ];

  print('Testing phone validation...');
  print('=' * 50);

  for (final testCase in testCases) {
    final phone = testCase.$1;
    final expected = testCase.$2;
    final description = testCase.$3;

    final result = validatePhoneOptional(phone);
    final isValid = result == null;
    final status = isValid == expected ? '✅ PASS' : '❌ FAIL';

    print('$status: "$phone" ($description)');
    if (isValid != expected) {
      print('  Expected: ${expected ? 'valid' : 'invalid'}');
      print('  Got: ${isValid ? 'valid' : 'invalid'}');
      if (result != null) {
        print('  Error: $result');
      }
    }
    print('');
  }

  print('Test completed.');
}