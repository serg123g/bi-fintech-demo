import 'package:fintech_platform/features/auth/presentation/widgets/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email', () {
    expect(AuthValidators.email(''), isNotNull);
    expect(AuthValidators.email('ana@'), isNotNull);
    expect(AuthValidators.email(' ana@test.com '), isNull);
  });

  test('password exige mínimo 8 caracteres', () {
    expect(AuthValidators.password('1234567'), isNotNull);
    expect(AuthValidators.password('12345678'), isNull);
  });

  test('nombre', () {
    expect(AuthValidators.fullName(' '), isNotNull);
    expect(AuthValidators.fullName('Ana Torres'), isNull);
  });
}
