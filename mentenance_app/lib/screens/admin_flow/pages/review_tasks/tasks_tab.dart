import 'package:flutter/material.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _selectedTaskFilter = 'الكل';

  final List<Map<String, dynamic>> tasks = [
    {
      'type': 'Urgent',
      'title': 'خطأ في Counting Mechanism يتطلب تدخل عاجل',
      'code': 'PROSCAN-6P-001247',
      'branch': 'فرع الرياض الرئيسي',
      'estTime': 45,
      'distance': 2.5,
      'startNow': true,
    },
    {
      'type': 'Maintenance',
      'title': 'الصيانة الوقائية الشهرية لجميع الأجهزة',
      'code': 'PROSCAN-5P-008934',
      'branch': 'فرع جدة التجاري',
      'estTime': 90,
      'distance': 5.2,
      'startNow': false,
    },
    {
      'type': 'Update',
      'title': 'تحديث Firmware لأحدث نسخة لجميع الأجهزة',
      'code': 'PROSCAN-3P-019876',
      'branch': 'فرع الدمام الشرقي',
      'estTime': 30,
      'distance': 8.1,
      'startNow': false,
    },
  ];

  List<Map<String, dynamic>> get filteredTasks {
    if (_selectedTaskFilter == 'الكل') return tasks;
    return tasks.where((t) => t['type'] == _selectedTaskFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildTaskFilterDropdown(),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return TaskCard(
                type: task['type'],
                title: task['title'],
                code: task['code'],
                branch: task['branch'],
                estTime: task['estTime'],
                distance: task['distance'],
                startNow: task['startNow'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskFilterDropdown() {
    final filters = ['الكل', 'Urgent', 'Maintenance', 'Update'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedTaskFilter,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items:
            filters
                .map(
                  (f) => DropdownMenuItem<String>(
                    value: f,
                    child: Text(
                      f == 'Urgent'
                          ? 'عاجلة'
                          : f == 'Maintenance'
                          ? 'صيانة'
                          : f == 'Update'
                          ? 'تحديث'
                          : 'الكل',
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedTaskFilter = value);
        },
      ),
    );
  }
}

// -------------------- كرت المهام --------------------
class TaskCard extends StatelessWidget {
  final String type;
  final String title;
  final String code;
  final String branch;
  final int estTime;
  final double distance;
  final bool startNow;

  const TaskCard({
    super.key,
    required this.type,
    required this.title,
    required this.code,
    required this.branch,
    required this.estTime,
    required this.distance,
    this.startNow = false,
  });

  Color get color {
    switch (type) {
      case "Urgent":
        return const Color.fromARGB(206, 244, 67, 54);
      case "Maintenance":
        return const Color.fromARGB(202, 255, 153, 0);
      case "Update":
        return const Color.fromARGB(202, 76, 175, 79);
      default:
        return Colors.grey;
    }
  }

  String get typeLabel {
    switch (type) {
      case "Urgent":
        return "عاجلة";
      case "Maintenance":
        return "صيانة";
      case "Update":
        return "تحديث";
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
        border: Border(right: BorderSide(color: color, width: 6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // النوع والوقت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  startNow ? "بدأت قبل 30 دقيقة" : "موعد البدء: 10:00 ص",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(code, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(branch, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  "المدة: $estTime دقيقة",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${distance.toStringAsFixed(1)} كم",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('قبول'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('رفض'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
