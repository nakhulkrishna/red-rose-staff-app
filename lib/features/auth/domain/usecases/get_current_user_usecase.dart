import 'package:staff_app/features/auth/domain/entities/app_user.dart';
import 'package:staff_app/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<AppUser?> call() {
    return _repository.getCurrentUser();
  }
}
