// lib/services/notification_navigation_service.dart

import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart'; // <-- TAMBAHKAN IMPORT INI untuk WidgetsBinding
import '../models/notification_intent.dart';

/// Menjembatani event klik notifikasi dengan layer navigasi aplikasi.
///
/// Service ini tidak memegang BuildContext dan tidak melakukan Navigator.push.
/// Intent disimpan apabila UI atau sesi pengguna belum siap, kemudian dikirim
/// setelah MainScreen menjadi consumer aktif.
class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  final StreamController<NotificationIntent> _controller =
      StreamController<NotificationIntent>.broadcast(sync: true);

  final Queue<NotificationIntent> _pendingIntents = Queue<NotificationIntent>();

  final Set<String> _knownIntentIds = <String>{};

  bool _consumerReady = false;
  bool _flushScheduled = false;

  Stream<NotificationIntent> get intents => _controller.stream;

  void enqueue(NotificationIntent intent) {
    if (!_knownIntentIds.add(intent.id)) {
      return;
    }

    if (!_consumerReady) {
      _pendingIntents.addLast(intent);
      return;
    }

    _emitWhenReady(intent);
  }

  /// Mengembalikan intent ke antrean tanpa dianggap sebagai notifikasi baru.
  /// Dipakai untuk mengatasi race condition apabila sesi berubah saat intent
  /// baru saja dikirim ke UI.
  void defer(NotificationIntent intent) {
    _consumerReady = false;
    _pendingIntents.addFirst(intent);
  }

  void markConsumerReady() {
    _consumerReady = true;
    _scheduleFlush();
  }

  void markConsumerNotReady() {
    _consumerReady = false;
  }

  void clearPending() {
    _pendingIntents.clear();
  }

  void _scheduleFlush() {
    if (_flushScheduled) {
      return;
    }

    _flushScheduled = true;

    // ---------------------------------------------------------
    // PERUBAHAN: Gunakan addPostFrameCallback agar flush
    // menunggu widget tree / UI selesai dirender
    // ---------------------------------------------------------
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushScheduled = false;

      if (!_consumerReady || _controller.isClosed) {
        return;
      }

      while (_consumerReady && _pendingIntents.isNotEmpty) {
        _controller.add(_pendingIntents.removeFirst());
      }
    });
  }

  void _emitWhenReady(NotificationIntent intent) {
    // ---------------------------------------------------------
    // PERUBAHAN: Sama seperti di atas, gunakan addPostFrameCallback
    // ---------------------------------------------------------
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.isClosed) {
        return;
      }

      if (!_consumerReady) {
        _pendingIntents.addFirst(intent);
        return;
      }

      _controller.add(intent);
    });
  }
}
