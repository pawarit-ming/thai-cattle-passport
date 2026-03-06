import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/widgets/common/app_text_field.dart';
import 'package:th_cow_passport/ui/widgets/common/app_dropdown.dart';

class DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final VoidCallback onTap;

  const DatePickerField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      label: labelText,
      isRequired: true,
      suffixIcon: const Icon(Icons.calendar_today),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณาเลือกวันที่';
        }
        return null;
      },
    );
  }
}

class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final int maxLines;
  final bool isRequired;
  final TextInputType? keyboardType;
  final String? suffixText;

  final IconData? icon;
  final String? assetIcon;

  const FormTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.isRequired = true,
    this.keyboardType,
    this.suffixText,
    this.icon,
    this.assetIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType ?? TextInputType.text,
      label: labelText,
      hintText: hintText,
      isRequired: isRequired,
      suffixText: suffixText,
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
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'กรุณากรอกข้อมูล$labelText';
        }
        return null;
      },
    );
  }
}

class FormDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;
  final String? hintText;

  final String? assetIcon;
  final IconData? icon;

  const FormDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.isRequired = false,
    this.hintText,
    this.assetIcon,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown<T>(
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (isRequired && value == null) {
              return 'กรุณาเลือก$label';
            }
            return null;
          },
      isRequired: isRequired,
      hintText: hintText,
      assetIcon: assetIcon,
      icon: icon,
    );
  }
}
