import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/authentication%20copy/provider/authentication_provider.dart';
import 'package:staff_app/authentication%20copy/screens/splash_screen.dart';

import 'package:staff_app/firebase_options.dart';
import 'package:staff_app/order_products/provider/customer.dart';
import 'package:staff_app/products/provider/products_management.dart';
import 'package:staff_app/products/screen/products.dart';
import 'package:staff_app/products/screen/products_management.dart';
import 'package:staff_app/order_products/provider/provider.dart';

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
      ChangeNotifierProvider(create: (_) => Costomer()),
    ChangeNotifierProvider(create: (context) => ProductProvider()),
    ChangeNotifierProvider(create: (context) => StaffProvider()),
    ChangeNotifierProvider(create: (context) => ThemeProvider()), // <-- Add this
     ChangeNotifierProvider(create: (_) => UserProvider()),
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
          home: const SplashScreen(),
        );
      },
    );
  }
}
