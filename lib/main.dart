import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/firebase_options.dart';
import 'package:staff_app/products/provider/products_management.dart';
import 'package:staff_app/products/screen/products.dart';
import 'package:staff_app/products/screen/products_management.dart';
import 'package:staff_app/staff_management/provider/provider.dart';
import 'package:staff_app/theme/theme.dart';
import 'package:staff_app/theme/themeprovider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Create theme provider and wait for saved theme
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeFromPrefs();
  runApp(MultiProvider(
    providers: [
    ChangeNotifierProvider(create: (context) => ProductProvider()),
    ChangeNotifierProvider(create: (context) => StaffProvider()),
    ChangeNotifierProvider(create: (context) => ThemeProvider()), // <-- Add this
  ],
    child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RED ROSE STAFF',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode, // Dynamic theme
          home: const DashboardScreen(),
        );
      },
    );
  }
}
