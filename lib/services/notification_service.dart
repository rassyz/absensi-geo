import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'device_token_service.dart';

enum NotificationDestination { attendance }

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String channelId = 'attendance_reminder';
  static const String channelName = 'Pengingat Presensi';
  static const String channelDescription =
      'Notifikasi pengingat presensi masuk dan keluar.';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final DeviceTokenService _deviceTokenService = DeviceTokenService();

  final StreamController<NotificationDestination> _navigationController =
      StreamController<NotificationDestination>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _initialized = false;

  Stream<NotificationDestination> get navigationRequests =>
      _navigationController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await _requestPermission();
    await _initializeLocalNotifications();
    await _createAndroidNotificationChannel();

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    /*
     * Foreground:
     * pesan ditampilkan sebagai local notification.
     */
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM foreground diterima: ${message.messageId}');
      await _showForegroundNotification(message);
    });

    /*
     * Background:
     * event hanya diproses saat aplikasi sudah hidup dan MainScreen
     * sudah berada di widget tree.
     *
     * Terminated tidak diproses di sini. Android hanya membuka aplikasi,
     * lalu aplikasi menjalankan SplashScreen normal.
     */
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((
      String newToken,
    ) async {
      try {
        await _deviceTokenService.saveToken(newToken);
      } catch (error) {
        debugPrint('Gagal memperbarui token FCM: $error');
      }
    });
  }

  Future<void> _requestPermission() async {
    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

    debugPrint('Status izin notifikasi: ${settings.authorizationStatus}');

    if (!Platform.isAndroid) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool? granted = await androidImplementation
        ?.requestNotificationsPermission();

    debugPrint('Izin notifikasi Android: $granted');
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_attendify');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        /*
         * Callback ini dipakai ketika aplikasi masih hidup.
         * Untuk launch terminated dari local notification, aplikasi tetap
         * dibiarkan menjalankan SplashScreen normal.
         */
        _handleLocalNotificationPayload(response.payload);
      },
    );
  }

  Future<void> _createAndroidNotificationChannel() async {
    if (!Platform.isAndroid) {
      return;
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.createNotificationChannel(channel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!Platform.isAndroid) {
      return;
    }

    final RemoteNotification? remoteNotification = message.notification;

    final String title =
        remoteNotification?.title ??
        message.data['title']?.toString() ??
        'Pengingat Presensi';

    final String body =
        remoteNotification?.body ??
        message.data['body']?.toString() ??
        'Silakan periksa data presensi Anda.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_attendify',
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final int notificationId =
        (message.messageId?.hashCode ??
                DateTime.now().millisecondsSinceEpoch.remainder(100000))
            .abs();

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  void _handleLocalNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        _handleNotificationData(decoded);
        return;
      }

      if (decoded is Map) {
        final Map<String, dynamic> data = decoded.map<String, dynamic>(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        );

        _handleNotificationData(data);
      }
    } catch (_) {
      if (payload == 'attendance') {
        _navigationController.add(NotificationDestination.attendance);
      }
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final String route = data['route']?.toString().trim() ?? '';

    if (route == 'attendance') {
      _navigationController.add(NotificationDestination.attendance);
    }
  }

  Future<void> syncCurrentToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();

      debugPrint('FCM token: $token');

      if (token == null || token.trim().isEmpty) {
        return;
      }

      await _deviceTokenService.saveToken(token);

      debugPrint('FCM token berhasil dikirim ke Laravel.');
    } catch (error, stackTrace) {
      debugPrint('Gagal menyinkronkan FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> removeCurrentTokenFromBackend() async {
    try {
      final String? token = await _firebaseMessaging.getToken();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      await _deviceTokenService.deleteToken(token);
    } catch (error) {
      debugPrint('Gagal menghapus token FCM: $error');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _initialized = false;
  }
}
