import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';

class Step1TypeSelection extends StatelessWidget {
  final Function(ActivityType) onTypeSelected;
  final String cowSex;
  final bool isBreedingMissing;

  const Step1TypeSelection({
    super.key,
    required this.onTypeSelected,
    required this.cowSex,
    this.isBreedingMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    // Filter activities based on sex
    final allowedTypes = ActivityType.values.where((type) {
      if (type == ActivityType.EDIT_LOG) return false;

      // Male cows cannot give birth or be pregnant
      if (cowSex == 'MALE') {
        if (type == ActivityType.PREGNANCY_CHECK ||
            type == ActivityType.BIRTH) {
          return false;
        }
      }
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'บันทึกกิจกรรมอะไรดี?',
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
              itemCount: allowedTypes.length,
              itemBuilder: (context, index) {
                final type = allowedTypes[index];
                return _buildTypeCard(context, type);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, ActivityType type) {
    final showWarning = isBreedingMissing &&
        (type == ActivityType.PREGNANCY_CHECK || type == ActivityType.BIRTH);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTypeSelected(type),
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          decoration: WizardStyles.cardDecoration,
          child: Stack(
            children: [
              Center(
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
                      child: type.assetIcon != null
                          ? Padding(
                              padding: EdgeInsets.all(12.r),
                              child: Image.asset(
                                type.assetIcon!,
                                width: 28.r,
                                height: 28.r,
                                color: WizardColors.textLight,
                              ),
                            )
                          : Icon(
                              type.icon,
                              color: WizardColors.textLight,
                              size: 28.r,
                            ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      type.label,
                      style: WizardStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WizardColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (showWarning)
                Positioned(
                  top: 12.r,
                  right: 12.r,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: Colors.white,
                      size: 14.r,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
