import 'package:flutter/material.dart';

/// 🔑 About Us
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "About Us",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome to Red Rose!\n\n"
                "Our app helps users manage products, orders, and customer information efficiently. "
                "We aim to provide a smooth and reliable experience for everyone who uses our app.\n\n"
                "Our mission is to deliver high-quality service, improve user experience, and ensure data privacy and security for all users.\n\n"
                "This app is designed for general use and to assist anyone looking to organize and manage sales or product information effectively.",
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
