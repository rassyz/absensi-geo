// lib/screens/attendance_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:absensi_geo/providers/attendance_update_provider.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/services/attendance_service.dart';
import 'package:absensi_geo/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/utils/app_logger.dart';
import '../core/utils/app_message.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceZoneMapData {
  const _AttendanceZoneMapData({
    required this.id,
    required this.name,
    required this.points,
  });

  final int id;
  final String name;
  final List<LatLng> points;

  LatLng get center {
    if (points.isEmpty) {
      return const LatLng(-6.200000, 106.816666);
    }

    double latitudeTotal = 0;
    double longitudeTotal = 0;

    for (final point in points) {
      latitudeTotal += point.latitude;
      longitudeTotal += point.longitude;
    }

    return LatLng(
      latitudeTotal / points.length,
      longitudeTotal / points.length,
    );
  }
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationValidationDebounce;

  File? _capturedImage;
  Position? _latestPosition;

  // --- Dynamic Map State Variables ---
  List<_AttendanceZoneMapData> _attendanceZones = [];
  LatLng? _officeLocation;
  LatLng? _userLocation;
  bool _isLoadingMap = true;

  // --- Real-Time Attendance State ---
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  String _checkInTime = '-- : -- : --';
  String _checkOutTime = '-- : -- : --';

  // --- Attendance Blocking State ---
  bool _isAttendanceBlocked = false;
  String? _attendanceBlockedStatus;
  String _attendanceBlockedMessage = '';

  // --- Real-Time Location Validation State ---
  bool _isLocationValid = false;
  bool _isFakeGpsDetected = false;
  bool _isValidatingLocation = true;
  bool _isProcessingAttendance = false;
  int _locationValidationRequestId = 0;

  String _locationStatusCode = 'loading';
  String _locationStatusMessage = 'Mencari lokasi terkini...';

  @override
  void initState() {
    super.initState();
    _initializeAttendanceData();
  }

  @override
  void dispose() {
    _locationValidationDebounce?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAttendanceData() async {
    await _fetchTodayStatus();

    try {
      await _fetchAttendanceZone();
    } catch (e) {
      AppLogger.error('API Zone Error', error: e);
    }

    if (mounted) {
      setState(() {
        _officeLocation ??= const LatLng(
          -6.162709797692463,
          106.64946673441781,
        );
        _isLoadingMap = false;
      });
    }

    if (_isAttendanceBlocked) {
      return;
    }

    try {
      await _startRealtimeLocationMonitoring();
    } catch (e) {
      AppLogger.error('GPS Error', error: e);

      if (!mounted) return;

      setState(() {
        _isLocationValid = false;
        _isFakeGpsDetected = false;
        _isValidatingLocation = false;
        _locationStatusCode = 'location_error';
        _locationStatusMessage = AppMessage.toIndonesia(e);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppMessage.toIndonesia(e)),
          backgroundColor: AppColors.tertiary[500],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _fetchTodayStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token != null) {
      final statusData = await _attendanceService.getTodayAttendanceStatus(
        token,
      );

      if (statusData != null && statusData['success'] == true && mounted) {
        setState(() {
          _hasCheckedIn = statusData['has_checked_in'] ?? false;
          _hasCheckedOut = statusData['has_checked_out'] ?? false;
          _isAttendanceBlocked = statusData['is_attendance_blocked'] == true;
          _attendanceBlockedStatus = statusData['attendance_status']
              ?.toString();
          _attendanceBlockedMessage =
              statusData['attendance_message']?.toString() ?? '';

          _checkInTime =
              statusData['check_in_time']?.toString() ?? '-- : -- : --';
          _checkOutTime =
              statusData['check_out_time']?.toString() ?? '-- : -- : --';

          if (_isAttendanceBlocked) {
            _isLocationValid = false;
            _isFakeGpsDetected = false;
            _isValidatingLocation = false;
            _locationStatusCode = 'attendance_blocked';
            _locationStatusMessage = _attendanceBlockedMessage.isNotEmpty
                ? _attendanceBlockedMessage
                : 'Presensi hari ini tidak tersedia.';
          }
        });
      }
    }
  }

  Future<void> _fetchAttendanceZone() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null || token.isEmpty) return;

    final zonesData = await _attendanceService.getUserAttendanceZones(token);

    final parsedZones = zonesData
        .map<_AttendanceZoneMapData?>((zone) {
          final String area = zone['area']?.toString() ?? '';
          final List<LatLng> points = _parseWktPolygon(area);

          if (points.isEmpty) return null;

          return _AttendanceZoneMapData(
            id: _parseZoneId(zone['id']),
            name: zone['name']?.toString() ?? 'Zona Presensi',
            points: points,
          );
        })
        .whereType<_AttendanceZoneMapData>()
        .toList();

    if (!mounted) return;

    final allPoints = parsedZones
        .expand<LatLng>((zone) => zone.points)
        .toList();

    setState(() {
      _attendanceZones = parsedZones;

      if (allPoints.isNotEmpty) {
        _officeLocation = _getPointsCenter(allPoints);
      }
    });
  }

  Future<void> _startRealtimeLocationMonitoring() async {
    await _ensureLocationReady();

    final Position initialPosition = await _getFreshPosition();
    _handleRealtimePosition(initialPosition, validateImmediately: true);

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );

    await _positionSubscription?.cancel();

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            _handleRealtimePosition(position);
          },
          onError: (Object error) {
            if (!mounted) return;

            setState(() {
              _isLocationValid = false;
              _isFakeGpsDetected = false;
              _isValidatingLocation = false;
              _locationStatusCode = 'location_error';
              _locationStatusMessage = AppMessage.toIndonesia(error);
            });
          },
        );
  }

  void _handleRealtimePosition(
    Position position, {
    bool validateImmediately = false,
  }) {
    if (!mounted) return;

    _latestPosition = position;

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    if (_isAttendanceBlocked) {
      _applyAttendanceBlockedStatus();
      return;
    }

    if (position.isMocked) {
      _setFakeGpsStatus();
      return;
    }

    _scheduleLocationValidation(
      position,
      validateImmediately: validateImmediately,
    );
  }

  void _scheduleLocationValidation(
    Position position, {
    bool validateImmediately = false,
  }) {
    _locationValidationDebounce?.cancel();

    if (validateImmediately) {
      _validateRealtimeLocation(position);
      return;
    }

    _locationValidationDebounce = Timer(
      const Duration(seconds: 1),
      () => _validateRealtimeLocation(position),
    );
  }

  Future<void> _validateRealtimeLocation(Position position) async {
    if (!mounted) return;

    if (_isAttendanceBlocked) {
      _applyAttendanceBlockedStatus();
      return;
    }

    if (position.isMocked) {
      _setFakeGpsStatus();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLocationValid = false;
        _isFakeGpsDetected = false;
        _isValidatingLocation = false;
        _locationStatusCode = 'location_error';
        _locationStatusMessage =
            'Sesi login tidak ditemukan. Silakan login ulang.';
      });
      return;
    }

    final int requestId = ++_locationValidationRequestId;

    setState(() {
      _isFakeGpsDetected = false;
      _isValidatingLocation = true;
      _locationStatusCode = 'loading';
      _locationStatusMessage = 'Memvalidasi lokasi terkini...';
    });

    try {
      final result = await _attendanceService.validateAttendanceLocation(
        token: token,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted || requestId != _locationValidationRequestId) return;

      _applyLocationValidationResult(result);
    } catch (e) {
      if (!mounted || requestId != _locationValidationRequestId) return;

      setState(() {
        _isLocationValid = false;
        _isFakeGpsDetected = false;
        _isValidatingLocation = false;
        _locationStatusCode = 'location_error';
        _locationStatusMessage = AppMessage.toIndonesia(e);
      });
    }
  }

  void _applyLocationValidationResult(Map<String, dynamic> result) {
    if (!mounted) return;

    final bool isAttendanceBlocked = result['is_attendance_blocked'] == true;
    final String status =
        result['location_status']?.toString() ?? 'outside_area';
    final bool isValid = result['is_valid'] == true;
    final String message =
        result['message']?.toString() ??
        (isValid
            ? 'Lokasi berada di area presensi.'
            : 'Lokasi berada di luar area presensi.');

    setState(() {
      if (isAttendanceBlocked) {
        _isAttendanceBlocked = true;
        _attendanceBlockedStatus = result['attendance_status']?.toString();
        _attendanceBlockedMessage = message;
        _isLocationValid = false;
        _isFakeGpsDetected = false;
        _isValidatingLocation = false;
        _locationStatusCode = 'attendance_blocked';
        _locationStatusMessage = message;
        return;
      }

      _isLocationValid = isValid;
      _isFakeGpsDetected = false;
      _isValidatingLocation = false;
      _locationStatusCode = status;
      _locationStatusMessage = message;
    });
  }

  void _applyAttendanceBlockedStatus() {
    _locationValidationDebounce?.cancel();
    _locationValidationRequestId++;

    if (!mounted) return;

    setState(() {
      _isLocationValid = false;
      _isFakeGpsDetected = false;
      _isValidatingLocation = false;
      _locationStatusCode = 'attendance_blocked';
      _locationStatusMessage = _attendanceBlockedMessage.isNotEmpty
          ? _attendanceBlockedMessage
          : 'Presensi hari ini tidak tersedia.';
    });
  }

  void _setFakeGpsStatus() {
    _locationValidationDebounce?.cancel();
    _locationValidationRequestId++;

    if (!mounted) return;

    setState(() {
      _isLocationValid = false;
      _isFakeGpsDetected = true;
      _isValidatingLocation = false;
      _locationStatusCode = 'fake_gps';
      _locationStatusMessage = 'Fake GPS terdeteksi.';
    });
  }

  Future<Map<String, dynamic>> _validatePositionBeforeAction(
    String token,
    Position position,
  ) async {
    if (_isAttendanceBlocked) {
      _applyAttendanceBlockedStatus();

      return {
        'success': true,
        'is_valid': false,
        'location_status': 'attendance_blocked',
        'message': _locationStatusMessage,
        'is_attendance_blocked': true,
        'attendance_status': _attendanceBlockedStatus,
      };
    }

    if (position.isMocked) {
      _setFakeGpsStatus();

      return {
        'success': true,
        'is_valid': false,
        'location_status': 'fake_gps',
        'message': 'Fake GPS terdeteksi.',
      };
    }

    final result = await _attendanceService.validateAttendanceLocation(
      token: token,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    _applyLocationValidationResult(result);
    return result;
  }

  Future<void> _processAttendance(String token) async {
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sesi login tidak ditemukan. Silakan login ulang.',
          ),
          backgroundColor: AppColors.tertiary[500],
        ),
      );
      return;
    }

    if (_isProcessingAttendance) return;

    if (_isAttendanceBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _attendanceBlockedMessage.isNotEmpty
                ? _attendanceBlockedMessage
                : 'Presensi hari ini tidak tersedia.',
          ),
          backgroundColor: AppColors.tertiary[500],
        ),
      );
      return;
    }

    if (_isFakeGpsDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fake GPS terdeteksi.'),
          backgroundColor: AppColors.tertiary[500],
        ),
      );
      return;
    }

    if (!_isLocationValid || _isValidatingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_locationStatusMessage),
          backgroundColor: AppColors.tertiary[500],
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingAttendance = true;
      });
    }

    bool loadingDialogVisible = false;

    try {
      // Validasi terbaru sebelum kamera dibuka.
      Position latestPosition = await _getFreshPosition();
      _updateLatestPositionMarker(latestPosition);

      final preCameraValidation = await _validatePositionBeforeAction(
        token,
        latestPosition,
      );

      if (preCameraValidation['is_valid'] != true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              preCameraValidation['message']?.toString() ??
                  'Lokasi berada di luar area presensi.',
            ),
            backgroundColor: AppColors.tertiary[500],
          ),
        );
        return;
      }

      final bool isCheckIn = !_hasCheckedIn;

      // Kamera hanya dibuka setelah lokasi dinyatakan valid oleh backend.
      // Kamera depan dipilih untuk Face Capture.
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 30,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (photo == null) return;
      if (!mounted) return;

      setState(() {
        _capturedImage = File(photo.path);
      });

      // Ambil dan validasi ulang lokasi setelah pengambilan foto.
      latestPosition = await _getFreshPosition();
      _updateLatestPositionMarker(latestPosition);

      final afterPhotoValidation = await _validatePositionBeforeAction(
        token,
        latestPosition,
      );

      if (afterPhotoValidation['is_valid'] != true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              afterPhotoValidation['message']?.toString() ??
                  'Lokasi berada di luar area presensi.',
            ),
            backgroundColor: AppColors.tertiary[500],
          ),
        );
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingDialogVisible = true;

      // Backend check-in/check-out tetap melakukan validasi lokasi final.
      final result = await _attendanceService.submitAttendance(
        token: token,
        photo: _capturedImage!,
        latitude: latestPosition.latitude,
        longitude: latestPosition.longitude,
        isCheckIn: isCheckIn,
      );

      if (!mounted) return;

      if (loadingDialogVisible) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogVisible = false;
      }

      if (result['success'] == true) {
        setState(() {
          final String currentTime = DateFormat(
            'HH : mm : ss',
          ).format(DateTime.now());

          if (isCheckIn) {
            _hasCheckedIn = true;
            _checkInTime = currentTime;
          } else {
            _hasCheckedOut = true;
            _checkOutTime = currentTime;
          }
        });

        Provider.of<AttendanceUpdateProvider>(
          context,
          listen: false,
        ).notifyUpdate();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppMessage.toIndonesia(
              result['message'],
              fallback: result['success'] == true
                  ? isCheckIn
                        ? 'Presensi masuk berhasil.'
                        : 'Presensi keluar berhasil.'
                  : 'Presensi gagal. Silakan coba lagi.',
            ),
          ),
          backgroundColor: result['success'] == true
              ? AppColors.secondary[500]
              : AppColors.tertiary[500],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      if (loadingDialogVisible) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogVisible = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppMessage.toIndonesia(e)),
          backgroundColor: AppColors.tertiary[500],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAttendance = false;
        });
      }
    }
  }

  void _updateLatestPositionMarker(Position position) {
    if (!mounted) return;

    _latestPosition = position;

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _recenterOnUser() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memperbarui lokasi GPS...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final position = await _getFreshPosition();
      _handleRealtimePosition(position, validateImmediately: true);

      if (_latestPosition != null) {
        _mapController.move(
          LatLng(_latestPosition!.latitude, _latestPosition!.longitude),
          17.0,
        );
      }
    } catch (e) {
      AppLogger.error('Recenter Error', error: e);
    }
  }

  bool get _isAttendanceButtonEnabled {
    return !_isAttendanceBlocked &&
        !_hasCheckedOut &&
        !_isProcessingAttendance &&
        !_isValidatingLocation &&
        !_isFakeGpsDetected &&
        _isLocationValid;
  }

  Color get _locationStatusColor {
    switch (_locationStatusCode) {
      case 'inside_area':
        return Colors.green;
      case 'tolerance_zone':
        return Colors.orange;
      case 'attendance_blocked':
        return _attendanceBlockedStatus?.toLowerCase() == 'cuti'
            ? Colors.orange
            : Colors.red;
      case 'outside_area':
      case 'fake_gps':
      case 'location_error':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get _locationStatusIcon {
    switch (_locationStatusCode) {
      case 'inside_area':
        return Icons.location_on;
      case 'tolerance_zone':
        return Icons.radar;
      case 'attendance_blocked':
        return Icons.event_busy;
      case 'outside_area':
        return Icons.location_off;
      case 'fake_gps':
        return Icons.gps_off;
      case 'location_error':
        return Icons.error_outline;
      default:
        return Icons.sync;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final employee = user?.employee;
    String displayPosition = 'Employee';

    final String? avatarUrl = user?.avatarUrl;

    if (employee != null) {
      if (employee.position != null && employee.departmentName != null) {
        displayPosition = '${employee.departmentName} - ${employee.position}';
      } else {
        displayPosition = employee.position ?? 'Employee';
      }
    }

    String mainButtonText = 'Absen Masuk';

    if (_isAttendanceBlocked) {
      final blockedStatus = _attendanceBlockedStatus?.trim();

      mainButtonText = blockedStatus != null && blockedStatus.isNotEmpty
          ? '$blockedStatus Hari Ini'
          : 'Presensi Tidak Tersedia';
    } else if (_isProcessingAttendance) {
      mainButtonText = 'Memproses Presensi...';
    } else if (_hasCheckedIn && !_hasCheckedOut) {
      mainButtonText = 'Absen Keluar';
    } else if (_hasCheckedOut) {
      mainButtonText = 'Presensi Selesai';
    }

    return Scaffold(
      backgroundColor: AppColors.light[500],
      appBar: AppBar(
        backgroundColor: AppColors.white[500],
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray[10],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.dark[500],
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Presensi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.dark[500],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gray[10],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.my_location,
                size: 18,
                color: AppColors.dark[500],
              ),
            ),
            onPressed: _recenterOnUser,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(top: 16, left: 16, right: 16, child: _buildDateSelector()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCard(
              user?.employee?.fullName ?? user?.name ?? 'Guest',
              displayPosition,
              user?.token ?? '',
              mainButtonText,
              avatarUrl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoadingMap || _officeLocation == null) {
      return Container(
        color: AppColors.light[500],
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary[500]),
        ),
      );
    }

    final allZonePoints = _attendanceZones
        .expand<LatLng>((zone) => zone.points)
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _officeLocation!,
        initialZoom: 17.0,
        initialCameraFit: allZonePoints.isEmpty
            ? null
            : CameraFit.coordinates(
                coordinates: allZonePoints,
                padding: const EdgeInsets.fromLTRB(32, 100, 32, 320),
                maxZoom: 17.0,
              ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yourcompany.absensigeo',
        ),
        if (_attendanceZones.isNotEmpty)
          PolygonLayer(
            polygons: _attendanceZones.map((zone) {
              return Polygon(
                points: zone.points,
                color: AppColors.primary[500]!.withValues(alpha: 0.15),
                borderColor: AppColors.primary[500]!,
                borderStrokeWidth: 2.0,
              );
            }).toList(),
          ),
        MarkerLayer(
          markers: [
            ..._attendanceZones.map((zone) {
              return Marker(
                point: zone.center,
                width: 44,
                height: 44,
                child: Tooltip(
                  message: zone.name,
                  child: Icon(
                    Icons.business,
                    color: AppColors.primary[700],
                    size: 30,
                  ),
                ),
              );
            }),
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary[500],
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white[500]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark[500]!.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white[500],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark05,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: AppColors.primary[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('d MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.dark[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(
    String userName,
    String position,
    String token,
    String mainButtonText,
    String? avatarUrl,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 32),
      decoration: BoxDecoration(
        color: AppColors.white[500],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary[500]!,
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gray[500],
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.dark[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position,
                      style: TextStyle(
                        color: AppColors.gray[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasCheckedIn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary[500],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: AppColors.white[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRealtimeLocationStatus(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: AppColors.gray20),
          ),
          _buildTimelineItem(
            time: _checkInTime,
            label: 'Absen Masuk',
            isCompleted: _hasCheckedIn,
            isLast: false,
            buttonText: 'Masuk',
            isButtonActive: !_isAttendanceBlocked && !_hasCheckedIn,
          ),
          _buildTimelineItem(
            time: _checkOutTime,
            label: 'Absen Keluar',
            isCompleted: _hasCheckedOut,
            isLast: true,
            buttonText: 'Keluar',
            isButtonActive:
                !_isAttendanceBlocked && _hasCheckedIn && !_hasCheckedOut,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isAttendanceButtonEnabled
                  ? () => _processAttendance(token)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAttendanceButtonEnabled
                    ? AppColors.primary[500]
                    : AppColors.gray[500],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                mainButtonText,
                style: TextStyle(
                  color: AppColors.white[500],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeLocationStatus() {
    final color = _locationStatusColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          if (_isValidatingLocation)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(_locationStatusIcon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationStatusMessage,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String label,
    required bool isCompleted,
    required bool isLast,
    required String buttonText,
    required bool isButtonActive,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.primary[500]
                      : AppColors.white[500],
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.primary[500]!
                        : AppColors.gray[500]!,
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 16, color: AppColors.white[500])
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: CustomPaint(
                      size: const Size(1, double.infinity),
                      painter: DottedLinePainter(color: AppColors.gray[500]!),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.dark[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(color: AppColors.gray[500], fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isButtonActive
                    ? AppColors.primary[500]
                    : AppColors.gray[10],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  color: isButtonActive
                      ? AppColors.white[500]
                      : AppColors.gray[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LatLng> _parseWktPolygon(String wkt) {
    List<LatLng> points = [];

    try {
      final String coordsString = wkt
          .replaceAll(RegExp(r'[A-Za-z\(\)]'), '')
          .trim();
      final List<String> pairs = coordsString.split(',');

      for (String pair in pairs) {
        final List<String> coords = pair.trim().split(RegExp(r'\s+'));

        if (coords.length == 2) {
          final double lng = double.parse(coords[0]);
          final double lat = double.parse(coords[1]);
          points.add(LatLng(lat, lng));
        }
      }
    } catch (e) {
      AppLogger.error('Error parsing polygon', error: e);
    }

    return points;
  }

  int _parseZoneId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  LatLng _getPointsCenter(List<LatLng> points) {
    if (points.isEmpty) {
      return const LatLng(-6.200000, 106.816666);
    }

    double latSum = 0;
    double lngSum = 0;

    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }

    return LatLng(latSum / points.length, lngSum / points.length);
  }

  Future<void> _ensureLocationReady() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Layanan lokasi sedang tidak aktif. Aktifkan GPS terlebih dahulu.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Izin lokasi ditolak. Aplikasi membutuhkan akses lokasi untuk presensi.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi melalui pengaturan aplikasi.',
      );
    }
  }

  Future<Position> _getFreshPosition() async {
    await _ensureLocationReady();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    const double dashHeight = 3.0;
    const double dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
