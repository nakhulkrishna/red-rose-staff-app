import 'package:flutter/material.dart';
import 'package:staff_app/features/auth/presentation/pages/login_page.dart';
import 'package:staff_app/features/products/presentation/pages/products_page.dart';
import 'package:staff_app/shared/widgets/app_scaffold.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Auth Feature'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Products Feature'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
