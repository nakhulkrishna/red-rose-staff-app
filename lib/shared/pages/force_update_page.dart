import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:staff_app/shared/providers/app_update_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blocking screen shown when the installed build is below the minimum
/// configured in catalog_app_config/app_version. Cannot be dismissed.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key, required this.status});

  final AppUpdateStatus status;

  String get _storeUrl {
    if (!kIsWeb && Platform.isIOS) {
      return status.iosUrl.isNotEmpty ? status.iosUrl : status.androidUrl;
    }
    return status.androidUrl.isNotEmpty ? status.androidUrl : status.iosUrl;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  height: 104,
                  width: 104,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E7FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    size: 52,
                    color: Color(0xFF3730A3),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Update Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  status.message.isNotEmpty
                      ? status.message
                      : 'A new version of the app is required to continue. '
                            'Please update to keep placing orders.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _VersionChip(
                        label: 'Installed',
                        value: status.currentVersion.isEmpty
                            ? '-'
                            : status.currentVersion,
                        color: const Color(0xFFB91C1C),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      _VersionChip(
                        label: 'Latest',
                        value: status.latestVersion.isEmpty
                            ? 'New version'
                            : status.latestVersion,
                        color: const Color(0xFF047857),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openStore(context),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Update Now'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final url = _storeUrl;
    final messenger = ScaffoldMessenger.of(context);
    if (url.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Update link not configured. Contact your admin.'),
        ),
      );
      return;
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the update link.')),
      );
    }
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
