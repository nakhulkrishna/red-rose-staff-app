import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/products/presentation/pages/products_list_page.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';
import 'package:url_launcher/url_launcher.dart';

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

Future<List<String>> _resolveSalesmanIdentifiers({
  required FirebaseFirestore firestore,
  required String uid,
  required String email,
}) async {
  final ids = <String>{uid};
  final staff = firestore.collection('catalog_staff_salesmen');

  final byUid = await staff.where('uid', isEqualTo: uid).limit(1).get();
  for (final doc in byUid.docs) {
    ids.add(doc.id);
    final code = (doc.data()['id'] as String?)?.trim() ?? '';
    if (code.isNotEmpty) ids.add(code);
  }

  if (email.isNotEmpty) {
    final byEmail = await staff.where('email', isEqualTo: email).limit(1).get();
    for (final doc in byEmail.docs) {
      ids.add(doc.id);
      final code = (doc.data()['id'] as String?)?.trim() ?? '';
      if (code.isNotEmpty) ids.add(code);
    }
  }

  final byDoc = await staff.doc(uid).get();
  if (byDoc.exists) {
    ids.add(byDoc.id);
    final code = (byDoc.data()?['id'] as String?)?.trim() ?? '';
    if (code.isNotEmpty) ids.add(code);
  }

  return ids.where((id) => id.trim().isNotEmpty).toList();
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  DateTime _lastRefreshedAt = DateTime.now();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshSettings(silent: true),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshSettings({bool silent = false}) async {
    ref.invalidate(_staffProfileProvider);
    try {
      await ref.read(_staffProfileProvider.future);
      if (!mounted) return;
      setState(() => _lastRefreshedAt = DateTime.now());
      if (!silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings refreshed.')));
      }
    } catch (_) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refresh failed. Please try again.')),
      );
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send reset link: $e')));
    }
  }

  Future<void> _showExportSummary() async {
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth == null) return;

    try {
      final firestore = ref.read(firestoreProvider);
      final salesmanIds = await _resolveSalesmanIdentifiers(
        firestore: firestore,
        uid: auth.uid,
        email: auth.email,
      );

      if (salesmanIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No salesman profile found.')),
        );
        return;
      }

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final snapshot = await firestore
          .collection('catalog_orders')
          .where('salesmanId', whereIn: salesmanIds.take(10).toList())
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .get();

      var total = 0.0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['amountQar'] as num?)?.toDouble() ?? 0;
      }

      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Monthly Summary'),
          content: Text(
            'Orders: ${snapshot.docs.length}\n'
            'Total: QAR ${total.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await ref.read(authActionControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final staff = ref.watch(_staffProfileProvider).valueOrNull ?? const {};

    final name = ((staff['name'] as String?)?.trim().isNotEmpty ?? false)
        ? (staff['name'] as String)
        : (auth?.name ?? 'Salesman');
    final role = (staff['role'] as String?) ?? 'Salesman';
    final region = ((staff['region'] as String?)?.trim().isNotEmpty ?? false)
        ? (staff['region'] as String)
        : (auth?.region ?? '-');
    final phone = ((staff['phone'] as String?)?.trim().isNotEmpty ?? false)
        ? (staff['phone'] as String)
        : (auth?.phone ?? '-');
    final email = auth?.email ?? '';
    final imageUrl = (staff['imageUrl'] as String?) ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshSettings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refreshSettings,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              Text(
                'Last refreshed: ${DateFormat('dd MMM yyyy, hh:mm a').format(_lastRefreshedAt)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              _ProfileCard(
                name: name,
                role: role,
                email: email,
                phone: phone,
                region: region,
                imageUrl: imageUrl,
              ),
              const SizedBox(height: 10),
              _SectionCard(
                title: 'General',
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Products Catalog',
                      subtitle: 'Browse current products and pricing',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductsListPage(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.bar_chart_outlined,
                      title: 'Monthly Sales Summary',
                      subtitle: 'Quick report for this month',
                      onTap: _showExportSummary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                title: 'Account',
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_reset_outlined,
                      title: 'Change Password',
                      subtitle: 'Send reset link to your email',
                      onTap: () => _sendPasswordReset(email),
                    ),
                    _SettingsTile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Logout from this device',
                      onTap: _confirmLogout,
                      danger: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                title: 'Support & Legal',
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'About Us',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutUsPage(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.rule_folder_outlined,
                      title: 'Terms & Conditions',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TermsConditionsPage(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Contact support team',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportPage(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.gavel_outlined,
                      title: 'Legal',
                      subtitle: 'Compliance and legal notice',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LegalPage()),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.mail_outline,
                      title: 'Contact by Email',
                      subtitle: 'sales@redrose.com',
                      onTap: () => _openExternal('mailto:sales@redrose.com'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_outlined),
                      title: const Text('App Version'),
                      subtitle: Text(
                        'RED ROSE SALESMAN APP v2.1.4 (15)\nUpdated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.region,
    required this.imageUrl,
  });

  final String name;
  final String role;
  final String email;
  final String phone;
  final String region;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEFF3F8),
            backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
            child: imageUrl.isEmpty
                ? const Icon(Icons.person_outline, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$role • $region',
                  style: const TextStyle(color: Color(0xFFE2E8F0)),
                ),
                Text(email, style: const TextStyle(color: Color(0xFFCBD5E1))),
                Text(phone, style: const TextStyle(color: Color(0xFFCBD5E1))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB91C1C) : const Color(0xFF111827);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Welcome to Red Rose!\n\n'
          'Our app helps users manage products, orders, and customer information efficiently. '
          'We aim to provide a smooth and reliable experience for everyone who uses our app.\n\n'
          'Our mission is to deliver high-quality service, improve user experience, and ensure data privacy '
          'and security for all users.\n\n'
          'This app is designed for general use and to assist anyone looking to organize and manage sales '
          'or product information effectively.',
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PolicyHeader(title: 'Privacy Policy', lastUpdated: '27 Aug 2025'),
          _PolicySection(
            title: 'Information We Collect',
            body:
                '- Name, email, and contact number.\n- Orders, products, and app usage data.\n- No payment details are collected.',
          ),
          _PolicySection(
            title: 'How We Use Information',
            body:
                '- To provide and improve app features.\n- To communicate updates and provide support.\n- To ensure a secure user experience.',
          ),
          _PolicySection(
            title: 'Account Deletion',
            body:
                'Users can request account deletion. Deletion permanently removes personal data and app history.',
          ),
          _PolicySection(
            title: 'Data Sharing',
            body:
                'We do not sell or rent personal data. Data may be shared only with trusted service providers required for app functionality.',
          ),
          _PolicySection(
            title: 'Data Security',
            body:
                'We use reasonable security measures to protect your data from unauthorized access.',
          ),
          _PolicySection(
            title: 'Contact Us',
            body:
                'Email: jabirkarulai@gmail.com\nWhatsApp: +974 7727 0580 / India: 9946270580',
          ),
        ],
      ),
    );
  }
}

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PolicyHeader(
            title: 'Terms & Conditions',
            lastUpdated: '27 Aug 2025',
          ),
          _PolicySection(
            title: 'Use of App',
            body:
                'This app helps users manage products, orders, and records. Do not use the app for illegal activities.',
          ),
          _PolicySection(
            title: 'Account & Data',
            body:
                'Users are responsible for account credentials. Account deletion permanently removes personal data.',
          ),
          _PolicySection(
            title: 'Orders & Delivery',
            body:
                'This app is primarily for record-keeping and order operations. Delivery handling may happen outside the app.',
          ),
          _PolicySection(
            title: 'Payments',
            body:
                'Payments may be handled externally depending on business process and integration setup.',
          ),
          _PolicySection(
            title: 'Restrictions',
            body:
                'Users may not misuse, redistribute, or reverse-engineer app content and services.',
          ),
          _PolicySection(
            title: 'Disclaimer',
            body:
                'We are not liable for losses caused by credential sharing, negligence, or unauthorized third-party access.',
          ),
        ],
      ),
    );
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PolicySection(
            title: 'Primary Contact',
            body:
                'Nakhul Krishna\nEmail: nakhulkrishna253@gmail.com',
          ),
          const _PolicySection(
            title: 'Need Help?',
            body:
                'For order, catalog, or account issues, contact support and include your salesman ID, app version, and a short issue summary.',
          ),
          _ActionCard(
            icon: Icons.mail_outline,
            title: 'Email Support',
            subtitle: 'sales@redrose.com',
            onTap: () async {
              final uri = Uri.parse('mailto:sales@redrose.com');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          _ActionCard(
            icon: Icons.phone_outlined,
            title: 'Call Support',
            subtitle: '+974 7727 0580',
            onTap: () async {
              final uri = Uri.parse('tel:+97477270580');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          const _PolicySection(
            title: 'Compliance Notice',
            body:
                'Use of this app must comply with local laws, company policy, and customer data handling standards.',
          ),
          const _PolicySection(
            title: 'Data Handling',
            body:
                'Sales and customer data must only be accessed for authorized business operations.',
          ),
          const _PolicySection(
            title: 'Intellectual Property',
            body:
                'All app branding, interfaces, and business logic remain property of Red Rose and partners.',
          ),
        ],
      ),
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader({required this.title, required this.lastUpdated});

  final String title;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Last Updated: $lastUpdated',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new),
        onTap: onTap,
      ),
    );
  }
}
