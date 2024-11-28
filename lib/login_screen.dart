import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khuje_nao/activity_feed.dart';
import 'package:khuje_nao/admin_page.dart';
import 'package:khuje_nao/localization.dart';
import 'package:khuje_nao/main.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage(); // For secure storage
  String _language = 'en'; // Default language
  String email = '';
  String password = '';
  bool rememberMe = false; // Track the "Remember Me" checkbox state
  String otp = ''; // To store entered OTP

  @override
  void initState() {
    super.initState();
    _checkIfUserRemembered(); // Check if the user has already logged in
    _loadLanguage();
  }
  Future<void> _loadLanguage() async {
    String? storedLanguage = await _storage.read(key: 'language');
    setState(() {
      _language = storedLanguage ?? 'en';
    });
  }

  /// Check if email exists in secure storage and redirect if true
  Future<void> _checkIfUserRemembered() async {
    final savedEmail = await _storage.read(key: 'email');
    if (savedEmail != null) {
      // Email exists, redirect to the activity feed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ActivityFeedPage()),
      );
    }
  }

  /// Show a dialog with a message
  void _showResponseDialog(String messagediag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messagediag),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog
              },
              child: Text(AppLocalization.getString(_language,"okay")),
            ),
          ],
        );
      },
    );
  }

  /// Show OTP Verification Dialog
  void _showOtpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalization.getString(_language,"otp_send") + email),
          content: TextField(
            onChanged: (value) => otp = value,
            decoration: const InputDecoration(labelText: "OTP"),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text(AppLocalization.getString(_language,"cancel")),
            ),
            ElevatedButton(
              onPressed: () async {
                final isValidOtp = await apiService.verifyOtp(email, otp);
                if (isValidOtp) {
                  Navigator.pop(context); // Close dialog
                  _showResponseDialog(AppLocalization.getString(_language,"otp_verified"));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ActivityFeedPage()),
                  );
                } else {
                  _showResponseDialog(AppLocalization.getString(_language,"otp_invalid"));
                  _storage.delete(key: 'email');
                }
              },
              child: Text(AppLocalization.getString(_language,"verify")),
            ),
          ],
        );
      },
    );
  }

  /// Perform login and handle remember me logic
  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      if (email.compareTo('Admin')==0 && password.compareTo('Admin')==0){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPage()),
        );
        return;
      }
      int response = await apiService.login(email, password);
      switch (response) {
        case -1:
          _showResponseDialog(AppLocalization.getString(_language,"invalid_mail"));
          break;
        case -2:
          _showResponseDialog(AppLocalization.getString(_language,"invalid_pass"));
          break;
        case -9:
          _showResponseDialog(AppLocalization.getString(_language,"login_failed"));
          break;
        case 0:
          if (rememberMe) {
            // Save email securely if "Remember Me" is selected
            await _storage.write(key: 'email', value: email);
          }
          final otpSent = await apiService.sendOtp(email);
          if (otpSent) {
            _showOtpDialog(); // Show the OTP dialog
          } else {
            _showResponseDialog("Failed to send OTP. Please try again.");
            _storage.delete(key: 'email');
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(AppLocalization.getString(_language,"login")),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HomeScreen()),
                );
              },
              child: Text(AppLocalization.getString(_language,"go_home")),
            ),
          ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(_language,"email")),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() => email = value),
                initialValue: email, // Prepopulate if saved
              ),
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(_language,"password")),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
                initialValue: password, // Prepopulate if saved
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: Text(AppLocalization.getString(_language,"remember_me")),
                value: rememberMe,
                onChanged: (bool? value) {
                  setState(() {
                    rememberMe = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: Text(AppLocalization.getString(_language,"login")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
