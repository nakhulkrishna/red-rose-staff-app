import 'package:flutter/material.dart';
import 'package:staff_app/core/config/app_constants.dart';
import 'package:staff_app/core/theme/app_theme.dart';
import 'package:staff_app/features/auth/presentation/pages/auth_gate_page.dart';

class StaffApp extends StatelessWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      theme: AppTheme.light,
      home: const AuthGatePage(),
    );
  }
}
