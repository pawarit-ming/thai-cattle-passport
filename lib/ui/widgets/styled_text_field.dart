import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
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
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            helperMaxLines: 2,
            errorText: errorText,
            suffixText: suffixText,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 12.h), // Ensure padding
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
            filled: true,
            fillColor: Colors.grey.shade50,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
      ],
    );
  }
}
