import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/tasks_auth_admin.dart';

// استيراد الخدمات
import 'package:mentenance_app/screens/pages/home/tasks_auth.dart';

// استيراد الواجهات الجزئية
import 'package:mentenance_app/screens/admin_flow/pages/home/home_appbar.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/bottom_bar.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/tasks_widget.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/technician_staff.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  String selectedFilter = "All";
  late Future<List<Map<String, dynamic>>> futureTasks;
  late Future<List<Map<String, dynamic>>> futureTechnicians;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    futureTasks = TasksAuthAdminservice.fetchTasks();
    futureTechnicians = TechniciansApiService.fetchTechnicians();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      futureTasks = TasksAuthAdminservice.fetchTasks();
      futureTechnicians = TechniciansApiService.fetchTechnicians();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomHomeAppBar(tabController: _tabController),
        body: TabBarView(
          controller: _tabController,
          children: [
            /// 🟠 تبويب المهام من الـ API
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // فلتر المهام
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: selectedFilter,
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(value: "All", child: Text("الكل")),
                          DropdownMenuItem(value: "مهمة", child: Text("مهمة")),
                          DropdownMenuItem(
                            value: "صيانة",
                            child: Text("صيانة"),
                          ),
                          DropdownMenuItem(
                            value: "تحديث",
                            child: Text("تحديث"),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _refreshData,
                        tooltip: "تحديث البيانات",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: futureTasks,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "حدث خطأ أثناء جلب المهام:\n${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "لا توجد مهام للعرض",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        List<Map<String, dynamic>> tasks = snapshot.data!;
                        List<Map<String, dynamic>> filteredTasks =
                            selectedFilter == "All"
                                ? tasks
                                : tasks.where((task) {
                                  switch (selectedFilter) {
                                    case "مهمة":
                                      return task['type'] == 'Urgent';
                                    case "صيانة":
                                      return task['type'] == 'Maintenance';
                                    case "تحديث":
                                      return task['type'] == 'Update';
                                    default:
                                      return true;
                                  }
                                }).toList();

                        return ListView.separated(
                          itemCount: filteredTasks.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return TaskCard(
                              id: task['id'],
                              type: task['type'],
                              title: task['title'],
                              code: task['code'],
                              branch: task['branch'],
                              estTime: task['estTime'],
                              distance: task['distance'],
                              startNow: task['startNow'],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// 🟢 تبويب الفنيين من الـ API مع تصميم TechnicalStaffCard
            FutureBuilder<List<Map<String, dynamic>>>(
              future: futureTechnicians,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "حدث خطأ أثناء جلب الفنيين:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا يوجد فنيين حالياً",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final technicians = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: technicians.length,
                  itemBuilder: (context, index) {
                    final tech = technicians[index];
                    return TechnicalStaffCard(
                      name: tech['name'] ?? 'غير معروف',
                      email: tech['email'] ?? 'غير معروف',
                      phone: tech['phone'] ?? 'غير معروف',
                    );
                  },
                );
              },
            ),
          ],
        ),

        bottomNavigationBar: ADminBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
