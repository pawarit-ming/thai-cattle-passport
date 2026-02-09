import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/widgets/styled_dropdown_field.dart';

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
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
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
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: '$labelText${isRequired ? ' *' : ''}',
        hintText: hintText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
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
      ),
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
    return StyledDropdownField<T>(
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
