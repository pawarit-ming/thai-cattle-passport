import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    this.isRequired = false,
    this.hintText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        SizedBox(height: 8.h),

        // The Dropdown
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hintText ?? 'เลือก$label',
            helperText: helperText,
            helperMaxLines: 2,
            prefixIcon: icon != null ? Icon(icon) : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true, // Prevent RenderFlex overflow for long text
        ),
      ],
    );
  }
}
