import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';

class Step1TypeSelection extends StatelessWidget {
  final Function(ActivityType) onTypeSelected;

  const Step1TypeSelection({super.key, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of activity?',
            style: WizardStyles.titleLarge,
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.0,
              ),
              itemCount: ActivityType.values.length,
              itemBuilder: (context, index) {
                final type = ActivityType.values[index];
                if (type == ActivityType.EDIT_LOG)
                  return const SizedBox.shrink(); // Skip Edit Log

                return _buildTypeCard(context, type);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, ActivityType type) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTypeSelected(type),
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          decoration: WizardStyles.cardDecoration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: WizardColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type.icon,
                  color: WizardColors.textLight,
                  size: 28.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                type.label, // Or key map to English if needed, but extension has Thai
                style: WizardStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WizardColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
