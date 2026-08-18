import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

final _staffProfileProvider = StreamProvider<Map<String, dynamic>>((
  ref,
) async* {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield const {};
    return;
  }

  final firestore = ref.read(firestoreProvider);
  final staff = firestore.collection('catalog_staff_salesmen');

  if (user.email.isNotEmpty) {
    final byEmail = await staff
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (byEmail.docs.isNotEmpty) {
      yield byEmail.docs.first.data();
      return;
    }
  }

  final byDoc = await staff.doc(user.uid).get();
  if (byDoc.exists) {
    yield byDoc.data() ?? const {};
    return;
  }

  yield const {};
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final staff = ref.watch(_staffProfileProvider).valueOrNull ?? const {};

    String field(String key, String fallback) {
      final value = (staff[key] as String?)?.trim() ?? '';
      return value.isNotEmpty ? value : fallback;
    }

    final name = field('name', auth?.name.isNotEmpty == true ? auth!.name : 'Salesman');
    final role = field('role', 'Salesman');
    final region = field('region', auth?.region ?? '-');
    final phone = field('phone', auth?.phone ?? '-');
    final email = auth?.email ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('Settings')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_staffProfileProvider);
          await ref.read(_staffProfileProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Card(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                children: [
                  _InfoRow(label: 'Email', value: email),
                  _InfoRow(label: 'Phone', value: phone),
                  _InfoRow(label: 'Region', value: region),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: const Text('Reset Password'),
                    subtitle: const Text('Send a reset link to your email'),
                    onTap: () => _sendPasswordReset(context, email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFB91C1C)),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Color(0xFFB91C1C)),
                    ),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'RED ROSE SALESMAN APP v2.1.8',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty || email == '-') {
      messenger.showSnackBar(
        const SnackBar(content: Text('No email on this account.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send reset link: $e')),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Clear order state so the next account on this device does not
      // inherit the previous user's cart or customer.
      ref.read(cartProvider.notifier).clear();
      ref.read(selectedCustomerProvider.notifier).state = null;
      await ref.read(authActionControllerProvider.notifier).signOut();
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: child,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
