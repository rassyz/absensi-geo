// lib/screens/member_attendance_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';

class MemberAttendanceScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const MemberAttendanceScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<MemberAttendanceScreen> createState() => _MemberAttendanceScreenState();
}

class _MemberAttendanceScreenState extends State<MemberAttendanceScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadAttendance();
    });
  }

  void _loadAttendance({bool forceRefresh = false}) {
    final provider = context.read<EmployeeProvider>();

    final hasCache = provider.hasAttendanceCache(
      widget.employeeId,
      month: _selectedMonth,
      year: _selectedYear,
    );

    unawaited(
      provider.fetchAttendances(
        widget.employeeId,
        month: _selectedMonth,
        year: _selectedYear,
        forceRefresh: forceRefresh,
        silent: hasCache,
      ),
    );
  }

  Future<void> _refreshAttendance() {
    return context.read<EmployeeProvider>().fetchAttendances(
      widget.employeeId,
      month: _selectedMonth,
      year: _selectedYear,
      forceRefresh: true,
      silent: true,
    );
  }

  void _showFilterModal() {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    int temporaryMonth = _selectedMonth;
    int temporaryYear = _selectedYear;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.viewInsetsOf(modalContext).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Presensi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: temporaryMonth,
                            decoration: InputDecoration(
                              labelText: 'Bulan',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text(monthNames[index]),
                              );
                            }),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setModalState(() {
                                temporaryMonth = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: temporaryYear,
                            decoration: InputDecoration(
                              labelText: 'Tahun',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: List.generate(5, (index) {
                              final year = DateTime.now().year - 3 + index;

                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setModalState(() {
                                temporaryYear = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(modalContext);

                          setState(() {
                            _selectedMonth = temporaryMonth;
                            _selectedYear = temporaryYear;
                          });

                          _loadAttendance();
                        },
                        child: const Text(
                          'Terapkan Filter',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();

    final attendances = employeeProvider.getAttendances(
      widget.employeeId,
      month: _selectedMonth,
      year: _selectedYear,
    );

    final hasCache = employeeProvider.hasAttendanceCache(
      widget.employeeId,
      month: _selectedMonth,
      year: _selectedYear,
    );

    final isLoading = employeeProvider.isLoadingAttendancesFor(
      widget.employeeId,
      month: _selectedMonth,
      year: _selectedYear,
    );

    Widget bodyContent;

    if (!hasCache && isLoading) {
      bodyContent = const _AttendanceSkeletonList();
    } else if (attendances.isEmpty) {
      bodyContent = RefreshIndicator(
        onRefresh: _refreshAttendance,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data untuk bulan '
                    '$_selectedMonth/$_selectedYear.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        onRefresh: _refreshAttendance,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: attendances.length,
          itemBuilder: (context, index) {
            return _AttendanceCard(record: attendances[index]);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.employeeName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Data lama tetap tampil ketika aplikasi memperbarui
          // cache di background.
          if (hasCache && isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }
}

class _AttendanceSkeletonList extends StatelessWidget {
  const _AttendanceSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 16);
      },
      itemBuilder: (context, index) {
        return Container(
          height: 118,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: Colors.grey[300]!, width: 8),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _AttendanceCard({required this.record});

  String _formatDate(String? dateString) {
    if (dateString == null) {
      return 'Tanggal Tidak Diketahui';
    }

    try {
      final date = DateTime.parse(dateString).toLocal();

      const monthNames = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString == '--:--') {
      return '--:--';
    }

    try {
      final date = DateTime.parse(timeString).toLocal();

      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = record['status']?.toString().toLowerCase() ?? '';

    final isInactive =
        currentStatus == 'future_date' || currentStatus == 'absent';

    final indicatorColor = isInactive ? Colors.grey[300]! : Colors.blue[400]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: indicatorColor, width: 8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(record['date']?.toString()),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      icon: Icons.login,
                      time: _formatTime(record['check_in']?.toString()),
                      iconColor: isInactive ? Colors.grey : Colors.blue,
                      timeColor: isInactive
                          ? Colors.grey[500]
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeBox(
                      icon: Icons.logout,
                      time: _formatTime(record['check_out']?.toString()),
                      iconColor: isInactive ? Colors.grey : Colors.blue,
                      timeColor: isInactive
                          ? Colors.grey[500]
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final IconData icon;
  final String time;
  final Color iconColor;
  final Color? timeColor;

  const _TimeBox({
    required this.icon,
    required this.time,
    required this.iconColor,
    this.timeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: timeColor,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
