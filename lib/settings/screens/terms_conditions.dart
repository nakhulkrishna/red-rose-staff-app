import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildSection(String title, String content, IconData icon) {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.primaryColor,
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(content, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last Updated: 27 Aug 2025",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            buildSection(
              "Use of App",
              "The app is designed to help users manage products, orders, and records. "
              "Do not use the app for illegal purposes.",
              Iconsax.document,
            ),

            buildSection(
              "Account & Data",
              "Users are responsible for maintaining account credentials. "
              "You can delete your account at any time from within the app. "
              "Deleting your account permanently removes all personal data.",
              Iconsax.trash,
            ),

            buildSection(
              "Orders & Delivery",
              "This app is for record-keeping only. "
              "No shipping or delivery is handled within the app.",
              Iconsax.box,
            ),

            buildSection(
              "Payments",
              "No payments or transactions are processed within the app. "
              "All payments are handled externally.",
              Iconsax.money,
            ),

            buildSection(
              "Restrictions",
              "Users may not resell, redistribute, or misuse the app in any way.",
              Iconsax.warning_2,
            ),

            buildSection(
              "Disclaimer",
              "We are not liable for data loss or misuse caused by user negligence "
              "or unauthorized third-party access.",
              Iconsax.shield,
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                "© 2025 Red Rose",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
