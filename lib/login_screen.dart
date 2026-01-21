import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khuje_nao/activity_feed.dart';
import 'package:khuje_nao/admin_page.dart';
import 'package:khuje_nao/localization.dart';
import 'package:khuje_nao/main.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:khuje_nao/profile_completion_screen.dart';

/// `LoginScreen` handles user login via Google Sign-In only.
/// Users must select their @northsouth.edu Google account to sign in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  /// The `ApiService` instance used to interact with the backend.
  final ApiService api_service = ApiService();

  /// Secure storage used to persist sensitive data, such as email and language preference.
  final STORAGE = const FlutterSecureStorage();

  /// The currently selected language (default is English).
  String language = 'en';

  /// Loading state for Google Sign-In
  bool is_loading = false;

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

  /// Handles Google Sign-In for login.
  /// Checks if user exists in database, if yes - logs in, if no - shows error to sign up.
  Future<void> signInWithGoogle() async {
    setState(() {
      is_loading = true;
    });

    try {
      // Show account picker (all Google accounts on device)
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          is_loading = false;
        });
        return; // User cancelled
      }

      final email = googleUser.email;
      if (email == null || !email.endsWith('@northsouth.edu')) {
        setState(() {
          is_loading = false;
        });
        showResponseDialog("Only @northsouth.edu email accounts are allowed. Please select your North South University account.");
        return;
      }

      // Check if user exists in database
      final userExists = await api_service.checkUserExists(email);
      if (!userExists) {
        setState(() {
          is_loading = false;
        });
        showResponseDialog("Account does not exist. Please sign up first.");
        return;
      }

      // User exists - proceed with Firebase authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        setState(() {
          is_loading = false;
        });
        showResponseDialog("Google sign-in failed: No ID token.");
        return;
      }

      // Verify with backend
      final response = await api_service.firebaseGoogleLogin(idToken);
      if (!response) {
        setState(() {
          is_loading = false;
        });
        showResponseDialog("Google Sign-In backend verification failed.");
        return;
      }

      // Check if profile is complete
      final profile = await api_service.getProfile(idToken);
      final isProfileComplete = profile != null && profile['profile_complete'] == true;

      // Store email for session
      await STORAGE.write(key: 'email', value: email);

      setState(() {
        is_loading = false;
      });

      if (!isProfileComplete) {
        // Redirect to profile completion screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileCompletionScreen(idToken: idToken)),
        );
        if (result == true && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ActivityFeedPage()));
        }
      } else {
        // Navigate to activity feed
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ActivityFeedPage()));
        }
      }
    } catch (e) {
      setState(() {
        is_loading = false;
      });
      showResponseDialog("Google Sign-In error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.getString(language, "login")),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalization.getString(language, "go_home")),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Sign in with your\nNorth South University account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your @northsouth.edu Google account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              if (is_loading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
