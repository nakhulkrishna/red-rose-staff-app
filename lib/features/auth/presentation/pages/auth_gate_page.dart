import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/domain/entities/app_user.dart';
import 'package:staff_app/features/auth/presentation/pages/login_page.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/navigation/presentation/pages/main_shell_page.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginPage();
        if (!user.isApprovedActive) {
          return _AccountBlockedPage(user: user);
        }
        return const MainShellPage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error is FirebaseAuthException && error.code == 'user-banned'
                  ? (error.message ?? 'Temporarily banned.')
                  : 'Authentication failed: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountBlockedPage extends ConsumerWidget {
  const _AccountBlockedPage({required this.user});

  final AppUser user;

  String get _message {
    switch (user.approvalStatus.toLowerCase()) {
      case 'pending':
        return 'Your account is pending admin approval.\nPlease wait until an administrator approves your access.';
      case 'rejected':
        return 'Your account request was rejected.\nContact your administrator for more information.';
      case 'deactivated':
        return 'Your account has been deactivated.\nContact your administrator to restore access.';
      default:
        return 'Your account is not active.\nContact your administrator for access.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top, size: 48, color: Color(0xFF6B7280)),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ref.invalidate(authStateProvider),
                child: const Text('Check Again'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authActionControllerProvider.notifier).signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
