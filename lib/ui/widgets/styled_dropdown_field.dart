import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/widgets/common/app_dropdown.dart';

/// A standardized Dropdown field with the label positioned above the input.
///
/// Features:
/// - Label above the dropdown
/// - Optional required asterisk (*)
/// - Consistent decoration and styling
class StyledDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final IconData? icon;
  final String? assetIcon;
  final bool isRequired;
  final String? hintText;
  final String? helperText;

  const StyledDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.icon,
    this.assetIcon,
    this.isRequired = false,
    this.hintText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isRequired: isRequired,
      hintText: hintText ?? 'เลือก$label',
      prefixIcon: assetIcon != null
          ? Padding(
              padding: EdgeInsets.all(12.r),
              child: Image.asset(
                assetIcon!,
                width: 24.r,
                height: 24.r,
              ),
            )
          : (icon != null ? Icon(icon) : null),
    );
  }
}
