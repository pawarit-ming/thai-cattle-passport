import 'package:flutter/material.dart';
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

  const FormTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: '$labelText${isRequired ? ' *' : ''}',
        hintText: hintText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
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

  const FormDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.isRequired = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return StyledDropdownField<T>(
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      validator: validator,
      isRequired: isRequired,
      hintText: hintText,
    );
  }
}
