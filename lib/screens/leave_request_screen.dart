import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_geo/theme/app_colors.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/providers/leave_provider.dart'; // 👇 Import LeaveProvider
import 'package:absensi_geo/providers/attendance_update_provider.dart';
import 'package:absensi_geo/services/leave_service.dart';
import 'package:absensi_geo/screens/apply_leave_screen.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  int _activeTabIndex = 0;
  List<String> _selectedStatuses = [];
  final List<String> _statusOptions = ['Approved', 'Rejected', 'Pending'];

  // Fungsi untuk me-refresh data secara manual (saat di-pull to refresh)
  Future<void> _refreshData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).user?.token;
    if (token != null) {
      await Provider.of<LeaveProvider>(
        context,
        listen: false,
      ).fetchLeaveData(token, forceRefresh: true);
    }
  }

  Future<void> _processTeamLeave(int leaveId, String status) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null) {
      Navigator.pop(context);
      return;
    }

    final success = await LeaveService().processTeamLeave(
      token: token,
      leaveId: leaveId,
      status: status,
    );

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading dialog

    if (success) {
      // 👇 Hapus dari list di provider agar UI otomatis ter-update
      leaveProvider.removeTeamLeave(leaveId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave successfully $status!'),
          backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
        ),
      );

      Provider.of<AttendanceUpdateProvider>(
        context,
        listen: false,
      ).notifyUpdate();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process request.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTeamLeaveDetails(dynamic leave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TeamLeaveDetailModal(
          leave: leave,
          onAccept: () {
            Navigator.pop(context);
            _processTeamLeave(leave['id'], 'Approved');
          },
          onReject: () {
            Navigator.pop(context);
            _processTeamLeave(leave['id'], 'Rejected');
          },
        );
      },
    );
  }

  void _showPersonalLeaveDetails(dynamic leave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PersonalLeaveDetailModal(leave: leave);
      },
    );
  }

  void _showFilterModal() {
    List<String> tempStatuses = List.from(_selectedStatuses);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Status",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ..._statusOptions.map((status) {
                    String displayLabel = status == 'Rejected'
                        ? 'Rejected'
                        : status;
                    return Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.grey.shade300,
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          displayLabel,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: tempStatuses.contains(status),
                        activeColor: Colors.blue,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(
                          horizontal: 0,
                          vertical: -4,
                        ),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              tempStatuses.add(status);
                            } else {
                              tempStatuses.remove(status);
                            }
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              tempStatuses.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatuses = tempStatuses;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );
  }

  // Fungsi untuk memfilter list berdasarkan state lokal dan data dari Provider
  List<dynamic> _getFilteredLeaves(LeaveProvider provider) {
    List<dynamic> baseList;

    if (_activeTabIndex == 0) {
      baseList = provider.allLeaves
          .where((leave) => leave['is_past'] == false)
          .toList();
    } else if (_activeTabIndex == 1) {
      baseList = provider.allLeaves
          .where((leave) => leave['is_past'] == true)
          .toList();
    } else {
      baseList = provider.teamLeaves;
    }

    if (_selectedStatuses.isEmpty) {
      return baseList;
    }

    return baseList.where((leave) {
      return _selectedStatuses.any(
        (s) => s.toLowerCase() == leave['status'].toString().toLowerCase(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isFilterActive = _selectedStatuses.isNotEmpty;

    // 👇 Pantau perubahan pada LeaveProvider 👇
    final leaveProvider = Provider.of<LeaveProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.light[500],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Data Cuti',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () async {
              final bool? shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApplyLeaveScreen(),
                ),
              );

              if (shouldRefresh == true) {
                _refreshData();
              }
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.black87),
                onPressed: _showFilterModal,
              ),
              if (isFilterActive)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        child: Column(
          children: [
            _buildSummary(leaveProvider), // Lempar provider ke widget
            const SizedBox(height: 20),
            _buildTabs(),
            const SizedBox(height: 20),
            Expanded(
              // Tampilkan loading HANYA JIKA belum ada data di memori
              child: !leaveProvider.isLoaded && leaveProvider.isFetching
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: _buildList(leaveProvider),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(LeaveProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard("Jumlah Cuti", provider.summary['balance']!, Colors.blue),
        _SummaryCard(
          "Cuti Disetujui",
          provider.summary['approved']!,
          Colors.green,
        ),
        _SummaryCard(
          "Cuti Tertunda",
          provider.summary['pending']!,
          Colors.teal,
        ),
        _SummaryCard(
          "Cuti Dibatalkan",
          provider.summary['cancelled']!,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = ["Akan Datang", "Lalu", "Cuti Tim"];
    return Row(
      children: List.generate(tabs.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _activeTabIndex = index),
            child: _TabItem(tabs[index], _activeTabIndex == index),
          ),
        );
      }),
    );
  }

  Widget _buildList(LeaveProvider provider) {
    final leavesToShow = _getFilteredLeaves(provider);

    if (leavesToShow.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120),
            sliver: SliverFillRemaining(
              child: Center(
                child: Text(
                  _activeTabIndex == 2
                      ? "Tidak ada pengajuan cuti dari tim Anda."
                      : "Tidak ada data cuti yang ditemukan.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: leavesToShow.length,
      itemBuilder: (context, index) {
        final leave = leavesToShow[index];

        if (_activeTabIndex == 2) {
          final employeeName = leave['employee'] != null
              ? leave['employee']['full_name']
              : (leave['employee_name'] ?? 'Unknown');

          String? employeeAvatar;
          if (leave['employee'] != null && leave['employee']['user'] != null) {
            employeeAvatar = leave['employee']['user']['avatar_url'];
          } else {
            employeeAvatar = leave['avatar_url'];
          }

          return _TeamLeaveItem(
            name: employeeName,
            dateRange:
                leave['date_range'] ??
                '${leave['start_date']} - ${leave['end_date']}',
            imageUrl: employeeAvatar,
            onReject: () => _processTeamLeave(leave['id'], 'Rejected'),
            onAccept: () => _processTeamLeave(leave['id'], 'Approved'),
            onTap: () => _showTeamLeaveDetails(leave),
          );
        }

        return _LeaveItem(
          date:
              leave['date_range'] ??
              '${leave['start_date']} - ${leave['end_date']}',
          days: leave['apply_days']?.toString() ?? '0',
          balance: leave['balance']?.toString() ?? '0',
          approvedBy: leave['approved_by'] ?? '--',
          status: leave['status'] ?? 'Pending',
          onTap: () => _showPersonalLeaveDetails(leave),
        );
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔹 COMPONENTS
////////////////////////////////////////////////////////////

// --- KOMPONEN BARU: MODAL DETAIL CUTI PRIBADI ---
class _PersonalLeaveDetailModal extends StatelessWidget {
  final dynamic leave;

  const _PersonalLeaveDetailModal({required this.leave});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.green;
    String status = leave['status'] ?? 'Pending';
    if (status.toLowerCase() == 'pending') statusColor = Colors.orange;
    if (status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'rejected') {
      statusColor = Colors.red;
    }

    // 👇 MENGAMBIL DATA NAMA & POSISI DINAMIS DARI AUTH PROVIDER 👇
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final employee = user?.employee;
    final String? avatarUrl = user?.avatarUrl;

    // 1. Ambil Nama Lengkap
    final String userName =
        employee?.fullName ?? user?.name ?? "Unknown Employee";

    // 2. Rangkai Departemen - Posisi
    String positionInfo = "Department - Position not set";
    if (employee != null) {
      if (employee.departmentName != null && employee.position != null) {
        positionInfo = "${employee.departmentName} - ${employee.position}";
      } else if (employee.position != null) {
        positionInfo = employee.position!;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary[500],
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 👇 DATA DINAMIS DITAMPILKAN DI SINI 👇
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark[500],
                          ),
                        ),
                        Text(
                          positionInfo,
                          style: TextStyle(
                            color: AppColors.gray[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Badge Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),

            _buildDetailRow(
              "Tipe Cuti",
              leave['leave_type'] ?? 'General Leave',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              "Tanggal",
              leave['date_range'] ??
                  '${leave['start_date']} - ${leave['end_date']}',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              "Hari yang Diajukan",
              "${leave['apply_days'] ?? 0} Hari",
            ),
            const SizedBox(height: 16),
            _buildDetailRow("Diterima Oleh", leave['approved_by'] ?? '--'),
            const SizedBox(height: 16),

            Text(
              "Alasan Cuti",
              style: TextStyle(color: AppColors.gray[500], fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.light[500],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                leave['reason'] ?? 'No reason provided in database.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.dark[500],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Tutup
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary[500],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Tutup",
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: AppColors.gray[500], fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.dark[500],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// --- MODAL DETAIL TEAM LEAVE ---
class _TeamLeaveDetailModal extends StatelessWidget {
  final dynamic leave;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _TeamLeaveDetailModal({
    required this.leave,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ambil Nama Lengkap
    final employeeName = leave['employee'] != null
        ? leave['employee']['full_name']
        : (leave['employee_name'] ?? 'Unknown Employee');

    String? employeeAvatar;
    if (leave['employee'] != null && leave['employee']['user'] != null) {
      employeeAvatar = leave['employee']['user']['avatar_url'];
    } else {
      employeeAvatar = leave['avatar_url']; // Fallback
    }

    // 👇 2. LOGIKA BARU: Merangkai Departemen - Posisi 👇
    String positionInfo = 'Staff Member';
    if (leave['employee'] != null) {
      final dept = leave['employee']['department'];
      final pos = leave['employee']['position'];

      if (dept != null && pos != null) {
        positionInfo = "$dept - $pos";
      } else if (pos != null) {
        positionInfo = pos;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: employeeAvatar != null
                      ? NetworkImage(employeeAvatar)
                      : null,
                  child: employeeAvatar == null
                      ? const Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark[500],
                        ),
                      ),
                      Text(
                        positionInfo,
                        style: TextStyle(
                          color: AppColors.gray[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            _buildDetailRow("Tipe Cuti", leave['leave_type'] ?? 'Cuti Reguler'),
            const SizedBox(height: 16),
            _buildDetailRow(
              "Tanggal",
              leave['date_range'] ??
                  '${leave['start_date']} - ${leave['end_date']}',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              "Hari yang Diajukan",
              "${leave['apply_days'] ?? 0} Hari",
            ),
            const SizedBox(height: 16),
            Text(
              "Alasan Cuti",
              style: TextStyle(color: AppColors.gray[500], fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.light[500],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                leave['reason'] ?? 'No reason provided.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.dark[500],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF766A),
                      side: const BorderSide(color: Color(0xFFFF766A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Tolak Cuti",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD3B8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Setujui Cuti",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: AppColors.gray[500], fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.dark[500],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// --- KOMPONEN KARTU TEAM LEAVE ---
class _TeamLeaveItem extends StatelessWidget {
  final String name;
  final String dateRange;
  final String? imageUrl;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _TeamLeaveItem({
    required this.name,
    required this.dateRange,
    this.imageUrl,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: imageUrl != null
                          ? NetworkImage(imageUrl!)
                          : null,
                      child: imageUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateRange,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Tolak",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF766A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Setujui",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DD3B8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool active;

  const _TabItem(this.text, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.primary[500] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// 👇 KOMPONEN KARTU CUTI PRIBADI YANG SUDAH DIPERBARUI (CLICKABLE) 👇
class _LeaveItem extends StatelessWidget {
  final String date;
  final String days;
  final String balance;
  final String approvedBy;
  final String status;
  final VoidCallback onTap;

  const _LeaveItem({
    required this.date,
    required this.days,
    required this.balance,
    required this.approvedBy,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.green;
    if (status.toLowerCase() == '') statusColor = Colors.orange;
    if (status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'rejected') {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark[500]!.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Date", style: TextStyle(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _info("Hari", days),
                    _info("Sisa Cuti", balance),
                    _info("Diterima Oleh", approvedBy),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
