import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/farm/farm_service.dart';
import 'package:th_cow_passport/services/farm/model/farm_model.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/ui/screens/cow_form/widgets/create_farm_dialog.dart';
import 'package:th_cow_passport/ui/widgets/styled_text_field.dart';
import 'package:th_cow_passport/ui/widgets/styled_dropdown_field.dart';
import 'package:th_cow_passport/core/constants/animal_constants.dart';
import 'package:th_cow_passport/ui/widgets/common/app_search_dropdown.dart';

class GeneralInfoTab extends ConsumerStatefulWidget {
  final TextEditingController nidNumberController;
  final TextEditingController animalNameController;
  final TextEditingController breedController;
  final DateTime birthDate;
  final ValueChanged<DateTime> onBirthDateChanged;
  final String sex;
  final ValueChanged<String?> onSexChanged;
  final Farm? selectedFarm;
  final ValueChanged<Farm?> onFarmChanged;

  const GeneralInfoTab({
    super.key,
    required this.nidNumberController,
    required this.animalNameController,
    required this.breedController,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.sex,
    required this.onSexChanged,
    required this.selectedFarm,
    required this.onFarmChanged,
  });

  @override
  ConsumerState<GeneralInfoTab> createState() => _GeneralInfoTabState();
}

class _GeneralInfoTabState extends ConsumerState<GeneralInfoTab> {
  final _logger = Logger();

  // State
  String? _selectedBreed;
  final TextEditingController _customBreedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeBreedFields();
  }

  void _initializeBreedFields() {
    final currentBreed = widget.breedController.text;
    if (currentBreed.isNotEmpty) {
      if (AnimalConstants.breedOptions.contains(currentBreed)) {
        _selectedBreed = currentBreed;
      } else {
        _selectedBreed = AnimalConstants.customOption;
        _customBreedController.text = currentBreed;
      }
    } else {
      _selectedBreed = null;
    }

    // Listen to custom controller to update main controller
    _customBreedController.addListener(() {
      if (_selectedBreed == AnimalConstants.customOption) {
        widget.breedController.text = _customBreedController.text;
      }
    });
  }

  @override
  void dispose() {
    _customBreedController.dispose();
    super.dispose();
  }

  void _showCreateFarmDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateFarmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          // Farm Selection Dropdown
          if (userId != null)
            Consumer(
              builder: (context, ref, child) {
                final farmsAsync = ref.watch(userFarmsProvider(userId));

                return farmsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) {
                    _logger.e('[CowForm] Error loading farms',
                        error: error, stackTrace: stack);
                    return Text('Error loading farms: $error');
                  },
                  data: (farms) {
                    if (farms.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 40),
                            SizedBox(height: 8.h),
                            const Text(
                              'คุณยังไม่มีข้อมูลฟาร์ม',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text('ต้องสร้างฟาร์มก่อนจึงจะเพิ่มวัวได้'),
                            SizedBox(height: 12.h),
                            ElevatedButton.icon(
                              onPressed: _showCreateFarmDialog,
                              icon: const Icon(Icons.add_home_work),
                              label: const Text('สร้างฟาร์มใหม่'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return AppSearchDropdown<Farm>(
                      label: 'ฟาร์ม',
                      isRequired: true,
                      value: widget.selectedFarm ??
                          (farms.isNotEmpty ? farms.first : null),
                      prefixIcon: const Icon(Icons.home),
                      items: farms
                          .map((farm) => DropdownMenuItem(
                                value: farm,
                                child: Text(farm.farmName),
                              ))
                          .toList(),
                      itemAsString: (farm) => farm.farmName,
                      onChanged: widget.onFarmChanged,
                      validator: (value) {
                        if (value == null) {
                          return 'กรุณาเลือกฟาร์ม';
                        }
                        return null;
                      },
                    );
                  },
                );
              },
            ),
          StyledTextField(
            controller: widget.nidNumberController,
            label: 'Tag ID (เลขหู)',
            hintText: 'เช่น 1234567890123',
            icon: Icons.confirmation_number,
            isRequired: true,
            maxLength: 16,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: 16.h),
          StyledTextField(
            controller: widget.animalNameController,
            label: 'ชื่อวัว',
            hintText: 'เช่น สมศรี, บุญรอด',
            icon: Icons.pets,
            isRequired: true,
            maxLength: 50,
          ),
          SizedBox(height: 16.h),
          AppSearchDropdown<String>(
            label: 'สายพันธุ์',
            isRequired: true,
            value: _selectedBreed,
            hintText: 'เลือกสายพันธุ์',
            prefixIcon: const Icon(Icons.category),
            items: AnimalConstants.breedOptions.map((breed) {
              return DropdownMenuItem(
                value: breed,
                child: Text(breed),
              );
            }).toList(),
            itemAsString: (breed) => breed,
            onChanged: (value) {
              setState(() {
                _selectedBreed = value;
                if (value == AnimalConstants.customOption) {
                  widget.breedController.text = _customBreedController.text;
                } else {
                  widget.breedController.text = value ?? '';
                }
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาเลือกสายพันธุ์';
              }
              return null;
            },
          ),
          if (_selectedBreed == AnimalConstants.customOption) ...[
            SizedBox(height: 16.h),
            StyledTextField(
              label: 'ระบุสายพันธุ์',
              controller: _customBreedController,
              icon: Icons.edit,
              hintText: 'เช่น วากิวลูกผสม, บราห์มันแท้',
              isRequired: true,
              maxLength: 50,
            ),
          ],
          SizedBox(height: 16.h),
          StyledTextField(
            controller: TextEditingController(
                text: MaterialLocalizations.of(context)
                    .formatShortDate(widget.birthDate)),
            label: 'วันเกิด',
            isRequired: true,
            readOnly: true,
            icon: Icons.calendar_today,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.birthDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                widget.onBirthDateChanged(picked);
              }
            },
          ),
          SizedBox(height: 16.h),
          StyledDropdownField<String>(
            label: 'เพศ',
            isRequired: true,
            value: widget.sex,
            icon: Icons.wc,
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('ผู้')),
              DropdownMenuItem(value: 'FEMALE', child: Text('เมีย')),
            ],
            onChanged: widget.onSexChanged,
          ),
        ],
      ),
    );
  }
}
