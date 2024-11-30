import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async'; //# For periodic updates

/// The `ChatPage` widget provides the interface for real-time communication between users.
/// It handles message sending, message retrieval, and periodic refresh of messages.
class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  /// List of messages to display in the chat.
  List<types.Message> messages = [];

  /// Secure storage for user data (e.g., email, receiver email).
  final STORAGE = const FlutterSecureStorage();

  /// The server URL for API requests.
  final server_url = 'http://10.0.2.2:5000';

  /// The current user.
  late types.User user;

  /// The email of the person being messaged (receiver).
  String current_receiver = '';

  /// Loading indicator for the page.
  bool is_loading = true;

  /// Timer to periodically refresh messages.
  Timer? message_timer;

  @override
  void initState() {
    super.initState();
    initializeUser();
  }

  @override
  void dispose() {
    message_timer?.cancel(); //# Cancel the timer when the widget is disposed
    super.dispose();
  }

  /// Initializes the user and loads messages.
  ///
  /// This method retrieves the user and receiver email from secure storage,
  /// sets up the user information, and starts the periodic message refresh.
  Future<void> initializeUser() async {
    try {
      final email = await STORAGE.read(key: "email");
      final receiverEmail = await STORAGE.read(key: "receiver_email");

      if (email != null && receiverEmail != null) {
        setState(() {
          user = types.User(
            id: email,
            firstName: email.split('@').first,
          );
          current_receiver = receiverEmail;
          is_loading = false;
        });

        loadMessages(); // Initial message load
        startMessageRefresh(); // Start periodic refresh
      } else {
        throw Exception("User or receiver email not found in storage.");
      }
    } catch (e) {
      print("Error initializing chat: $e");
      setState(() {
        is_loading = false;
      });
    }
  }

  /// Starts periodic message refresh every 5 seconds.
  ///
  /// This method uses a timer to automatically refresh the messages at a regular interval.
  void startMessageRefresh() {
    message_timer = Timer.periodic(Duration(seconds: 5), (timer) {
      loadMessages();
    });
  }

  /// Adds a new message to the chat UI.
  ///
  /// [message] The message object that will be inserted at the top of the messages list.
  void addMessage(types.Message message) {
    setState(() {
      messages.insert(0, message);
    });
  }

  /// Handles the send button press by sending the message to the server.
  ///
  /// [message] The message content (partial text) to be sent.
  void handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    addMessage(textMessage);
    await sendMessageToServer(textMessage);
  }

  /// Sends the message to the server.
  ///
  /// [message] The message to be sent to the server.
  Future<void> sendMessageToServer(types.TextMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('$server_url/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': message.text,
          'author_id': message.author.id,
          'receiver_id': current_receiver,
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

  /// Loads messages from the server based on the current user and receiver.
  Future<void> loadMessages() async {
    try {
      final response = await http.post(
        Uri.parse('$server_url/get_messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'author_id': user.id,
          'receiver_id': current_receiver,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final loaded_messages = responseData.map((message) {
          return types.TextMessage(
            id: message['_id'] ?? '',
            author: types.User(id: message['author_id']),
            createdAt: message['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
            text: message['text'] ?? '',
          );
        }).toList();

        setState(() {
          messages = loaded_messages;
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
    if (is_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ' + current_receiver),
      ),
      body: Chat(
        messages: messages,
        onSendPressed: handleSendPressed,
        user: user,
      ),
    );
  }
}
