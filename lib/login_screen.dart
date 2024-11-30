import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khuje_nao/activity_feed.dart';
import 'package:khuje_nao/admin_page.dart';
import 'package:khuje_nao/localization.dart';
import 'package:khuje_nao/main.dart';
import 'api_service.dart';

/// `LoginScreen` is a StatefulWidget that handles user login and OTP verification.
/// It provides functionality for remembering user credentials, submitting login details,
/// and verifying OTP sent to the user’s email.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  /// The `ApiService` instance used to interact with the backend.
  final ApiService api_service = ApiService();

  /// The global key used for form validation.
  final form_key = GlobalKey<FormState>();

  /// Secure storage used to persist sensitive data, such as email and language preference.
  final STORAGE = const FlutterSecureStorage();

  /// The currently selected language (default is English).
  String language = 'en';

  /// The email entered by the user.
  String email = '';

  /// The password entered by the user.
  String password = '';

  /// Tracks whether the "Remember Me" checkbox is selected.
  bool remember_me = false;

  /// Stores the OTP entered by the user for verification.
  String otp = '';

  @override
  void initState() {
    super.initState();
    checkIfUserRemembered(); // Check if the user is already logged in
    loadLanguage(); // Load the preferred language from storage
  }

  /// Loads the preferred language from secure storage.
  Future<void> loadLanguage() async {
    String? stored_language = await STORAGE.read(key: 'language');
    setState(() {
      language = stored_language ?? 'en';
    });
  }

  /// Checks if the user's email exists in secure storage,
  /// and if it does, redirects to the ActivityFeedPage.
  Future<void> checkIfUserRemembered() async {
    final saved_email = await STORAGE.read(key: 'email');
    if (saved_email != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ActivityFeedPage()),
      );
    }
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
              child: Text(AppLocalization.getString(language, "okay")),
            ),
          ],
        );
      },
    );
  }

  /// Displays an OTP verification dialog where the user can input the OTP sent to their email.
  void showOtpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalization.getString(language, "otp_send") + email),
          content: TextField(
            onChanged: (value) => otp = value,  // Store OTP entered by the user
            decoration: const InputDecoration(labelText: "OTP"),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),  // Close the dialog
              child: Text(AppLocalization.getString(language, "cancel")),
            ),
            ElevatedButton(
              onPressed: () async {
                final is_valid_otp = await api_service.verifyOtp(email, otp);
                if (is_valid_otp) {
                  Navigator.pop(context);  // Close dialog
                  showResponseDialog(AppLocalization.getString(language, "otp_verified"));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ActivityFeedPage()),
                  );
                } else {
                  showResponseDialog(AppLocalization.getString(language, "otp_invalid"));
                  STORAGE.delete(key: 'email'); // Delete stored email on OTP failure
                }
              },
              child: Text(AppLocalization.getString(language, "verify")),
            ),
          ],
        );
      },
    );
  }

  /// Handles user login.
  ///
  /// This method validates the form, checks if the user is an admin,
  /// sends a request to log in, and displays the appropriate response dialogs.
  Future<void> login() async {
    if (form_key.currentState!.validate()) {
      if (email.compareTo('Admin') == 0 && password.compareTo('Admin') == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPage()),
        );
        return;
      }
      int response = await api_service.login(email, password);
      switch (response) {
        case -1:
          showResponseDialog(AppLocalization.getString(language, "invalid_mail"));
          break;
        case -2:
          showResponseDialog(AppLocalization.getString(language, "invalid_pass"));
          break;
        case -9:
          showResponseDialog(AppLocalization.getString(language, "login_failed"));
          break;
        case 0:
          if (remember_me) {
            await STORAGE.write(key: 'email', value: email); // Save email securely
          }
          final otpSent = await api_service.sendOtp(email);
          if (otpSent) {
            showOtpDialog(); // Show the OTP dialog
          } else {
            showResponseDialog("Failed to send OTP. Please try again.");
            STORAGE.delete(key: 'email'); // Delete stored email if OTP fails
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.getString(language, "login")),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: Text(AppLocalization.getString(language, "go_home")),
          ),
        ],
      ),
      body: Form(
        key: form_key,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(language, "email")),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() => email = value),
                initialValue: email, // Prepopulate if saved
              ),
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(language, "password")),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
                initialValue: password, // Prepopulate if saved
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: Text(AppLocalization.getString(language, "remember_me")),
                value: remember_me,
                onChanged: (bool? value) {
                  setState(() {
                    remember_me = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: Text(AppLocalization.getString(language, "login")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
