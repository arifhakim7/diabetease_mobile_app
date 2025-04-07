import 'package:flutter/material.dart';

class Sign_UpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image
              Image.asset(
                'asset/logo.png',
                height: 130,
                width: 130,
              ),
              const SizedBox(height: 40),
              // Buttons Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to sign-up functionality
                        Navigator.pushNamed(context, 'sign_up_page');
                      },
                      child: const Text('Sign Up',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment
                          .bottomCenter, // Aligns the text at the bottom
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black, // Default text color
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to login page
                              Navigator.pushNamed(context, 'login_page');
                            },
                            child: const Text(
                              "Log in.",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue, // Blue color for the button
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
