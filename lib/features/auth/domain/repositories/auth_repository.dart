import 'package:staff_app/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Stream<AppUser?> authStateChanges();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String name,
    required String region,
    required String phone,
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
}
