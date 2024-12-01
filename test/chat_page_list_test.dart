import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khuje_nao/chat_page_list.dart'; // Import the file containing your ChatPageListState class
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends Mock implements http.Client {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  // Define the mock instances
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockHttpClient mockHttpClient;
  late MockFlutterSecureStorage mockStorage;
  late ChatPageListState chatPageListState;

  // Setup before each test
  setUp(() {
    mockHttpClient = MockHttpClient();
    mockStorage = MockFlutterSecureStorage();
    chatPageListState = ChatPageListState();
    registerFallbackValue(Uri.parse('http://example.com'));
    registerFallbackValue(http.Response('{"chat_id": "user1", "latest_message": "Hello"}', 200));
  });

  // Test for missing email in secure storage
  test('fetchChats handles missing email in storage', () async {
    // Arrange: Mock the storage to return null for the email
    when(() => mockStorage.read(key: 'email')).thenAnswer((_) async => null);

    // Act: Call the fetchChats method
    await chatPageListState.fetchChats();

    // Assert: Verify that the fetchChats method handles missing email correctly
    expect(chatPageListState.is_loading, false);
    expect(chatPageListState.chats, []);
  });

  // Test for successful fetching of chats when email is available
  test('fetchChats fetches chats successfully when email is available', () async {
    // Arrange: Mock the storage and HTTP response
    when(() => mockStorage.read(key: 'email')).thenAnswer((_) async => 'test@example.com');

    final mockResponse = jsonEncode([
      {'chat_id': 'receiver@example.com', 'latest_message': 'Hello!', 'latest_message_time': 1629803797000},
      {'chat_id': 'friend@example.com', 'latest_message': 'Hey!', 'latest_message_time': 1629803807000}
    ]);

    when(() => mockHttpClient.post(
      Uri.parse('http://10.0.2.2:5000/get_chats'),
      headers: {'Content-Type': 'application/json'},
      body: any(named: 'body'),
    )).thenAnswer((_) async => http.Response(mockResponse, 200));

    // Act: Call fetchChats to fetch chats
    await chatPageListState.fetchChats();

    // Assert: Verify that the chats are populated with mock data
    expect(chatPageListState.chats.length, 2);
    expect(chatPageListState.chats[0]['chat_id'], 'receiver@example.com');
    expect(chatPageListState.chats[1]['chat_id'], 'friend@example.com');
  });

  // Test for failed HTTP response
  test('fetchChats handles failed response', () async {
    // Arrange: Mock the storage and failed HTTP response
    when(() => mockStorage.read(key: 'email')).thenAnswer((_) async => 'test@example.com');

    when(() => mockHttpClient.post(
      Uri.parse('http://10.0.2.2:5000/get_chats'),
      headers: {'Content-Type': 'application/json'},
      body: any(named: 'body'),
    )).thenAnswer((_) async => http.Response('Failed', 400)); // Simulating failure

    // Act: Call fetchChats
    await chatPageListState.fetchChats();

    // Assert: Verify that chats are not updated due to failure and is_loading is false
    expect(chatPageListState.chats, []);
  });
}
