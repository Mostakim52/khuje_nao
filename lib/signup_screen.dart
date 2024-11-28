import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'localization.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage(); // For secure storage
  String _language = 'en'; // Default language
  String name = '';
  String email = '';
  String password = '';
  int nsu_id = 0;
  String phone_number = ''; // Default value for the dropdown

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }
  Future<void> _loadLanguage() async {
    String? storedLanguage = await _storage.read(key: 'language');
    setState(() {
      _language = storedLanguage ?? 'en';
    });
  }

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
              child: const Text("Okay"),
            ),
          ],
        );
      },
    );
  }

  Future<void> signup() async {
    if (_formKey.currentState!.validate()) {
      int response = await apiService.signup(name, email, password, nsu_id, phone_number);
      switch(response){
        case -1: _showResponseDialog(AppLocalization.getString(_language,"invalid_name"));
        case -2: _showResponseDialog(AppLocalization.getString(_language,"invalid_mail"));
        case -3: _showResponseDialog(AppLocalization.getString(_language,"invalid_pass"));
        case -4: _showResponseDialog(AppLocalization.getString(_language,"invalid_id"));
        case -5: _showResponseDialog(AppLocalization.getString(_language,"invalid_phone"));
        case -6: _showResponseDialog(AppLocalization.getString(_language,"signup_fail"));
        case 0: _showResponseDialog("Sign Up Successful"); Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalization.getString(_language,"signup"))),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(_language,"name")),
                onChanged: (value) => setState(() => name = value),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(_language,"email")),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() => email = value),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(_language,"password")),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(_language,"id")),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() => nsu_id = int.parse(value)),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: AppLocalization.getString(_language,"phone_no")),
                keyboardType: TextInputType.phone,
                onChanged: (value) => setState(() => phone_number = value),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: signup,
                child: Text(AppLocalization.getString(_language,"signup")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}