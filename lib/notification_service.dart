import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  // Initialize notifications
  static Future<void> initializeNotifications() async {
    AwesomeNotifications().initialize(
      // Set the icon to null if no custom icon is needed
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed){
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // Function to send a notification with two buttons
  static Future<void> sendNotification(String message, String button1Text, String button2Text) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: 'Notification',
        body: message,
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'BUTTON1',
          label: button1Text,
        ),
        NotificationActionButton(
          key: 'BUTTON2',
          label: button2Text,
        ),
      ],
    );
  }
}
