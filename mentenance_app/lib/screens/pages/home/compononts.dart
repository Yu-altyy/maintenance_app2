import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';

//الفلترة
class FilterDropdown extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const FilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 98, 98, 99).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: DropdownButton<String>(
        value: selectedFilter,
        isExpanded: true,
        dropdownColor: Colors.white,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list, color: AppColors.primary, size: 30),
        iconEnabledColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        items: const [
          DropdownMenuItem(
            value: "All",
            child: Align(alignment: Alignment.centerRight, child: Text("الكل")),
          ),
          DropdownMenuItem(
            value: "مهمة",
            child: Align(alignment: Alignment.centerRight, child: Text("مهمة")),
          ),
          DropdownMenuItem(
            value: "صيانة",
            child: Align(
              alignment: Alignment.centerRight,
              child: Text("صيانة"),
            ),
          ),
          DropdownMenuItem(
            value: "تحديث",
            child: Align(
              alignment: Alignment.centerRight,
              child: Text("تحديث"),
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}
