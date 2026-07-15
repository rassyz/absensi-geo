// lib/providers/employee_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_logger.dart';
import '../services/employee_service.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeService _service = EmployeeService();

  List<Map<String, dynamic>> _teamMembers = [];

  // Cache dipisahkan berdasarkan:
  // employeeId - tahun - bulan
  final Map<String, List<Map<String, dynamic>>> _memberAttendances = {};

  // Menyimpan request yang sedang berjalan agar request sama
  // tidak dikirim dua kali.
  final Map<String, Future<void>> _attendanceRequests = {};

  // Loading dibuat spesifik untuk setiap periode presensi.
  final Set<String> _loadingAttendanceKeys = {};

  bool _isLoading = false;
  int _cacheGeneration = 0;

  List<Map<String, dynamic>> get teamMembers => _teamMembers;

  bool get isLoading => _isLoading;

  // Dipertahankan untuk kompatibilitas dengan kode lama.
  bool get isLoadingAttendances => _loadingAttendanceKeys.isNotEmpty;

  String _attendanceKey(int employeeId, int month, int year) {
    return '$employeeId-$year-$month';
  }

  int? _parseEmployeeId(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  List<Map<String, dynamic>> getAttendances(
    int employeeId, {
    int? month,
    int? year,
  }) {
    final now = DateTime.now();

    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    final key = _attendanceKey(employeeId, selectedMonth, selectedYear);

    return _memberAttendances[key] ?? [];
  }

  bool hasAttendanceCache(int employeeId, {int? month, int? year}) {
    final now = DateTime.now();

    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    final key = _attendanceKey(employeeId, selectedMonth, selectedYear);

    return _memberAttendances.containsKey(key);
  }

  bool isLoadingAttendancesFor(int employeeId, {int? month, int? year}) {
    final now = DateTime.now();

    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    final key = _attendanceKey(employeeId, selectedMonth, selectedYear);

    return _loadingAttendanceKeys.contains(key);
  }

  // Mengambil daftar anggota tim.
  Future<void> fetchTeams() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    bool successfullyLoaded = false;

    try {
      _teamMembers = await _service.fetchTeamMembers();
      successfullyLoaded = true;
    } catch (e) {
      AppLogger.error('Error Provider Teams', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Setelah daftar anggota muncul, muat presensi bulan berjalan
    // secara bertahap di background.
    if (successfullyLoaded && _teamMembers.isNotEmpty) {
      unawaited(preloadCurrentMonthAttendances());
    }
  }

  Future<void> fetchAttendances(
    int employeeId, {
    int? month,
    int? year,
    bool forceRefresh = false,
    bool silent = false,
  }) {
    final now = DateTime.now();

    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    final key = _attendanceKey(employeeId, selectedMonth, selectedYear);

    // Jangan mengambil ulang apabila cache sudah tersedia.
    if (!forceRefresh && _memberAttendances.containsKey(key)) {
      return Future<void>.value();
    }

    // Jangan mengirim request yang sama dua kali.
    final existingRequest = _attendanceRequests[key];

    if (existingRequest != null) {
      return existingRequest;
    }

    final generationAtRequest = _cacheGeneration;

    final request = _loadAttendances(
      employeeId: employeeId,
      month: selectedMonth,
      year: selectedYear,
      cacheKey: key,
      generationAtRequest: generationAtRequest,
      silent: silent,
    );

    _attendanceRequests[key] = request;

    unawaited(
      request.whenComplete(() {
        _attendanceRequests.remove(key);
      }),
    );

    return request;
  }

  Future<void> _loadAttendances({
    required int employeeId,
    required int month,
    required int year,
    required String cacheKey,
    required int generationAtRequest,
    required bool silent,
  }) async {
    _loadingAttendanceKeys.add(cacheKey);

    if (!silent) {
      notifyListeners();
    }

    try {
      final data = await _service.fetchMemberAttendances(
        employeeId: employeeId,
        month: month,
        year: year,
      );

      // Mencegah request lama memasukkan data kembali setelah logout.
      if (generationAtRequest != _cacheGeneration) {
        return;
      }

      _memberAttendances[cacheKey] = data;
    } catch (e) {
      AppLogger.error('Error Provider Attendance', error: e);
    } finally {
      _loadingAttendanceKeys.remove(cacheKey);
      notifyListeners();
    }
  }

  // Memuat presensi bulan berjalan sebelum pengguna membuka
  // halaman detail. Request dibatasi per batch agar server tidak
  // menerima terlalu banyak request sekaligus.
  Future<void> preloadCurrentMonthAttendances({int batchSize = 4}) async {
    if (_teamMembers.isEmpty) {
      return;
    }

    final now = DateTime.now();

    final employeeIds = _teamMembers
        .map((employee) => _parseEmployeeId(employee['id']))
        .whereType<int>()
        .toList();

    for (int index = 0; index < employeeIds.length; index += batchSize) {
      final endIndex = (index + batchSize < employeeIds.length)
          ? index + batchSize
          : employeeIds.length;

      final batch = employeeIds.sublist(index, endIndex);

      await Future.wait(
        batch.map(
          (employeeId) => fetchAttendances(
            employeeId,
            month: now.month,
            year: now.year,
            silent: true,
          ),
        ),
      );
    }
  }

  void clearAttendanceCache({int? employeeId}) {
    if (employeeId == null) {
      _memberAttendances.clear();
      notifyListeners();
      return;
    }

    _memberAttendances.removeWhere(
      (key, value) => key.startsWith('$employeeId-'),
    );

    notifyListeners();
  }

  void reset() {
    _cacheGeneration++;

    _teamMembers = [];
    _memberAttendances.clear();
    _attendanceRequests.clear();
    _loadingAttendanceKeys.clear();

    _isLoading = false;

    notifyListeners();
  }
}
