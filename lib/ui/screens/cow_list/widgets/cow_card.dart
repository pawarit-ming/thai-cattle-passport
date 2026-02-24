import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import 'package:th_cow_passport/ui/widgets/cached_cow_image.dart';

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
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : Colors.grey.withValues(
                  alpha: 0.2), // เพิ่มเส้นขอบสีเทาจาง ๆ เมื่อไม่ได้เลือก
          width: isSelected ? 2.w : 1.w,
        ),
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
                CachedCowImage(
                  imageUrl: () {
                    if (cow.facePic != null && cow.facePic!.isNotEmpty) {
                      return cow.facePic!.first;
                    } else if (cow.bodyPic != null && cow.bodyPic!.isNotEmpty) {
                      return cow.bodyPic!.first;
                    }
                    return null;
                  }(),
                  width: 60,
                  height: 60,
                  borderRadius: 12,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NID
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cow.nidNumber,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                      // Name
                      Text(
                        cow.animalName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      // Breed
                      Text(
                        cow.breed ?? '-',
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 8.h),
                      // Gender + Age
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
                          if (age != null) ...[
                            SizedBox(width: 8.w),
                            Text(
                              '$age ปี',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Health status (replaces arrow)
                _buildHealthTag(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthTag() {
    switch (cow.status) {
      case 'SICK':
        return _buildStatusTag(
          label: 'ป่วย',
          color: Colors.red.shade100,
          textColor: Colors.red.shade800,
        );
      case 'DEATH':
        return _buildStatusTag(
          label: 'ตาย',
          color: Colors.grey.shade300,
          textColor: Colors.grey.shade800,
        );
      default:
        return _buildStatusTag(
          label: 'สุขภาพดี',
          color: Colors.green.shade100,
          textColor: Colors.green.shade800,
        );
    }
  }

  Widget _buildStatusTag(
      {required String label, required Color color, required Color textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: textColor,
          fontWeight: FontWeight.bold,
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: textColor),
          if (label != null && label.isNotEmpty) ...[
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11.sp,
                  color: textColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
