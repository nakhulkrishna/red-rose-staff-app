import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/presentation/pages/login_page.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/navigation/presentation/pages/main_shell_page.dart';
import 'package:staff_app/shared/pages/force_update_page.dart';
import 'package:staff_app/shared/providers/app_update_provider.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force-update gate: takes priority over everything else. Fails open
    // when the config is unreadable so a Firestore issue cannot lock the app.
    final updateStatus =
        ref.watch(appUpdateStatusProvider).valueOrNull ?? AppUpdateStatus.none;
    if (updateStatus.updateRequired) {
      return ForceUpdatePage(status: updateStatus);
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginPage();
        return const MainShellPage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Authentication failed: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
