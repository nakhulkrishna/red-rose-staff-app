import 'package:flutter/material.dart';

class PriceModeBanner extends StatelessWidget {
  const PriceModeBanner({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        'Price Mode: $label',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF9A3412),
        ),
      ),
    );
  }
}
