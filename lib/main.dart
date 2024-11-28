import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_service.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'chat_page.dart';
import 'report_lost_item_screen.dart';
import 'search_lost_item_screen.dart';
import 'localization.dart';

void main() {
  NotificationService.initializeNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _language = 'en'; // Default language

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  // Load the language preference from secure storage
  Future<void> _loadLanguage() async {
    String? storedLanguage = await _storage.read(key: 'language');
    setState(() {
      _language = storedLanguage ?? 'en';
    });
  }

  // Toggle the language and update storage
  Future<void> _toggleLanguage() async {
    String newLanguage = _language == 'en' ? 'bd' : 'en';
    await _storage.write(key: 'language', value: newLanguage);
    setState(() {
      _language = newLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Khuje Nao'),
        actions: [
          ElevatedButton(
            onPressed: _toggleLanguage,
            child: Text(
              _language == 'en' ? 'বাংলা' : 'English',
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
              child: Text(AppLocalization.getString(_language, 'signup')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(AppLocalization.getString(_language, 'login')),
            ),
          ],
        ),
      ),
    );
  }
}
