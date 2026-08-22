import 'package:staff_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:staff_app/features/auth/domain/entities/app_user.dart';
import 'package:staff_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<AppUser?> getCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges();
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<AppUser> signUp({required String email, required String password}) {
    return _remoteDataSource.signUp(email: email, password: password);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _remoteDataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
