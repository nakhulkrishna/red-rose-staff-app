import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget section(String title, IconData icon, String content) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.primaryColor,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Privacy Policy",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Last Updated: 27 Aug 2025",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              section(
                "Information We Collect",
                Iconsax.document,
                "- Name, Email, and Contact Number.\n"
                "- Orders, products, and app usage data.\n"
                "- No payment details are collected.",
              ),

              section(
                "How We Use Information",
                Iconsax.activity,
                "- To provide and improve app features.\n"
                "- To communicate updates and provide support.\n"
                "- To ensure a smooth and secure user experience.",
              ),

              section(
                "Account Deletion",
                Iconsax.trash,
                "- Users can delete their account at any time from within the app.\n"
                "- Deleting the account permanently removes all personal data and app history.",
              ),

              section(
                "Data Sharing",
                Iconsax.share,
                "- We do not sell or rent personal data.\n"
                "- Data may be shared with trusted third-party services only if required to provide app functionality.",
              ),

              section(
                "Data Security",
                Iconsax.shield_tick,
                "We use reasonable security measures to protect your data from unauthorized access.",
              ),

              section(
                "Contact Us",
                Iconsax.message,
                "Email: jabirkarulai@gmail.com\nWhatsApp: ++974 7727 0580 / Indian: 9946270580",
              ),

              const SizedBox(height: 30),
              Center(
                child: Text(
                  "© 2025 Red Rose",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
