import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final _user = const types.User(id: 'your_user_id'); // Replace with your app's user ID.

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    // Send the message to your server
    await _sendMessageToServer(textMessage);
  }

  Future<void> _sendMessageToServer(types.TextMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('your_server_endpoint'), // Replace with your backend API URL.
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': message.id,
          'text': message.text,
          'author_id': message.author.id,
          'created_at': message.createdAt,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _loadMessages() async {
    try {
      // Fetch messages from your server
      final response = await http.get(
        Uri.parse('your_server_endpoint'), // Replace with your backend API URL.
      );

      if (response.statusCode == 200) {
        final messages = (jsonDecode(response.body) as List)
            .map((e) => types.TextMessage.fromJson(e))
            .toList();

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chat'),
    ),
    body: Chat(
      messages: _messages,
      onSendPressed: _handleSendPressed,
      user: _user,
    ),
  );
}
