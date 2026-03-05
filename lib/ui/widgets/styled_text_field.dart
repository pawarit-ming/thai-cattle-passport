import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/widgets/common/app_text_field.dart';

class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? assetIcon;
  final String? hintText;
  final bool isRequired;
  final TextInputType? keyboardType;
  final String? suffixText;
  final String? helperText;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final String? errorText;
  final String? Function(String?)? customValidator;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.assetIcon,
    this.hintText,
    this.isRequired = false,
    this.keyboardType,
    this.suffixText,
    this.helperText,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.customValidator,
    this.errorText,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      keyboardType: keyboardType ?? TextInputType.text,
      suffixText: suffixText,
      helperText: helperText,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      errorText: errorText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      prefixIcon: assetIcon != null
          ? Padding(
              padding: EdgeInsets.all(12.r),
              child: Image.asset(
                assetIcon!,
                width: 24.r,
                height: 24.r,
              ),
            )
          : Icon(icon),
      validator: customValidator ??
          (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'กรุณากรอก $label';
            }
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'กรุณากรอกตัวเลขที่ถูกต้อง';
              }
            }
            return null;
          },
    );
  }
}
