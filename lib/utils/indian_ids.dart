import 'package:flutter/services.dart';

/// The formats of the Indian IDs a seller types in: what each one looks
/// like, and a formatter that keeps the box to that shape while typing
/// (upper case, the right characters, the right length).
///
/// Every check takes the text as typed; an empty optional field is the
/// caller's business, so these only say whether a non-empty value is
/// well-formed.
class IndianIds {
  const IndianIds._();

  /// PAN: five letters, four digits, one letter (ABCDE1234F).
  static final pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  /// GSTIN: state code, the PAN, entity number, Z, check character.
  static final gst =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  /// IFSC: four letters, a zero, six letters or digits (SBIN0001234).
  static final ifsc = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  /// UPI ID: a handle, @, the bank's name (name@okaxis).
  static final upi = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

  /// A bank account number: 9 to 18 digits.
  static final bankAccount = RegExp(r'^[0-9]{9,18}$');

  /// FSSAI licence number: 14 digits.
  static final fssai = RegExp(r'^[0-9]{14}$');

  /// A PIN code: six digits, not starting with 0.
  static final pincode = RegExp(r'^[1-9][0-9]{5}$');

  static bool isPan(String v) => pan.hasMatch(v.trim());
  static bool isGst(String v) => gst.hasMatch(v.trim());
  static bool isIfsc(String v) => ifsc.hasMatch(v.trim());
  static bool isUpi(String v) => upi.hasMatch(v.trim());
  static bool isBankAccount(String v) => bankAccount.hasMatch(v.trim());
  static bool isFssai(String v) => fssai.hasMatch(v.trim());
  static bool isPincode(String v) => pincode.hasMatch(v.trim());

  /// Letters and digits only, in capitals, at most [length].
  static List<TextInputFormatter> upperCode(int length) => [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        _UpperCase(),
        LengthLimitingTextInputFormatter(length),
      ];

  /// Digits only, at most [length].
  static List<TextInputFormatter> digits(int length) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(length),
      ];

  /// A UPI ID: no spaces.
  static List<TextInputFormatter> get upiFormatters => [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        LengthLimitingTextInputFormatter(80),
      ];
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
