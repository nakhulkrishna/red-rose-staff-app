import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/authentication/provider/authentication_provider.dart';
import 'package:staff_app/authentication/screens/authentication_screen.dart'
    show LoginScreen;
import 'package:staff_app/products/screen/products.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check login after 2 seconds
    Future.delayed(const Duration(seconds: 2), () async {
      bool isLoggedIn = await userProvider.checkLogin();

      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              height: 40,
              width: 40,
              child: LoadingIndicator(
                indicatorType: Indicator.ballPulse,
              
              
                colors: const [Colors.white],
              
               
                strokeWidth: 2,
              
            
              
              ),
            ),
           
  
          ],
        ),
      ),
    );
  }
}
