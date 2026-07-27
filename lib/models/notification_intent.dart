import 'package:flutter/foundation.dart';

enum NotificationDestination { attendance }

enum NotificationOpenSource {
  /// Pengguna menekan local notification saat proses aplikasi masih hidup.
  runningLocalNotification,

  /// Pengguna menekan FCM notification ketika aplikasi berada di background.
  backgroundRemoteNotification,

  /// Pengguna menekan FCM notification ketika aplikasi benar-benar terminated.
  terminatedRemoteNotification,

  /// Pengguna menekan local notification ketika aplikasi terminated.
  terminatedLocalNotification,
}

@immutable
class NotificationIntent {
  const NotificationIntent({
    required this.id,
    required this.destination,
    required this.source,
    required this.data,
  });

  final String id;
  final NotificationDestination destination;
  final NotificationOpenSource source;
  final Map<String, dynamic> data;

  static NotificationIntent? fromData(
    Map<String, dynamic> rawData, {
    required NotificationOpenSource source,
    String? messageId,
  }) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);

    final String route = data['route']?.toString().trim().toLowerCase() ?? '';

    final NotificationDestination? destination = switch (route) {
      'attendance' => NotificationDestination.attendance,
      _ => null,
    };

    if (destination == null) {
      return null;
    }

    final String resolvedId = messageId?.trim().isNotEmpty == true
        ? messageId!.trim()
        : data['_message_id']?.toString().trim().isNotEmpty == true
        ? data['_message_id'].toString().trim()
        : [
            source.name,
            route,
            data['type']?.toString() ?? '',
            data['date']?.toString() ?? '',
            data['attendance_id']?.toString() ?? '',
            data['employee_id']?.toString() ?? '',
          ].join(':');

    return NotificationIntent(
      id: resolvedId,
      destination: destination,
      source: source,
      data: Map<String, dynamic>.unmodifiable(data),
    );
  }
}
