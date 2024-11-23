import 'package:flutter/material.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  void _showResponseDialog(String messagediag) {

    //notification example
    // NotificationService.sendNotification(
    //   "Hello, I am a notification! You failed a login!",
    //   "Okay", //button to interact
    //   "Dismiss", //button to interact
    // );
    //

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

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      int response = await apiService.login(email, password);
      switch (response){
        case -1: _showResponseDialog("Invalid email");
        case -2: _showResponseDialog("Invalid password: Must be at least 8 characters and have at least 1 uppercase letter and a number");
        case -9: _showResponseDialog("Login failed.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() => email = value),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}