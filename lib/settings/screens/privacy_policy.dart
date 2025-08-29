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
                "- Name, Email, WhatsApp Number.\n"
                    "- Orders, Products, Customer details.\n"
                    "- No payment details are collected.",
              ),

              section(
                "How We Use Information",
                Iconsax.activity,
                "- Manage sales and product records.\n"
                    "- Communicate order-related details.\n"
                    "- Provide support & improve services.",
              ),

              section(
                "Data Sharing",
                Iconsax.share,
                "- We do not sell or rent data.\n"
                    "- Data may be shared with trusted third-party services only if required.",
              ),

              section(
                "Data Security",
                Iconsax.shield_tick,
                "We apply reasonable security measures to keep your data safe.",
              ),

              section(
                "Contact Us",
                Iconsax.message,
                "Email: jabirkarulai@gmail.com\nWhatsApp: ++974 7727 0580 \nIndian: 9946270580",
              ),

              const SizedBox(height: 30),
              Center(
                child: Text(
                  "© 2025 Red Rose Contracting W.L.L",
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
