import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fyp_diabetease/features/app/splash_screen/splash_screen.dart';
import 'package:fyp_diabetease/features/view/layout/mainLayout.dart';
import 'package:fyp_diabetease/features/view/pages/admin/admin_homepage.dart';
import 'package:fyp_diabetease/features/view/pages/admin/manage_recipe.dart';
import 'package:fyp_diabetease/features/view/pages/admin/manage_user.dart';
import 'package:fyp_diabetease/features/view/pages/onboarding.dart';
import 'package:fyp_diabetease/features/view/pages/profile/edit_profile_page.dart';
import 'package:fyp_diabetease/features/view/pages/login_signup/login_page.dart';
import 'package:fyp_diabetease/features/view/pages/profile/profile_page.dart';
import 'package:fyp_diabetease/features/view/pages/login_signup/sign_up_page.dart';
import 'package:fyp_diabetease/features/view/pages/signUp_page.dart';
import 'package:fyp_diabetease/features/view/pages/upload/upload_recipe_page.dart';
import 'package:fyp_diabetease/features/view/pages/upload/nutritional_analysis_page.dart';
import 'package:fyp_diabetease/features/view/pages/inbox/inbox_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetease',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set theme to blue
        primaryColor: Colors.blue,
        hintColor: Colors.blueAccent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue, // Button text color
          ),
        ),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            titleTextStyle: TextStyle(color: Colors.white)),
      ),
      home: SplashScreen(
        child: OnboardingScreen(),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        'onboarding': (context) => OnboardingScreen(),
        'signUp_page': (context) => Sign_UpPage(),
        'login_page': (context) => const LoginPage(),
        'sign_up_page': (context) => const SignUpPage(),
        'main_layout': (context) => const MainLayout(),
        'upload_recipe_page': (context) => const UploadRecipe(),
        'edit_profile_page': (context) => const EditProfilePage(),
        'profile_page': (context) => const ProfilePage(),
        'nutritional_analysis': (context) => NutritionalAnalysisPage(
              recipeName: 'Sample Recipe',
              ingredients: 'Sample Ingredient 1, Sample Ingredient 2',
              calories: 200,
              fat: 10,
              sugar: 5,
              protein: 15,
              glycemicIndex: 50,
              carbohydrateContent: 30,
              fiberContent: 10,
              sodiumContent: 200,
              addedSugars: 5,
              riskLevel: 3.5,
              advice: 'Sample advice',
            ),
        //'homepage': (context) => const Homepage(),
        'inbox': (context) => const InboxPage(),
        'admin_homepage': (context) => AdminHomepage(),
        'manage_users_page': (context) => const ManageUsersPage(),
        //'view_reports_page': (context) => const ViewReportsPage(),
        'manage_recipes_page': (context) => const ManageRecipesPage(),
      },
    );
  }
}
