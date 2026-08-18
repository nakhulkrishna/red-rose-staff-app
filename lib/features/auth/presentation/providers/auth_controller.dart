import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:staff_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:staff_app/features/auth/domain/entities/app_user.dart';
import 'package:staff_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:staff_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  return ref.read(getCurrentUserUseCaseProvider).call();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

final authActionControllerProvider =
    StateNotifierProvider<AuthActionController, AsyncValue<void>>((ref) {
      return AuthActionController(ref.read(authRepositoryProvider));
    });

enum AuthAction { none, signIn, signUp, passwordReset }

class AuthActionController extends StateNotifier<AsyncValue<void>> {
  AuthActionController(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  AuthAction lastAction = AuthAction.none;

  Future<void> signIn({required String email, required String password}) async {
    lastAction = AuthAction.signIn;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async =>
          _repository.signIn(email: email, password: password).then((_) {}),
    );
  }

  Future<void> sendPasswordReset({required String email}) async {
    lastAction = AuthAction.passwordReset;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.sendPasswordResetEmail(email: email),
    );
  }

  Future<void> signUp({
    required String name,
    required String region,
    required String phone,
    required String email,
    required String password,
  }) async {
    lastAction = AuthAction.signUp;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => _repository
          .signUp(
            name: name,
            region: region,
            phone: phone,
            email: email,
            password: password,
          )
          .then((_) {}),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.signOut);
  }
}

final authErrorMessageProvider = Provider<String?>((ref) {
  final state = ref.watch(authActionControllerProvider);
  return state.maybeWhen(
    error: (error, _) => _friendlyError(error),
    orElse: () => null,
  );
});

String _friendlyError(Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Firestore permission denied. Please check security rules for this user.';
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'user-banned':
        return error.message ?? 'Temporarily banned.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
  return error.toString();
}
