import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/home/CustomDrawer.dart';
import 'package:mentenance_app/screens/pages/home/bottem_bar.dart';
import 'package:mentenance_app/screens/pages/home/compononts.dart';
import 'package:mentenance_app/screens/pages/home/home_appbar.dart';
import 'package:mentenance_app/screens/pages/home/tasks_auth.dart'; // يحتوي على TaskApiService
import 'package:mentenance_app/screens/pages/home/tasks_widget.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int _currentIndex = 0;
  String selectedFilter = "All";

  late Future<List<Map<String, dynamic>>> futureTasks;

  @override
  void initState() {
    super.initState();
    // جلب المهام من الـ API باستخدام الـ userId المخزن
    futureTasks = TaskApiService.fetchTasks();
  }

  // دالة لتحديث المهام بالسحب للأسفل
  Future<void> _refreshTasks() async {
    setState(() {
      futureTasks = TaskApiService.fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        endDrawer: const CustomDrawer(),
        backgroundColor: AppColors.white,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(65),
          child: AppBarWidget(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // فلتر المهام
              FilterDropdown(
                selectedFilter: selectedFilter,
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // المهام من API
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: futureTasks,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "حدث خطأ أثناء جلب البيانات:\n${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "لا توجد مهام للعرض",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      // تطبيق الفلترة
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
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return TaskCard(
                            id: task['task_id'], // 👈 أضف هذا السطر
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
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
