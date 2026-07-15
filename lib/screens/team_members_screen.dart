// lib/screens/team_members_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import 'member_attendance_screen.dart';

import 'dart:async';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  static const String _allDepartments = 'Semua Departemen';

  String _searchQuery = '';
  String _selectedDepartment = _allDepartments;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final provider = context.read<EmployeeProvider>();

      if (provider.teamMembers.isEmpty) {
        await provider.fetchTeams();
      } else {
        // Apabila daftar tim berasal dari cache, tetap lakukan
        // preloading presensi bulan berjalan.
        unawaited(provider.preloadCurrentMonthAttendances());
      }
    });
  }

  String _getDepartmentName(Map<String, dynamic> employee) {
    final dynamic department = employee['department'];

    // Format:
    // "department": {
    //   "id": 1,
    //   "name": "Operasional"
    // }
    if (department is Map) {
      final String? name = department['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    // Fallback jika backend mengirim:
    // "department_name": "Operasional"
    final String? departmentName = employee['department_name']
        ?.toString()
        .trim();

    if (departmentName != null && departmentName.isNotEmpty) {
      return departmentName;
    }

    return 'Tanpa Departemen';
  }

  String _getPosition(Map<String, dynamic> employee) {
    final String? position = employee['position']?.toString().trim();

    if (position != null && position.isNotEmpty) {
      return position;
    }

    return 'Staff';
  }

  List<String> _getDepartments(List<Map<String, dynamic>> members) {
    final Set<String> departmentSet = members
        .map(_getDepartmentName)
        .where((department) => department.trim().isNotEmpty)
        .toSet();

    final List<String> departments = departmentSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [_allDepartments, ...departments];
  }

  List<Map<String, dynamic>> _filterMembers(
    List<Map<String, dynamic>> members,
    String selectedDepartment,
  ) {
    final String normalizedQuery = _searchQuery.trim().toLowerCase();

    return members.where((employee) {
      final String fullName =
          employee['full_name']?.toString().toLowerCase() ?? '';

      final String phone = employee['phone']?.toString().toLowerCase() ?? '';

      final String position = _getPosition(employee).toLowerCase();

      final String department = _getDepartmentName(employee).toLowerCase();

      final bool matchesDepartment =
          selectedDepartment == _allDepartments ||
          department == selectedDepartment.toLowerCase();

      final bool matchesSearch =
          normalizedQuery.isEmpty ||
          fullName.contains(normalizedQuery) ||
          phone.contains(normalizedQuery) ||
          position.contains(normalizedQuery) ||
          department.contains(normalizedQuery);

      return matchesDepartment && matchesSearch;
    }).toList();
  }

  String _getAvatarUrl(Map<String, dynamic> employee) {
    final String fullName =
        employee['full_name']?.toString().trim() ?? 'Unknown';

    final String? photoUrl = employee['photo_url']?.toString().trim();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return photoUrl;
    }

    return 'https://ui-avatars.com/api/'
        '?name=${Uri.encodeComponent(fullName)}'
        '&background=random';
  }

  @override
  Widget build(BuildContext context) {
    final EmployeeProvider employeeProvider = context.watch<EmployeeProvider>();

    final List<Map<String, dynamic>> members = employeeProvider.teamMembers;

    final List<String> departments = _getDepartments(members);

    // Mencegah DropdownButton error apabila departemen terpilih
    // sudah tidak terdapat pada data terbaru.
    final String activeDepartment = departments.contains(_selectedDepartment)
        ? _selectedDepartment
        : _allDepartments;

    final List<Map<String, dynamic>> filteredMembers = _filterMembers(
      members,
      activeDepartment,
    );

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
        title: const Text(
          'Anggota Tim',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Cari anggota tim',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Filter Departemen
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DropdownButtonFormField<String>(
              value: activeDepartment,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              decoration: InputDecoration(
                labelText: 'Filter Departemen',
                prefixIcon: const Icon(Icons.business_outlined),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.2),
                ),
              ),
              items: departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Text(department, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
          ),

          // Informasi jumlah anggota
          if (!employeeProvider.isLoading && members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredMembers.length} anggota ditemukan',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          Expanded(
            child: employeeProvider.isLoading && members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : members.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada anggota tim yang ditemukan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : filteredMembers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 56,
                            color: Colors.grey[350],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada anggota yang sesuai dengan '
                            'pencarian atau filter departemen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _selectedDepartment = _allDepartments;
                              });
                            },
                            child: const Text('Reset Filter'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => employeeProvider.fetchTeams(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredMembers.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey[300]),
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> employee =
                            filteredMembers[index];

                        final String fullName =
                            employee['full_name']?.toString().trim() ??
                            'Unknown';

                        final String phone =
                            employee['phone']?.toString().trim() ?? '-';

                        final String position = _getPosition(employee);

                        final String departmentName = _getDepartmentName(
                          employee,
                        );

                        final String departmentPosition =
                            '$departmentName - $position';

                        final bool isHead = position.toLowerCase() == 'head';

                        (employee['id'] as num).toInt();

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(
                              _getAvatarUrl(employee),
                            ),
                          ),
                          title: Text(
                            fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  phone,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHead
                                        ? Colors.blue[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    departmentPosition,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isHead
                                          ? Colors.blue[800]
                                          : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            final dynamic rawEmployeeId = employee['id'];

                            final int? employeeId = rawEmployeeId is int
                                ? rawEmployeeId
                                : int.tryParse(rawEmployeeId.toString());

                            if (employeeId == null) {
                              return;
                            }

                            final now = DateTime.now();
                            final provider = context.read<EmployeeProvider>();

                            // Biasanya sudah tersedia dari preloading.
                            // Jika belum, request dimulai dan otomatis dicegah agar tidak ganda.
                            unawaited(
                              provider.fetchAttendances(
                                employeeId,
                                month: now.month,
                                year: now.year,
                                silent: provider.hasAttendanceCache(
                                  employeeId,
                                  month: now.month,
                                  year: now.year,
                                ),
                              ),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemberAttendanceScreen(
                                  employeeId: employeeId,
                                  employeeName:
                                      employee['full_name']?.toString() ??
                                      'Unknown',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
