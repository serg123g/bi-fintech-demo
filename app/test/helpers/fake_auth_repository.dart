import 'dart:async';

import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/auth/domain/entities/app_user.dart';
import 'package:fintech_platform/features/auth/domain/entities/customer_segment.dart';
import 'package:fintech_platform/features/auth/domain/repositories/auth_repository.dart';

const testUser = AppUser(
  id: 'u-joven',
  email: 'joven@test.com',
  fullName: 'Ana Torres',
  segment: CustomerSegment.joven,
);

/// Repositorio en memoria, determinista. Usado por widget tests y el E2E.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser, this.password = 'Test1234!'})
      : _user = initialUser;

  final String password;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim() != testUser.email || password != this.password) {
      throw AuthFailure.fromReason(AuthFailureReason.invalidCredentials);
    }
    _user = testUser;
    _controller.add(_user);
    return testUser;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required CustomerSegment segment,
  }) async {
    final user = AppUser(
      id: 'u-new',
      email: email,
      fullName: fullName,
      segment: segment,
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
