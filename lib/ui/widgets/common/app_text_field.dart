import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  // New properties for full compatibility
  final bool isRequired;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final String? helperText;
  final String? suffixText;
  final String? assetIcon;
  final FocusNode? focusNode;
  final IconData? icon;
  final String? Function(String?)? customValidator;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.isRequired = false,
    this.maxLength,
    this.inputFormatters,
    this.errorText,
    this.helperText,
    this.suffixText,
    this.assetIcon,
    this.focusNode,
    this.icon,
    this.customValidator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            validator: customValidator ??
                validator ??
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
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hintText,
              helperText: helperText,
              errorText: errorText,
              suffixText: suffixText,
              helperMaxLines: 2,
              hintStyle: TextStyle(color: theme.hintColor),
              prefixIcon: assetIcon != null
                  ? Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Image.asset(
                        assetIcon!,
                        width: 24.r,
                        height: 24.r,
                      ),
                    )
                  : (icon != null
                      ? Icon(icon, color: theme.hintColor)
                      : prefixIcon),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: readOnly
                  ? theme.disabledColor.withValues(alpha: 0.05)
                  : theme.cardColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
