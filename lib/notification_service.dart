import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';

/// A service that handles notification operations using the Awesome Notifications package.
///
/// This class provides methods for initializing the notification system and sending
/// notifications with customizable content and action buttons.
class NotificationService {
  /// Initializes the Awesome Notifications package.
  ///
  /// This method sets up the notification system, including:
  /// - Creating a basic notification channel.
  /// - Requesting notification permissions from the user.
  ///
  /// \note This should be called during the app initialization to ensure that the
  /// notification system is ready to send notifications.
  static Future<void> initializeNotifications() async {
    AwesomeNotifications().initialize(
      /// \param icon The icon used for the notification.
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'basic_channel', ///< \brief The key identifier for the channel.
          channelName: 'Basic Notifications', ///< \brief The name displayed for the channel.
          channelDescription: 'Notification channel for basic tests',  ///< \brief Description of the channel's purpose.
          defaultColor: const Color(0xFF9D50DD), ///< \brief Default color used in notifications.
          ledColor: const Color(0xFF9D50DD), ///< \brief LED color for devices that support notification lights.
          importance: NotificationImportance.Max, ///< \brief The importance level of notifications in this channel.
          channelShowBadge: true, ///< \brief Whether to show a badge for notifications in this channel.
          playSound: true, ///< \brief Whether to play a sound when notifications arrive.
          enableVibration: true, ///< \brief Whether to vibrate when notifications arrive.
        ),
      ],
    );

    bool is_allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!is_allowed){
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  /// Sends a notification with two action buttons.
  ///
  /// [message] is the body of the notification.
  /// [button_1_Text] and [button_2_Text] are the labels for the action buttons.
  ///
  /// This method creates and sends a notification with the following:
  /// - A notification title of "Notification".
  /// - A body text defined by the [message] parameter.
  /// - Two buttons, with labels provided by the [button_1_Text] and [button_2_Text] parameters.
  ///
  /// \note This method is used to send custom notifications with interactive action buttons.
  static Future<void> sendNotification(String message, String button_1_Text, String button_2_Text) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10, ///< \brief Unique identifier for the notification.
        channelKey: 'basic_channel', ///< \brief The key of the channel to send this notification to.
        title: 'Notification', ///< \brief Title of the notification.
        body: message, ///< \brief Body content of the notification.
        notificationLayout: NotificationLayout.Default, ///< \brief Layout style of the notification.
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'BUTTON1', ///< \brief Unique key for the first action button.
          label: button_1_Text, ///< \brief Label text displayed on the first button.
        ),
        NotificationActionButton(
          key: 'BUTTON2', ///< \brief Unique key for the second action button.
          label: button_2_Text, ///< \brief Label text displayed on the second button.
        ),
      ],
    );
  }
}
