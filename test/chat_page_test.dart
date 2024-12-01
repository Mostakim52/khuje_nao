import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khuje_nao/chat_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

// Mocks
class MockHttpClient extends Mock implements http.Client {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('ChatPage Tests', () {
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
    });

    test('sendMessageToServer sends a message successfully', () async {
      // Arrange
      final message = types.TextMessage(
        author: types.User(id: 'test_user'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: 'message_id',
        text: 'Hello World',
      );

      // Mock the HTTP post response
      when(() => mockHttpClient.post(
        Uri.parse('http://10.0.2.2:5000/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: any(named: 'body'),
      )).thenAnswer(
            (_) async => http.Response('{"status":"success"}', 201),
      );

      // Act
      final response = await sendMessageToServer(message, client: mockHttpClient);

      // Assert
      expect(response, 'success');
      verify(() => mockHttpClient.post(
        Uri.parse('http://10.0.2.2:5000/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: any(named: 'body'),
      )).called(1); // Verify that the HTTP post was called exactly once
    });
  });
}

// Your actual sendMessageToServer function
Future<String> sendMessageToServer(types.TextMessage message, {http.Client? client}) async {
  final response = await (client ?? http.Client()).post(
    Uri.parse('http://10.0.2.2:5000/send_message'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'text': message.text,
      'author_id': message.author.id,
      'receiver_id': 'receiver_email',  // mock or real receiver email
      'created_at': message.createdAt,
    }),
  );

  if (response.statusCode == 201) {
    return 'success';
  } else {
    throw Exception('Failed to send message');
  }
}