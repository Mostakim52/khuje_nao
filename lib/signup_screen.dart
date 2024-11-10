import 'package:flutter/material.dart';
import 'api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  int nsu_id = 0;
  String phone_number = ''; // Default value for the dropdown

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
        case -1: _showResponseDialog("Invalid Name: Name limit is between 2 and 50 characters");
        case -2: _showResponseDialog("Invalid email");
        case -3: _showResponseDialog("Invalid password: Must be at least 8 characters and have at least 1 uppercase letter and a number");
        case -4: _showResponseDialog("Invalid NSU ID. Must be first 7 digits of NSU ID.");
        case -5: _showResponseDialog("Invalid phone number: Make sure The number starts with 01, the third digit is 3 through 9 (for valid operators and the total length is exactly 11 digits.");
        case -6: _showResponseDialog("Sign Up failed");
        case 0: _showResponseDialog("Sign Up Successful");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => setState(() => name = value),
              ),
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
              TextFormField(
                decoration: const InputDecoration(labelText: 'NSU ID (first 7 digits'),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() => nsu_id = int.parse(value)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                onChanged: (value) => setState(() => phone_number = value),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: signup,
                child: const Text('Signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}