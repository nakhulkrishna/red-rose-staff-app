import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  if (user.email.isNotEmpty) {
    final byEmail = await firestore
        .collection('catalog_staff_salesmen')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (byEmail.docs.isNotEmpty) {
      yield byEmail.docs.first.data();
      return;
    }
  }
  final byDoc = await firestore
      .collection('catalog_staff_salesmen')
      .doc(user.uid)
      .get();
  if (byDoc.exists) {
    yield byDoc.data() ?? const {};
    return;
  }
  yield const {};
});

final _userSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const {});
  }
  final firestore = ref.read(firestoreProvider);
  return firestore.collection('catalog_users').doc(user.uid).snapshots().map((
    doc,
  ) {
    if (!doc.exists) return const {};
    return doc.data() ?? const {};
  });
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
  bool _saving = false;

  Future<void> _patchSettings(Map<String, dynamic> patch) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(firestoreProvider)
          .collection('catalog_users')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'email': user.email,
            'name': user.name,
            'updatedAt': FieldValue.serverTimestamp(),
            ...patch,
          }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
      final csvRows = <String>['Order ID,Date,Customer,Amount QAR,Status'];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = (data['id'] as String?) ?? doc.id;
        final customer = (data['customerName'] as String?) ?? 'Customer';
        final amount = (data['amountQar'] as num?)?.toDouble() ?? 0;
        total += amount;
        final status = (data['paymentStatus'] as String?) ?? 'pending';
        final ts = data['orderDate'];
        final date = ts is Timestamp
            ? DateFormat('dd/MM/yyyy').format(ts.toDate())
            : '-';
        csvRows.add('$id,$date,$customer,${amount.toStringAsFixed(2)},$status');
      }
      final csv = csvRows.join('\n');

      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Report Preview',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text('Orders: ${snapshot.docs.length}'),
                Text('Total: QAR ${total.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: SelectableText(csv),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csv));
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Report copied to clipboard.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy CSV'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final staff = ref.watch(_staffProfileProvider).valueOrNull ?? const {};
    final settings = ref.watch(_userSettingsProvider).valueOrNull ?? const {};

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

    final orderSettings =
        (settings['orderPreferences'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final whatsapp =
        (settings['whatsapp'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final notifications =
        (settings['notifications'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final appPrefs =
        (settings['appPreferences'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final security =
        (settings['security'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final lowStockWarning = (orderSettings['lowStockWarning'] as bool?) ?? true;
    final confirmBeforePlace =
        (orderSettings['confirmBeforePlaceOrder'] as bool?) ?? true;
    final defaultUnit = (orderSettings['defaultUnit'] as String?) ?? 'Piece';
    final defaultChannel =
        (orderSettings['defaultChannel'] as String?) ?? 'Salesman App';

    final whatsappEnabled = (whatsapp['enabled'] as bool?) ?? true;
    final whatsappNumber =
        (settings['whatsappOrderNumber'] as String?) ??
        (whatsapp['number'] as String?) ??
        '';
    final whatsappTemplate =
        (whatsapp['messageTemplate'] as String?) ??
        'Hello {{customerName}}, your order {{orderId}} amount is QAR {{amount}}.';

    final language = (appPrefs['language'] as String?) ?? 'English';
    final currency = (appPrefs['currency'] as String?) ?? 'QAR';
    final dateFormat = (appPrefs['dateFormat'] as String?) ?? 'dd/MM/yyyy';
    final timezone = (appPrefs['timezone'] as String?) ?? 'Asia/Qatar';
    final theme = (appPrefs['theme'] as String?) ?? 'light';
    final appLock = (security['appLockEnabled'] as bool?) ?? false;

    final lastSignIn =
        FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;

    final compact = Theme.of(context).textTheme.copyWith(
      bodyLarge: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.22),
      bodyMedium: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontSize: 12.5, height: 1.2),
      bodySmall: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontSize: 11.5, height: 1.18),
      titleMedium: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontSize: 14),
      titleSmall: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontSize: 13),
      labelLarge: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontSize: 12),
    );

    return Theme(
      data: Theme.of(context).copyWith(textTheme: compact),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            Row(
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33111827),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFEFF3F8),
                        backgroundImage: imageUrl.isEmpty
                            ? null
                            : NetworkImage(imageUrl),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$role • $region',
                              style: const TextStyle(color: Color(0xFFE2E8F0)),
                            ),
                            Text(
                              email,
                              style: const TextStyle(color: Color(0xFFCBD5E1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(icon: Icons.phone_outlined, text: phone),
                      _MetaChip(icon: Icons.map_outlined, text: region),
                      _MetaChip(icon: Icons.badge_outlined, text: role),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.lock_reset_outlined,
                    label: 'Password',
                    onTap: () => _sendPasswordReset(email),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.message_outlined,
                    label: 'WhatsApp',
                    onTap: () async {
                      final controller = TextEditingController(
                        text: whatsappNumber,
                      );
                      final value = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('WhatsApp Number'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Enter number',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (value == null) return;
                      _patchSettings({
                        'whatsappOrderNumber': value,
                        'whatsapp': {...whatsapp, 'number': value},
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.download_outlined,
                    label: 'Reports',
                    onTap: _showExportSummary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Account & Security',
              icon: Icons.shield_outlined,
              subtitle: 'Login, device and app protection',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: const Text('Change Password'),
                    subtitle: const Text(
                      'Send reset password link to your email',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _sendPasswordReset(email),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: appLock,
                    onChanged: (value) {
                      _patchSettings({
                        'security': {...security, 'appLockEnabled': value},
                      });
                    },
                    title: const Text('App Lock (PIN/Biometric)'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_android_outlined),
                    title: const Text('Device / Session Info'),
                    subtitle: Text(
                      'UID: ${auth?.uid ?? '-'}\nLast sign in: ${lastSignIn == null ? '-' : DateFormat('dd MMM yyyy, h:mm a').format(lastSignIn)}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Order Preferences',
              icon: Icons.shopping_cart_checkout_outlined,
              subtitle: 'Defaults for creating and confirming orders',
              child: Column(
                children: [
                  _DropdownTile(
                    title: 'Default Order Channel',
                    value: defaultChannel,
                    values: const ['Salesman App', 'Phone', 'WhatsApp'],
                    onChanged: (value) {
                      _patchSettings({
                        'orderPreferences': {
                          ...orderSettings,
                          'defaultChannel': value,
                        },
                      });
                    },
                  ),
                  _DropdownTile(
                    title: 'Default Unit',
                    value: defaultUnit,
                    values: const ['Piece', 'Box', 'Carton'],
                    onChanged: (value) {
                      _patchSettings({
                        'orderPreferences': {
                          ...orderSettings,
                          'defaultUnit': value,
                        },
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Low Stock Warning'),
                    value: lowStockWarning,
                    onChanged: (value) {
                      _patchSettings({
                        'orderPreferences': {
                          ...orderSettings,
                          'lowStockWarning': value,
                        },
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Confirm Before Place Order'),
                    value: confirmBeforePlace,
                    onChanged: (value) {
                      _patchSettings({
                        'orderPreferences': {
                          ...orderSettings,
                          'confirmBeforePlaceOrder': value,
                        },
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'WhatsApp Integration',
              icon: Icons.chat_outlined,
              subtitle: 'Bill sharing settings and templates',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Send Bill to WhatsApp'),
                    value: whatsappEnabled,
                    onChanged: (value) {
                      _patchSettings({
                        'whatsapp': {...whatsapp, 'enabled': value},
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Integrated WhatsApp Number'),
                    subtitle: Text(
                      whatsappNumber.isEmpty
                          ? 'Not configured'
                          : whatsappNumber,
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final controller = TextEditingController(
                        text: whatsappNumber,
                      );
                      final value = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('WhatsApp Number'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Enter number',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (value == null) return;
                      _patchSettings({
                        'whatsappOrderNumber': value,
                        'whatsapp': {...whatsapp, 'number': value},
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.message_outlined),
                    title: const Text('Message Template Preview'),
                    subtitle: Text(
                      whatsappTemplate,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final controller = TextEditingController(
                        text: whatsappTemplate,
                      );
                      final value = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Edit Template'),
                          content: TextField(
                            controller: controller,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText:
                                  'Use variables: {{customerName}}, {{orderId}}, {{amount}}',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (value == null || value.isEmpty) return;
                      _patchSettings({
                        'whatsapp': {...whatsapp, 'messageTemplate': value},
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Notifications',
              icon: Icons.notifications_outlined,
              subtitle: 'Choose alerts you want to receive',
              child: Column(
                children: [
                  _NotificationSwitch(
                    title: 'Order Status Updates',
                    value:
                        (notifications['orderStatusUpdates'] as bool?) ?? true,
                    onChanged: (value) => _patchSettings({
                      'notifications': {
                        ...notifications,
                        'orderStatusUpdates': value,
                      },
                    }),
                  ),
                  _NotificationSwitch(
                    title: 'Target Reminders',
                    value: (notifications['targetReminders'] as bool?) ?? true,
                    onChanged: (value) => _patchSettings({
                      'notifications': {
                        ...notifications,
                        'targetReminders': value,
                      },
                    }),
                  ),
                  _NotificationSwitch(
                    title: 'Payment Pending Alerts',
                    value:
                        (notifications['paymentPendingAlerts'] as bool?) ??
                        true,
                    onChanged: (value) => _patchSettings({
                      'notifications': {
                        ...notifications,
                        'paymentPendingAlerts': value,
                      },
                    }),
                  ),
                  _NotificationSwitch(
                    title: 'Stock Alerts',
                    value: (notifications['stockAlerts'] as bool?) ?? true,
                    onChanged: (value) => _patchSettings({
                      'notifications': {...notifications, 'stockAlerts': value},
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Reports & Export',
              icon: Icons.bar_chart_outlined,
              subtitle: 'Sales downloads and sync details',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Download Sales Report'),
                    subtitle: const Text(
                      'Daily / weekly / monthly CSV preview',
                    ),
                    onTap: _showExportSummary,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.table_view_outlined),
                    title: const Text('Export Order Summary'),
                    subtitle: const Text('Copy order summary in CSV format'),
                    onTap: _showExportSummary,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sync_outlined),
                    title: const Text('Sync Status'),
                    subtitle: Text(
                      'Last sync: ${DateFormat('dd MMM yyyy, h:mm a').format(DateTime.now())}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'App Preferences',
              icon: Icons.tune_outlined,
              subtitle: 'Language, currency and display options',
              child: Column(
                children: [
                  _DropdownTile(
                    title: 'Language',
                    value: language,
                    values: const ['English', 'Arabic'],
                    onChanged: (value) => _patchSettings({
                      'appPreferences': {...appPrefs, 'language': value},
                    }),
                  ),
                  _DropdownTile(
                    title: 'Currency',
                    value: currency,
                    values: const ['QAR', 'USD', 'INR'],
                    onChanged: (value) => _patchSettings({
                      'appPreferences': {...appPrefs, 'currency': value},
                    }),
                  ),
                  _DropdownTile(
                    title: 'Timezone',
                    value: timezone,
                    values: const ['Asia/Qatar', 'Asia/Kolkata', 'UTC'],
                    onChanged: (value) => _patchSettings({
                      'appPreferences': {...appPrefs, 'timezone': value},
                    }),
                  ),
                  _DropdownTile(
                    title: 'Date Format',
                    value: dateFormat,
                    values: const ['dd/MM/yyyy', 'MM/dd/yyyy', 'dd MMM yyyy'],
                    onChanged: (value) => _patchSettings({
                      'appPreferences': {...appPrefs, 'dateFormat': value},
                    }),
                  ),
                  _DropdownTile(
                    title: 'Theme',
                    value: theme,
                    values: const ['light', 'dark', 'system'],
                    onChanged: (value) => _patchSettings({
                      'appPreferences': {...appPrefs, 'theme': value},
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Support & Legal',
              icon: Icons.support_agent_outlined,
              subtitle: 'Help center, policies and app version',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Products Catalog'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProductsListPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Help Center / Contact Manager'),
                    subtitle: const Text('sales@redrose.com'),
                    onTap: () => _openUrl('mailto:sales@redrose.com'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.rule_folder_outlined),
                    title: const Text('Terms & Conditions'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsPage()),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyPage()),
                      );
                    },
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline),
                    title: Text('App Version'),
                    subtitle: Text('RED ROSE SALESMAN APP v1.0.1 (build 26)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () async {
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

                if (result == true && context.mounted) {
                  await ref
                      .read(authActionControllerProvider.notifier)
                      .signOut();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final IconData? icon;

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
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.title,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = values.contains(value) ? value : values.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButton<String>(
              value: selected,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0F172A)),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'By using this app, the salesman agrees to follow pricing, stock, and order policies.\n\n'
          '1. Customer selection is mandatory before confirming orders.\n'
          '2. Unit and market pricing are system-controlled.\n'
          '3. Orders cannot be confirmed if stock is insufficient.\n'
          '4. Inventory is deducted in base units only after order confirmation.\n'
          '5. All order records are stored for sales history.',
        ),
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'User profile, order, and analytics data are used only for business operations and reporting. '
          'Data is stored securely in Firebase and access is role-based.',
        ),
      ),
    );
  }
}
