import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_service.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
/// The main entry point of the application.
///
/// Initializes notifications and runs the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // uses your firebase_options.dart
  runApp(const MyApp());
}

/// The root widget of the application with theme handling.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final saved = await _storage.read(key: 'theme_mode');
    setState(() {
      _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final next = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setState(() {
      _themeMode = next;
    });
    await _storage.write(key: 'theme_mode', value: next == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khuje Nao',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: HomeScreen(onToggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}

/// The home screen of the app, where users can navigate to login or signup pages.
///
/// This widget also allows users to toggle between English and Bengali languages.
class HomeScreen extends StatefulWidget {
  /// Constructor for [HomeScreen].
  const HomeScreen({super.key, required this.onToggleTheme, required this.themeMode});

  final Future<void> Function() onToggleTheme;
  final ThemeMode themeMode;

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
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
          ),
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
