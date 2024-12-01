import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_service.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'localization.dart';

/// The main entry point of the application.
///
/// Initializes notifications and runs the app.
void main() async {
  NotificationService.initializeNotifications();
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Constructor for [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khuje Nao',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

/// The home screen of the app, where users can navigate to login or signup pages.
///
/// This widget also allows users to toggle between English and Bengali languages.
class HomeScreen extends StatefulWidget {
  /// Constructor for [HomeScreen].
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  /// Instance of [FlutterSecureStorage] to persist language preferences securely.
  final FlutterSecureStorage STORAGE = const FlutterSecureStorage();

  /// Stores the current language code (`en` for English, `bd` for Bengali).
  String language = 'en'; // Default language

  @override
  void initState() {
    super.initState();
    loadLanguage();
  }

  /// Loads the user's preferred language from secure storage.
  ///
  /// If no language is found, defaults to English (`en`).
  Future<void> loadLanguage() async {
    String? storedLanguage = await STORAGE.read(key: 'language');
    setState(() {
      language = storedLanguage ?? 'en';
    });
  }

  /// Toggles the language between English (`en`) and Bengali (`bd`) and updates secure storage.
  Future<void> toggleLanguage() async {
    String newLanguage = language == 'en' ? 'bd' : 'en';
    await STORAGE.write(key: 'language', value: newLanguage);
    setState(() {
      language = newLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Khuje Nao'),
        actions: [
          ElevatedButton(
            onPressed: toggleLanguage,
            child: Text(
              language == 'en' ? 'বাংলা' : 'English',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: Text(AppLocalization.getString(language, 'signup')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(AppLocalization.getString(language, 'login')),
            ),
          ],
        ),
      ),
    );
  }
}
