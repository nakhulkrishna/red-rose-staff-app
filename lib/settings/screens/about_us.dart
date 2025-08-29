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
              Text("About Us", style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                "Red Rose Contracting W.L.L\n\n"
                "We specialize in wholesale dates and chocolates, providing high-quality products to meet business and customer demands.\n\n"
                "Our vision is to build long-term relationships by delivering excellence, reliability, and premium quality products.\n\n"
                "This Sales Management App is designed exclusively to help manage product, order, and customer data efficiently.",
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
