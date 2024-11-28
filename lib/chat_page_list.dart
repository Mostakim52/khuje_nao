import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:khuje_nao/chat_page.dart'; // ChatPage is the actual chat page widget

class ChatPageList extends StatefulWidget {
  @override
  _ChatPageListState createState() => _ChatPageListState();
}

class _ChatPageListState extends State<ChatPageList> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  // Fetch the list of ongoing chats from the backend
  Future<void> _fetchChats() async {
    try {
      final email = await _storage.read(key: "email");
      if (email != null) {
        _currentUserEmail = email;
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/get_chats'),
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
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: isLoading
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
                await _storage.write(key: "receiver_email", value: receiverEmail);
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
