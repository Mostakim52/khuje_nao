import 'package:flutter_test/flutter_test.dart';
import 'package:khuje_nao/api_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Create a Mock class for the http.Client
class MockClient extends Mock implements http.Client {}

void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockClient mockClient;

    // Set up the mock client before each test
    setUp(() {
      mockClient = MockClient();
      apiService = ApiService(); // ApiService uses real http requests by default.
    });

    test('signup returns -1 for invalid name', () async {
      // Arrange
      String invalidName = "o";
      String email = "test@example.com";
      String password = "Password123";
      int nsuId = 123456;
      String phoneNumber = "0123456789";

      // Act
      int result = await apiService.signup(invalidName, email, password, nsuId, phoneNumber);

      // Assert
      expect(result, -1);
    });

    test('signup returns -2 for invalid email', () async {
      // Arrange
      String name = "John Doe";
      String invalidEmail = "invalid-email";
      String password = "Password123";
      int nsuId = 123456;
      String phoneNumber = "0123456789";

      // Act
      int result = await apiService.signup(name, invalidEmail, password, nsuId, phoneNumber);

      // Assert
      expect(result, -2);
    });

    test('signup returns -3 for invalid password', () async {
      // Arrange
      String name = "John Doe";
      String email = "john.doe@example.com";
      String invalidPassword = "password";
      int nsuId = 123456;
      String phoneNumber = "0123456789";

      // Act
      int result = await apiService.signup(name, email, invalidPassword, nsuId, phoneNumber);

      // Assert
      expect(result, -3);
    });

    test('signup returns -4 for invalid NSU ID', () async {
      // Arrange
      String name = "John Doe";
      String email = "john.doe@example.com";
      String password = "Password123";
      int invalidNsuId = 12345; // Invalid NSU ID (less than 8 digits)
      String phoneNumber = "0123456789";

      // Act
      int result = await apiService.signup(name, email, password, invalidNsuId, phoneNumber);

      // Assert
      expect(result, -4);
    });

    test('signup returns -5 for invalid phone number', () async {
      // Arrange
      String name = "John Doe";
      String email = "john.doe@example.com";
      String password = "Password123";
      int nsuId = 1234567;
      String invalidPhoneNumber = "12345"; // Invalid phone number

      // Act
      int result = await apiService.signup(name, email, password, nsuId, invalidPhoneNumber);

      // Assert
      expect(result, -5);
    });

    test('signup returns 0 for successful signup', () async {
      // Arrange: Mock successful API response
      when(() => mockClient.post(
        Uri.parse('http://10.0.2.2:5000/signup'),
        headers: {"Content-Type": "application/json"},
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{"message": "Success"}', 201));

      // Act
      String name = "John Doe";
      String email = "john.doe@example.com";
      String password = "Password123";
      int nsuId = 1234567;
      String phoneNumber = "01319675674";

      int result = await apiService.signup(name, email, password, nsuId, phoneNumber);

      // Assert
      expect(result, 0);
    });

    test('signup returns -6 for failed signup', () async {
      // Arrange: Mock failed API response
      when(() => mockClient.post(
        Uri.parse('http://10.0.2.2:5000/signup'),
        headers: {"Content-Type": "application/json"},
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{"message": "Failed"}', 400));

      // Act
      String name = "John Doe";
      String email = "john.doe@example.com";
      String password = "Password123";
      int nsuId = 1234567;
      String phoneNumber = "01314567894";

      int result = await apiService.signup(name, email, password, nsuId, phoneNumber);

      // Assert
      expect(result, -6);
    });

    test('login returns -1 for invalid email', () async {
      // Arrange: Simulate an invalid email
      String invalidEmail = "invalid-email";
      String password = "Password123";

      // Act: Call login method
      int result = await apiService.login(invalidEmail, password);

      // Assert: Expect -1 for invalid email
      expect(result, -1);
    });

    test('login returns -2 for invalid password', () async {
      // Arrange: Simulate an invalid password
      String email = "john.doe@example.com";
      String invalidPassword = "password";

      // Act: Call login method
      int result = await apiService.login(email, invalidPassword);

      // Assert: Expect -2 for invalid password
      expect(result, -2);
    });

    test('login returns 0 for successful login', () async {
      // Arrange: Mock successful login response
      when(() => mockClient.post(
        Uri.parse('http://10.0.2.2:5000/login'),
        headers: {"Content-Type": "application/json"},
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{"email": "john.doe@example.com"}', 200));

      // Act: Call login method
      String email = "john.doe@example.com";
      String password = "Password123";

      int result = await apiService.login(email, password);

      // Assert: Expect 0 for successful login
      expect(result, 0);
    });

    test('login returns -9 for failed login', () async {
      // Arrange: Mock failed login response
      when(() => mockClient.post(
        Uri.parse('http://10.0.2.2:5000/login'),
        headers: {"Content-Type": "application/json"},
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{"message": "Failed"}', 400));

      // Act: Call login method
      String email = "john.doe@example.com";
      String password = "Password123";

      int result = await apiService.login(email, password);

      // Assert: Expect -9 for failed login
      expect(result, -9);
    });
  });
}
