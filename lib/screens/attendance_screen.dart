// lib/screens/attendance_screen.dart

import 'package:absensi_geo/providers/attendance_update_provider.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/services/attendance_service.dart';
import 'package:absensi_geo/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;

  final MapController _mapController = MapController();

  // --- Dynamic Map State Variables ---
  List<LatLng> _polygonPoints = [];
  LatLng? _officeLocation;
  LatLng? _userLocation;
  bool _isLoadingMap = true;

  // --- Real-Time Attendance State ---
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  String _checkInTime = '-- : -- : --';
  String _checkOutTime = '-- : -- : --';

  @override
  void initState() {
    super.initState();
    _initializeAttendanceData();
  }

  Future<void> _initializeAttendanceData() async {
    await _fetchTodayStatus();

    try {
      await _getUserLocation();
    } catch (e) {
      debugPrint("GPS Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.tertiary[500],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    try {
      await _fetchAttendanceZone();
    } catch (e) {
      debugPrint("API Zone Error: $e");
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

          if (_hasCheckedIn) {
            _checkInTime = statusData['check_in_time'] ?? '-- : -- : --';
          }
          if (_hasCheckedOut) {
            _checkOutTime = statusData['check_out_time'] ?? '-- : -- : --';
          }
        });
      }
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _fetchAttendanceZone() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token != null) {
      final zoneData = await _attendanceService.getUserAttendanceZone(token);

      if (zoneData != null && mounted) {
        setState(() {
          _polygonPoints = _parseWktPolygon(zoneData['area']);
          _officeLocation = _getPolygonCenter(_polygonPoints);
        });
      }
    }
  }

  Future<void> _processAttendance(String token) async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Waiting for GPS location..."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool isCheckIn = !_hasCheckedIn;

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (photo != null) {
      if (!mounted) return;
      setState(() {
        _capturedImage = File(photo.path);
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _attendanceService.submitAttendance(
        token: token,
        photo: _capturedImage!,
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        isCheckIn: isCheckIn,
      );

      if (!mounted) return;

      Navigator.pop(context);

      if (result['success'] == true) {
        setState(() {
          String currentTime = DateFormat(
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
          content: Text(result['message'] ?? "Status unknown"),
          backgroundColor: result['success'] == true
              ? AppColors.secondary[500]
              : AppColors.tertiary[500],
        ),
      );
    }
  }

  Future<void> _recenterOnUser() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Updating GPS location..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await _getUserLocation();

      if (_userLocation != null) {
        _mapController.move(_userLocation!, 17.0);
      }
    } catch (e) {
      debugPrint("Recenter Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final employee = user?.employee;
    String displayPosition = "Employee";

    final String? avatarUrl = user?.avatarUrl;

    if (employee != null) {
      if (employee.position != null && employee.departmentName != null) {
        displayPosition = "${employee.departmentName} - ${employee.position}";
      } else {
        displayPosition = employee.position ?? "Employee";
      }
    }

    String mainButtonText = "Absen Masuk";
    if (_hasCheckedIn && !_hasCheckedOut) {
      mainButtonText = "Absen Keluar";
    } else if (_hasCheckedOut) {
      mainButtonText = "Presensi Selesai";
    }

    return Scaffold(
      backgroundColor: AppColors.light[500],
      appBar: AppBar(
        backgroundColor: AppColors.white[500],
        elevation: 0,
        // Smart Back Button diaktifkan kembali
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
          // 1. Peta di lapisan paling bawah (Full Screen)
          _buildMap(),

          // 2. Pemilih Tanggal melayang di atas peta
          Positioned(top: 16, left: 16, right: 16, child: _buildDateSelector()),

          // 3. Kartu Bawah yang Bisa Digeser (Draggable Sheet)
          DraggableScrollableSheet(
            initialChildSize: 0.45, // Saat pertama buka, menutupi 45% layar
            minChildSize:
                0.25, // Bisa ditarik turun sampai 25% (hanya kelihatan foto profil & tombol)
            maxChildSize: 0.70, // Bisa ditarik naik sampai 70% layar
            builder: (BuildContext context, ScrollController scrollController) {
              return _buildBottomCard(
                user?.employee?.fullName ?? user?.name ?? 'Guest',
                displayPosition,
                user?.token ?? '',
                mainButtonText,
                scrollController, // Lempar controllernya ke fungsi build kartu
                avatarUrl,
              );
            },
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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _officeLocation!, initialZoom: 17.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yourcompany.absensigeo',
        ),
        if (_polygonPoints.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _polygonPoints,
                color: AppColors.primary[500]!.withValues(alpha: 0.15),
                borderColor: AppColors.primary[500]!,
                borderStrokeWidth: 2.0,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: _officeLocation!,
              width: 40,
              height: 40,
              child: Icon(
                Icons.business,
                color: AppColors.primary[700],
                size: 30,
              ),
            ),
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
          Icon(Icons.arrow_drop_down, color: AppColors.dark[500]),
        ],
      ),
    );
  }

  Widget _buildBottomCard(
    String userName,
    String position,
    String token,
    String mainButtonText,
    ScrollController scrollController,
    String? avatarUrl,
  ) {
    return Container(
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
      // Dibungkus dengan SingleChildScrollView yang menggunakan controller dari DraggableSheet
      child: SingleChildScrollView(
        controller: scrollController,
        // Padding bawah tetap 110px agar tidak menabrak Navigasi Kapsul Global
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: 110,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- DRAG HANDLE (Pill abu-abu kecil di atas kartu) ---
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // --- KONTEN KARTU ABSENSI ---
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
                        ? const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.white,
                          )
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

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, thickness: 1, color: AppColors.gray20),
            ),

            _buildTimelineItem(
              time: _checkInTime,
              label: 'Absen Masuk',
              isCompleted: _hasCheckedIn,
              isLast: false,
              buttonText: 'Masuk',
              isButtonActive: !_hasCheckedIn,
            ),

            _buildTimelineItem(
              time: _checkOutTime,
              label: 'Absen Keluar',
              isCompleted: _hasCheckedOut,
              isLast: true,
              buttonText: 'Keluar',
              isButtonActive: _hasCheckedIn && !_hasCheckedOut,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasCheckedOut
                    ? null
                    : () => _processAttendance(token),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasCheckedOut
                      ? AppColors.gray[500]
                      : AppColors.primary[500],
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
      String coordsString = wkt.replaceAll(RegExp(r'[A-Za-z\(\)]'), '').trim();
      List<String> pairs = coordsString.split(',');
      for (String pair in pairs) {
        List<String> coords = pair.trim().split(RegExp(r'\s+'));
        if (coords.length == 2) {
          double lng = double.parse(coords[0]);
          double lat = double.parse(coords[1]);
          points.add(LatLng(lat, lng));
        }
      }
    } catch (e) {
      debugPrint("Error parsing polygon: $e");
    }
    return points;
  }

  LatLng _getPolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(-6.200000, 106.816666);
    double latSum = 0;
    double lngSum = 0;
    for (var p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    var dashHeight = 3.0;
    var dashSpace = 3.0;
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
