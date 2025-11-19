import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khuje_nao/login_screen.dart';
import 'activity_feed.dart';
import 'api_service.dart';
import 'google_phone_onboarding.dart';
import 'localization.dart';

/// `SignupScreen` is a StatefulWidget that handles the user sign-up process.
/// It provides a form for users to enter their name, email, password, NSU ID,
/// and phone number, and handles submission of the sign-up request to the server.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  /// The `ApiService` instance used to interact with the backend API for sign-up.
  final ApiService api_service = ApiService();

  /// The global key used for form validation.
  final form_key = GlobalKey<FormState>();

  /// Secure storage used to persist sensitive data such as the preferred language.
  final STORAGE = const FlutterSecureStorage();

  /// The current selected language (default is English).
  String language = 'en';

  /// User's name entered during sign-up.
  String name = '';

  /// User's email entered during sign-up.
  String email = '';

  /// User's password entered during sign-up.
  String password = '';

  /// User's NSU ID entered during sign-up.
  int nsu_id = 0;

  /// User's phone number entered during sign-up.
  String phone_number = '';


  @override
  void initState() {
    super.initState();
    loadLanguage(); // Load the language preference from secure storage
  }

  /// Loads the preferred language from secure storage.
  Future<void> loadLanguage() async {
    String? stored_language = await STORAGE.read(key: 'language');
    setState(() {
      language = stored_language ?? 'en';
    });
  }

  /// Displays a response dialog with a custom message.
  ///
  /// [message_diag] is the message to be displayed in the dialog.
  void showResponseDialog(String message_diag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message_diag),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Okay"),
            ),
          ],
        );
      },
    );
  }

  // OTP removed for signup flow

  /// Handles user sign-up.
  ///
  /// This method validates the form and sends the sign-up details (name, email, password, NSU ID, and phone number)
  /// to the backend. Depending on the response, it shows appropriate messages.
  Future<void> signup() async {
    if (form_key.currentState!.validate()) {
      int response = await api_service.signup(name, email, password, nsu_id, phone_number);
      switch(response) {
        case -1: showResponseDialog(AppLocalization.getString(language, "invalid_name"));
        case -2: showResponseDialog(AppLocalization.getString(language, "invalid_mail"));
        case -3: showResponseDialog(AppLocalization.getString(language, "invalid_pass"));
        case -4: showResponseDialog(AppLocalization.getString(language, "invalid_id"));
        case -5: showResponseDialog(AppLocalization.getString(language, "invalid_phone"));
        case -6: showResponseDialog(AppLocalization.getString(language, "signup_fail"));
        case 0:
          showResponseDialog("Sign Up Successful");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalization.getString(language, "signup"))),
      body: Form(
        key: form_key,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              /// Name text field
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(language, "name")),
                onChanged: (value) => setState(() => name = value),
              ),

              /// Email text field
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(language, "email")),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() => email = value),
              ),

              /// Password text field
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(language, "password")),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
              ),

              /// NSU ID text field
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(language, "id")),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() => nsu_id = int.parse(value)),
              ),

              /// Phone number text field
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(language, "phone_no")),
                keyboardType: TextInputType.phone,
                onChanged: (value) => setState(() => phone_number = value),
              ),

              const SizedBox(height: 20),

              /// Sign-up button
              ElevatedButton(
                onPressed: signup,
                child: Text(AppLocalization.getString(language, "signup")),
              ),

              // In login_screen.dart (or signup_screen.dart):
              ElevatedButton(
                onPressed: () async {
                  final ok = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GooglePhoneOnboarding()),
                  );
                  if (ok == true && context.mounted) {
                    // Go to your main page after onboarding
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => ActivityFeedPage()),
                    );
                  }
                },
                child: const Text('Continue with Google + Phone OTP'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
