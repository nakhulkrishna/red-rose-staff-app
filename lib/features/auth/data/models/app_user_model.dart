import 'package:staff_app/features/auth/domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.region,
    required super.phone,
    super.approvalStatus,
    super.isActive,
  });
}
