import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:provider/provider.dart';
import 'package:staff_app/authentication/provider/authentication_provider.dart';
import 'package:staff_app/authentication/screens/authentication_screen.dart';
import 'package:staff_app/settings/screens/about_us.dart';
import 'package:staff_app/settings/screens/privacy_policy.dart';
import 'package:staff_app/settings/screens/terms_conditions.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingsItems = [
      {
        "title": "About Us",
        "icon": Iconsax.info_circle,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutUsScreen()),
          );
        },
      },
      {
        "title": "Privacy Policy",
        "icon": Iconsax.shield_tick,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          );
        },
      },
     
      {
        "title": "Terms & Conditions",
        "icon": Iconsax.document_text,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
          );
        },
      },
   {
  "title": "Sign Out",
  "icon": Iconsax.logout,
  "onTap": () async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<UserProvider>().logout();
      // Navigate to LoginScreen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()), 
        (route) => false,
      );
    }
  },
}
,
      {
        "title": "More Settings",
        "icon": Iconsax.setting_2,
        "onTap": () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Coming Soon...")));
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: settingsItems.length,
          itemBuilder: (context, index) {
            final item = settingsItems[index];
            return seetingsCard(
              context,
              title: item["title"],
              icon: item["icon"],
              onTap: item["onTap"],
            );
          },
        ),
      ),
    );
  }

  Widget seetingsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Iconsax.arrow_right_3, size: 20),
          ],
        ),
      ),
    );
  }
}
