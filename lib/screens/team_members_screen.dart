// lib/screens/team_members_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import 'member_attendance_screen.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TeamMembersScreenState createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeeProvider>();
      // 👇 PERBAIKAN: Hanya panggil API jika memori masih kosong!
      if (provider.teamMembers.isEmpty) {
        provider.fetchTeams();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Membaca data dari memori Provider (Tanpa FutureBuilder)
    final employeeProvider = context.watch<EmployeeProvider>();
    final members = employeeProvider.teamMembers;

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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            // 👇 Logika Loading dari Provider
            child: employeeProvider.isLoading && members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : members.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada anggota tim yang ditemukan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => employeeProvider.fetchTeams(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: members.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey[300]),
                      itemBuilder: (context, index) {
                        final employee = members[index];

                        // Pastikan logika BaseApiService.baseUrl ada jika avatarUrl membutuhkannya
                        final String avatarUrl =
                            employee['photo_url'] ??
                            'https://ui-avatars.com/api/?name=${employee['full_name']}&background=random';
                        final bool isHead = employee['position'] == 'Head';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                          title: Text(
                            employee['full_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee['phone'] ?? '-',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHead
                                        ? Colors.blue[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    employee['position'] ?? 'Staff',
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
                            // 👇 Pre-fetch data attendance agar instan saat pindah layar
                            context.read<EmployeeProvider>().fetchAttendances(
                              employee['id'],
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemberAttendanceScreen(
                                  employeeId: employee['id'],
                                  employeeName: employee['full_name'],
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
