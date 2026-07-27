import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_intent.dart';
import 'device_token_service.dart';
import 'notification_navigation_service.dart';

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

  final NotificationNavigationService _navigationService =
      NotificationNavigationService.instance;

  Future<void>? _initializationFuture;

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _authenticatedSessionActive = false;

  Future<void> initialize() {
    return _initializationFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    await _initializeLocalNotifications();
    await _createAndroidNotificationChannel();

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Listener FCM foreground bermasalah: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );

    _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _dispatchRemoteMessage(
          message,
          source: NotificationOpenSource.backgroundRemoteNotification,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Listener klik FCM background bermasalah: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );

    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((
      String newToken,
    ) async {
      if (!_authenticatedSessionActive || newToken.trim().isEmpty) {
        return;
      }

      try {
        await _deviceTokenService.saveToken(newToken);
      } catch (error, stackTrace) {
        debugPrint('Gagal memperbarui token FCM: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });

    await _captureTerminatedLaunchIntent();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_attendify');

    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleRunningLocalNotificationTap,
    );
  }

  Future<void> _createAndroidNotificationChannel() async {
    if (kIsWeb || !Platform.isAndroid) {
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

  /// Dipanggil setelah login atau restore session berhasil.
  ///
  /// Proses dibuat terpisah dari bootstrap aplikasi supaya login/navigasi
  /// tidak menunggu permission dialog dan sinkronisasi token FCM.
  Future<void> activateForAuthenticatedUser() async {
    _authenticatedSessionActive = true;

    try {
      await requestPermission();
      await syncCurrentToken();
    } catch (error, stackTrace) {
      debugPrint('Aktivasi notifikasi pengguna gagal: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> requestPermission() async {
    if (kIsWeb) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted = await androidImplementation
          ?.requestNotificationsPermission();

      debugPrint('Izin notifikasi Android: $granted');
      return;
    }

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

    debugPrint('Status izin notifikasi Apple: ${settings.authorizationStatus}');
  }

  Future<void> _captureTerminatedLaunchIntent() async {
    /*
     * TERMINATED REMOTE:
     * FCM notification yang membuka aplikasi dari kondisi terminated.
     */
    final RemoteMessage? initialRemoteMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialRemoteMessage != null) {
      _dispatchRemoteMessage(
        initialRemoteMessage,
        source: NotificationOpenSource.terminatedRemoteNotification,
      );
    }

    /*
     * TERMINATED LOCAL:
     * Local notification yang pernah dibuat saat foreground, kemudian
     * ditekan ketika proses aplikasi sudah terminated.
     */
    final NotificationAppLaunchDetails? localLaunchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();

    final bool launchedByLocalNotification =
        localLaunchDetails?.didNotificationLaunchApp ?? false;

    if (!launchedByLocalNotification) {
      return;
    }

    _dispatchPayload(
      localLaunchDetails?.notificationResponse?.payload,
      source: NotificationOpenSource.terminatedLocalNotification,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM foreground diterima: ${message.messageId}');

    if (kIsWeb || !Platform.isAndroid) {
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

    final Map<String, dynamic> payloadData = Map<String, dynamic>.from(
      message.data,
    );

    if (message.messageId?.trim().isNotEmpty == true) {
      payloadData['_message_id'] = message.messageId;
    }

    final int notificationId =
        (message.messageId?.hashCode ??
                DateTime.now().microsecondsSinceEpoch.remainder(2147483647))
            .abs();

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(payloadData),
    );
  }

  void _handleRunningLocalNotificationTap(NotificationResponse response) {
    _dispatchPayload(
      response.payload,
      source: NotificationOpenSource.runningLocalNotification,
    );
  }

  void _dispatchRemoteMessage(
    RemoteMessage message, {
    required NotificationOpenSource source,
  }) {
    final NotificationIntent? intent = NotificationIntent.fromData(
      message.data,
      source: source,
      messageId: message.messageId,
    );

    if (intent == null) {
      debugPrint(
        'Payload notifikasi diabaikan karena route tidak dikenali: '
        '${message.data}',
      );
      return;
    }

    _navigationService.enqueue(intent);
  }

  void _dispatchPayload(
    String? payload, {
    required NotificationOpenSource source,
  }) {
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(payload);

      if (decoded is! Map) {
        return;
      }

      final Map<String, dynamic> data = decoded.map<String, dynamic>(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );

      final NotificationIntent? intent = NotificationIntent.fromData(
        data,
        source: source,
        messageId: data['_message_id']?.toString(),
      );

      if (intent != null) {
        _navigationService.enqueue(intent);
      }
    } catch (error, stackTrace) {
      debugPrint('Payload local notification tidak valid: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> syncCurrentToken() async {
    if (!_authenticatedSessionActive) {
      return;
    }

    try {
      final String? token = await _firebaseMessaging.getToken();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      await _deviceTokenService.saveToken(token);

      // Jangan mencetak token lengkap ke log karena token adalah identifier
      // sensitif yang dapat digunakan untuk menargetkan perangkat.
      debugPrint('Token FCM berhasil disinkronkan ke Laravel.');
    } catch (error, stackTrace) {
      debugPrint('Gagal menyinkronkan token FCM: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> removeCurrentTokenFromBackend() async {
    _authenticatedSessionActive = false;

    try {
      final String? token = await _firebaseMessaging.getToken();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      await _deviceTokenService.deleteToken(token);
    } catch (error, stackTrace) {
      debugPrint('Gagal menghapus token FCM dari backend: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> dispose() async {
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedAppSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();

    _foregroundMessageSubscription = null;
    _messageOpenedAppSubscription = null;
    _tokenRefreshSubscription = null;

    _authenticatedSessionActive = false;
    _initializationFuture = null;
  }
}
