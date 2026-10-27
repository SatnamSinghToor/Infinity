import 'package:duggu/utils/indian_ids.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seller's business details are checked against these formats before
/// they are saved; a real ID must pass and a typo must not.
void main() {
  test('PAN', () {
    expect(IndianIds.isPan('ABCDE1234F'), isTrue);
    expect(IndianIds.isPan('HZHZH'), isFalse);
    expect(IndianIds.isPan('abcde1234f'), isFalse);
  });

  test('GSTIN', () {
    expect(IndianIds.isGst('22ABCDE1234F1Z5'), isTrue);
    expect(IndianIds.isGst('HZHHZ'), isFalse);
  });

  test('IFSC', () {
    expect(IndianIds.isIfsc('SBIN0001234'), isTrue);
    expect(IndianIds.isIfsc('HDFC0ABC123'), isTrue);
    expect(IndianIds.isIfsc('HZBJZJ'), isFalse);
    expect(IndianIds.isIfsc('SBIN1001234'), isFalse, reason: '5th is a zero');
  });

  test('UPI', () {
    expect(IndianIds.isUpi('name@okaxis'), isTrue);
    expect(IndianIds.isUpi('98765.43210@ybl'), isTrue);
    expect(IndianIds.isUpi('h hjxjx'), isFalse);
  });

  test('bank account, FSSAI and PIN code', () {
    expect(IndianIds.isBankAccount('989679878940'), isTrue);
    expect(IndianIds.isBankAccount('989679,87894'), isFalse);
    expect(IndianIds.isFssai('12345678901234'), isTrue);
    expect(IndianIds.isFssai('hxhhx'), isFalse);
    expect(IndianIds.isPincode('125120'), isTrue);
    expect(IndianIds.isPincode('012345'), isFalse);
  });

  test('the code formatter keeps capitals, letters and digits, and length', () {
    var value = const TextEditingValue(text: 'abc de-1234fXYZ');
    for (final f in IndianIds.upperCode(10)) {
      value = f.formatEditUpdate(const TextEditingValue(), value);
    }
    expect(value.text, 'ABCDE1234F');
  });
}
