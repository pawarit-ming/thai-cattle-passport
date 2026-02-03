import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoleSelectionStep extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onRoleSelected;

  const RoleSelectionStep({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เลือกประเภทผู้ใช้งาน',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          'กรุณาเลือกบทบาทของคุณในระบบ',
          style:
              theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        SizedBox(height: 24.h),

        // Farmer Option
        _buildRoleCard(
          context: context,
          roleId: 'FARMER',
          title: 'เกษตรกร',
          subtitle: 'เจ้าของฟาร์ม, ผู้เลี้ยงวัว',
          icon: Icons.agriculture,
          isSelected: selectedRole == 'FARMER',
        ),

        SizedBox(height: 16.h),

        // Buyer Option
        _buildRoleCard(
          context: context,
          roleId: 'BUYER',
          title: 'ผู้ซื้อ',
          subtitle: 'พ่อค้าคนกลาง, ผู้สนใจซื้อวัว',
          icon: Icons.shopping_cart,
          isSelected: selectedRole == 'BUYER',
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String roleId,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onRoleSelected(roleId),
      borderRadius: BorderRadius.circular(24.r), // Standard 24.r
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 32.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 24.r),
          ],
        ),
      ),
    );
  }
}
