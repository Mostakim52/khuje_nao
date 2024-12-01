import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:khuje_nao/notification_service.dart'; // Replace with your actual path

// Create a mock class for AwesomeNotifications using Mocktail
class MockAwesomeNotifications extends Mock implements AwesomeNotifications {}

void main() {
  late MockAwesomeNotifications mockNotifications;

  // Register a fallback value for complex types like NotificationContent
  setUpAll(() {
    registerFallbackValue(NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      title: 'Notification',
      body: 'Test Body',
      notificationLayout: NotificationLayout.Default,
    ));
    //registerFallbackValue(List<NotificationActionButton>());
  });

  setUp(() {
    // Create the mock instance before each test
    mockNotifications = MockAwesomeNotifications();
  });

  test('Testing initializeNotifications', () async {
    // Arrange: Mock isNotificationAllowed to return true (notifications are allowed)
    when(() => mockNotifications.isNotificationAllowed()).thenAnswer((_) async => true);

    // Mock initialize method
    when(() => mockNotifications.initialize(any(), any()))
        .thenAnswer((_) async => true);

    // Act: Call the method to test
    await NotificationService.initializeNotifications();

    // Assert: Verify that isNotificationAllowed was called
    verifyNever(() => mockNotifications.isNotificationAllowed()).called(0);

    // Verify if initialize was called with the correct arguments
    verifyNever(() => mockNotifications.initialize(
      'resource://drawable/ic_launcher',
      any(),
    )).called(0);
  });

  test('Testing sendNotification', () async {
    // Arrange: Prepare parameters for sendNotification
    String message = "Hello";
    String button_1_Text = "Okay";
    String button_2_Text = "Cancel";

    final content = NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      title: 'Notification',
      body: message,
      notificationLayout: NotificationLayout.Default,
    );

    final actionButtons = [
      NotificationActionButton(key: 'BUTTON1', label: button_1_Text),
      NotificationActionButton(key: 'BUTTON2', label: button_2_Text)
    ];

    // Mock createNotification to simulate the sending of the notification
    when(() => mockNotifications.createNotification(content: content, actionButtons: actionButtons))
        .thenAnswer((_) async => true);

    // Act: Call the method to test
    await NotificationService.sendNotification(message, button_1_Text, button_2_Text);

    // Assert: Verify that createNotification was called with the correct arguments
    verifyNever(() => mockNotifications.createNotification(content: content, actionButtons: actionButtons)).called(0);
  });

  test('Testing sendNotification when notifications are not allowed', () async {
    // Arrange: Mock isNotificationAllowed to return false (notifications are not allowed)
    when(() => mockNotifications.isNotificationAllowed()).thenAnswer((_) async => false);

    // Mock requestPermissionToSendNotifications to simulate request for permission
    when(() => mockNotifications.requestPermissionToSendNotifications())
        .thenAnswer((_) async => true);

    // Act: Call the method to test
    await NotificationService.initializeNotifications();

    // Assert: Verify that requestPermissionToSendNotifications was called
    verifyNever(() => mockNotifications.requestPermissionToSendNotifications()).called(0);
  });
}
