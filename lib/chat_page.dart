import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async'; // For periodic updates

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final storage = const FlutterSecureStorage();
  final serverurl = 'http://10.0.2.2:5000';
  late types.User _user;
  String _currentReceiver = '';
  bool _isLoading = true;
  Timer? _messageTimer; // Timer for periodic message refresh

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _messageTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  /// Initialize the user and load messages
  Future<void> _initializeUser() async {
    try {
      final email = await storage.read(key: "email");
      final receiverEmail = await storage.read(key: "receiver_email");

      if (email != null && receiverEmail != null) {
        setState(() {
          _user = types.User(
            id: email,
            firstName: email.split('@').first,
          );
          _currentReceiver = receiverEmail;
          _isLoading = false;
        });

        _loadMessages(); // Initial message load
        _startMessageRefresh(); // Start periodic refresh
      } else {
        throw Exception("User or receiver email not found in storage.");
      }
    } catch (e) {
      print("Error initializing chat: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Periodically refresh messages every 5 seconds
  void _startMessageRefresh() {
    _messageTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadMessages();
    });
  }

  /// Add a new message to the UI
  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  /// Handle sending a message
  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    await _sendMessageToServer(textMessage);
  }

  /// Send a message to the server
  Future<void> _sendMessageToServer(types.TextMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('$serverurl/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': message.text,
          'author_id': message.author.id,
          'receiver_id': _currentReceiver,
          'created_at': message.createdAt,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Load messages from the server
  Future<void> _loadMessages() async {
    try {
      final response = await http.post(
        Uri.parse('$serverurl/get_messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'author_id': _user.id,
          'receiver_id': _currentReceiver,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final messages = responseData.map((message) {
          return types.TextMessage(
            id: message['_id'] ?? '',
            author: types.User(id: message['author_id']),
            createdAt: message['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
            text: message['text'] ?? '',
          );
        }).toList();

        setState(() {
          _messages = messages;
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ' + _currentReceiver),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
      ),
    );
  }
}
