import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final storage = const FlutterSecureStorage();
  final serverurl = 'http://10.0.2.2:5000';
  late types.User _user; // Updated to store `types.User`
  bool _isLoading = true; // Track whether initialization is complete
  final TextEditingController _receiverController = TextEditingController(); // For entering receiver ID/email
  String _currentReceiver = ''; // To track the selected receiver

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Initialize user data
  }

  /// Initialize the `_user` object by reading the email from storage
  Future<void> _initializeUser() async {
    try {
      final email = await storage.read(key: "email"); // Read email from storage
      if (email != null) {
        setState(() {
          _user = types.User(
            id: email, // Use email as the user ID
            firstName: email.split('@').first, // Extract the first part of the email for display
          );
          _isLoading = false; // Mark initialization as complete
        });
      } else {
        throw Exception("No email found in secure storage.");
      }
    } catch (e) {
      print("Error initializing user: $e");
      setState(() {
        _isLoading = false; // Allow UI to display an error state
      });
    }
  }

  /// Add a message to the local message list
  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  /// Handle when the user sends a message
  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user, // Use `_user` as the message author
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(), // Generate a unique ID for this message
      text: message.text,
    );

    _addMessage(textMessage); // Add to the UI immediately
    await _sendMessageToServer(textMessage); // Send to the server
  }

  /// Send the message to the server
  Future<void> _sendMessageToServer(types.TextMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('$serverurl/send_message'), // Adjust your server endpoint if needed
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': message.text,
          'author_id': message.author.id, // Use the `id` field from `types.User`
          'receiver_id': _currentReceiver, // Use the current receiver from the text field
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
  void _loadMessages(String authorId, String receiverId) async {
    try {
      final response = await http.post(
        Uri.parse('$serverurl/get_messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'author_id': authorId, // Use the `id` field from `types.User`
          'receiver_id': receiverId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        print(responseData.toString());
        // Map each message from the server to the expected `types.TextMessage` format
        final messages = responseData.map((message) {
          final text = message['text'] ?? ''; // Use empty string if `text` is null
          final authorId = message['author_id'] ?? 'unknown'; // Default ID if `author_id` is null
          final createdAt = message['created_at'] ?? DateTime.now().millisecondsSinceEpoch;


          return types.TextMessage(
            id: message['_id'] ?? '', // Use empty string if `_id` is null
            author: types.User(id: authorId),
            createdAt: createdAt,
            text: text,
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

  /// Build the chat page UI
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _receiverController,
                    decoration: const InputDecoration(
                      labelText: 'Receiver Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentReceiver = _receiverController.text;
                      _loadMessages(_user.id, _currentReceiver);
                    });
                  },
                  child: const Text('Load Chat'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _user,
            ),
          ),
        ],
      ),
    );
  }
}
