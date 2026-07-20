import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns error if email is empty', () {
        expect(Validators.validateEmail(''), 'Email is required');
        expect(Validators.validateEmail(null), 'Email is required');
      });

      test('returns error if email is invalid', () {
        expect(Validators.validateEmail('invalidemail'), 'Enter a valid email address');
        expect(Validators.validateEmail('invalid@.com'), 'Enter a valid email address');
        expect(Validators.validateEmail('invalid@com'), 'Enter a valid email address');
      });

      test('returns null if email is valid', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user.name@domain.co.uk'), isNull);
      });
    });

    group('validatePassword', () {
      test('returns error if password is empty', () {
        expect(Validators.validatePassword(''), 'Password is required');
        expect(Validators.validatePassword(null), 'Password is required');
      });

      test('returns error if password is less than 8 characters', () {
        expect(Validators.validatePassword('Short1!'), 'Password must be at least 8 characters');
      });

      test('returns error if password has no uppercase letter', () {
        expect(Validators.validatePassword('nouppercase1!'), 'Password must contain at least 1 uppercase letter');
      });

      test('returns error if password has no number', () {
        expect(Validators.validatePassword('NoNumberHere!'), 'Password must contain at least 1 number');
      });

      test('returns null if password is valid', () {
        expect(Validators.validatePassword('ValidPass123!'), isNull);
      });
    });

    group('validateName', () {
      test('returns error if name is empty', () {
        expect(Validators.validateName(''), 'Name is required');
        expect(Validators.validateName(null), 'Name is required');
      });

      test('returns error if name is less than 2 characters', () {
        expect(Validators.validateName('A'), 'Name must be at least 2 characters');
      });

      test('returns null if name is valid', () {
        expect(Validators.validateName('John Doe'), isNull);
        expect(Validators.validateName('Jo'), isNull);
      });
    });

    group('validateAcademyCode', () {
      test('returns error if code is empty', () {
        expect(Validators.validateAcademyCode(''), 'Academy code is required');
        expect(Validators.validateAcademyCode(null), 'Academy code is required');
      });

      test('returns error if code is not exactly 6 characters', () {
        expect(Validators.validateAcademyCode('12345'), 'Code must be exactly 6 characters');
        expect(Validators.validateAcademyCode('1234567'), 'Code must be exactly 6 characters');
      });

      test('returns error if code is not alphanumeric', () {
        expect(Validators.validateAcademyCode('1234-6'), 'Code must be alphanumeric');
        expect(Validators.validateAcademyCode('1234_6'), 'Code must be alphanumeric');
      });

      test('returns null if code is valid', () {
        expect(Validators.validateAcademyCode('A1B2C3'), isNull);
        expect(Validators.validateAcademyCode('123456'), isNull);
        expect(Validators.validateAcademyCode('ABCDEF'), isNull);
      });
    });
  });
}
