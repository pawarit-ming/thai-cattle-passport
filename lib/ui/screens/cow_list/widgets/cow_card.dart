import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';

class CowCard extends StatelessWidget {
  final Cow cow;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onSelect;

  const CowCard({
    super.key,
    required this.cow,
    this.isEditMode = false,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final age = cow.birthDate != null
        ? DateTime.now().difference(cow.birthDate!).inDays ~/ 365
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : (theme.cardTheme.color ?? Colors.white),
        borderRadius: BorderRadius.circular(24.r),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 2.w)
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: isEditMode
              ? onSelect
              : () => context.push('/detail/${cow.animalId}'),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                if (isEditMode)
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (val) => onSelect(),
                      activeColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.3)),
                    image: (cow.facePic != null && cow.facePic!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(cow.facePic!.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (cow.facePic == null || cow.facePic!.isEmpty)
                      ? Icon(Icons.pets, color: colorScheme.primary, size: 36.r)
                      : null,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cow.nidNumber,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),

                          // เพิ่มระยะห่างนิดหน่อย กันตัวหนังสือชนกับป้ายชื่อ
                          SizedBox(width: 8.w),

                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            // ป้ายชื่อ (Container) ปล่อยไว้เหมือนเดิม มันจะอยู่ขวาสุด
                            child: Text(
                              'ชื่อ: ${cow.animalName}',
                              style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${cow.breed ?? '-'} • ${age != null ? '$age ปี' : 'ไม่ทราบ'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          _buildMiniTag(
                            icon: cow.sex == 'MALE' ? Icons.male : Icons.female,
                            color: cow.sex == 'MALE'
                                ? Colors.blue.shade100
                                : Colors.pink.shade100,
                            textColor: cow.sex == 'MALE'
                                ? Colors.blue.shade800
                                : Colors.pink.shade800,
                          ),
                          SizedBox(width: 8.w),
                          _buildMiniTag(
                            icon: Icons.monitor_heart_outlined,
                            label: 'สุขภาพดี',
                            color: Colors.green.shade100,
                            textColor: Colors.green.shade800,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward_ios,
                    size: 16.r, color: theme.dividerColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(
      {required IconData icon,
      String? label,
      required Color color,
      required Color textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: textColor),
          if (label != null && label.isNotEmpty) ...[
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10.sp,
                  color: textColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
