import 'package:flutter/material.dart';

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
        labelText: '$labelText ${isRequired ? '*' : '(ไม่บังคับ)'}',
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
