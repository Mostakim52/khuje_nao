import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:khuje_nao/chat_page.dart'; // ChatPage is the actual chat page widget

/// `ChatPageList` is a StatefulWidget that displays a list of ongoing chats for the current user.
/// It fetches the list of chats from the backend and navigates to the `ChatPage` when a chat is tapped.
class ChatPageList extends StatefulWidget {
  @override
  ChatPageListState createState() => ChatPageListState();
}

class ChatPageListState extends State<ChatPageList> {
  /// Secure storage used to persist data such as the user's email.
  late FlutterSecureStorage STORAGE = const FlutterSecureStorage();
  http.Client http_client = http.Client();

  /// The server URL for API requests.
  final base_url = 'https://alien-witty-monitor.ngrok-free.app';

  /// List to hold the ongoing chats fetched from the server.
  List<Map<String, dynamic>> chats = [];

  /// Loading state to show a loading indicator while fetching chat data.
  bool is_loading = true;

  /// Holds the current user's email.
  String? curren_user_email;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  // Allow mock injection via setter
  void setStorage(FlutterSecureStorage storage) {
    STORAGE = storage;
  }

  void setHttpClient(http.Client client) {
    http_client = client;
  }

  /// Fetches the list of ongoing chats from the backend.
  ///
  /// This method retrieves the current user's email from secure storage, sends a request to the backend,
  /// and populates the `chats` list with the response data.
  Future<void> fetchChats() async {
    try {
      final email = await STORAGE.read(key: "email");
      if (email != null) {
        curren_user_email = email;
        final response = await http.post(
          Uri.parse('$base_url/get_chats'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': email}),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            chats = List<Map<String, dynamic>>.from(data);
          });
        } else {
          print('Failed to fetch chats');
        }
      }
    } catch (e) {
      print('Error fetching chats: $e');
    } finally {
      setState(() {
        is_loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: is_loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final receiverEmail = chat['chat_id'];  // You can adjust how you handle the receiver here
          final latestMessage = chat['latest_message'] ?? 'No messages yet';
          final latestMessageTime = DateTime.fromMillisecondsSinceEpoch(chat['latest_message_time']);
          final formattedTime = "${latestMessageTime.hour}:${latestMessageTime.minute}";

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text("Chat with: $receiverEmail"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Latest Message: $latestMessage"),
                  Text("Sent at: $formattedTime"),
                ],
              ),
              onTap: () async {
                // Navigate to the ChatPage when this chat is tapped
                await STORAGE.write(key: "receiver_email", value: receiverEmail);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
