import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';

class CowListScreen extends ConsumerStatefulWidget {
  const CowListScreen({super.key});

  @override
  ConsumerState<CowListScreen> createState() => _CowListScreenState();
}

class _CowListScreenState extends ConsumerState<CowListScreen> {
  String? _selectedGender;
  final List<String> _selectedBreeds = [];
  RangeValues _ageRange = const RangeValues(0, 20);
  RangeValues _weightRange = const RangeValues(0, 1500);

  final List<String> _breeds = [
    'บราห์มัน',
    'ชาร์โรเลส์',
    'วากิว',
    'แองกัส',
    'ฮินดูบราซิล',
    'พื้นเมือง'
  ];

  bool _isEditMode = false;
  // ใช้ Set เพื่อเก็บ ID ที่เลือก (ป้องกันการซ้ำและหาข้อมูลเร็ว)
  final Set<int> _selectedCowIds = {};

  List<Cow> get _filteredCows {
    final allCows = ref.read(cowServiceProvider).cows;

    return allCows.where((cow) {
      // 1. กรองเพศ (Gender)
      if (_selectedGender != null && cow.sex != _selectedGender) {
        return false;
      }

      // 2. กรองสายพันธุ์ (Breeds)
      // ถ้ามีการเลือกสายพันธุ์ และวัวตัวนั้นไม่ได้อยู่ในสายพันธุ์ที่เลือก
      if (_selectedBreeds.isNotEmpty && !_selectedBreeds.contains(cow.breed)) {
        return false;
      }

      // 3. กรองอายุ (Age)
      // เช็คก่อนว่ามีวันเกิดไหม ถ้าไม่มี ให้กรองออก (หรือจะ return true ถ้าอยากให้แสดง)
      if (cow.birthDate == null) {
        return false;
      }

      // เมื่อเช็คแล้วว่าไม่ null ให้ใส่ ! ด้านหลังเพื่อยืนยันค่า
      final age = DateTime.now().difference(cow.birthDate!).inDays / 365;

      if (age < _ageRange.start || age > _ageRange.end) {
        return false;
      }

      // 4. กรองน้ำหนัก (Weight)
      // หมายเหตุ: สมมติว่าใน CowModel มี field 'weight' (double หรือ int)
      // ถ้าใน Model ชื่ออื่น ให้เปลี่ยน cow.weight เป็นชื่อที่ถูกต้อง
      final weight = (cow.weight ?? 0).toDouble();
      if (weight < _weightRange.start || weight > _weightRange.end) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    Future.microtask(() => ref.read(cowServiceProvider).fetchCows());
  }

  Future<void> _refreshCows() async {
    await ref.read(cowServiceProvider).fetchCows();
  }

  Future<void> _confirmBatchDelete(BuildContext context) async {
    final count = _selectedCowIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content:
            Text('คุณต้องการลบข้อมูลวัวทั้ง $count ตัวที่เลือกใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // เรียก Service เพื่อลบแบบ Batch
      for (final id in _selectedCowIds) {
        await ref.read(cowServiceProvider).deleteCow(id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบวัว $count ตัวเรียบร้อยแล้ว')),
        );
        setState(() {
          _isEditMode = false;
          _selectedCowIds.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cowService = ref.watch(cowServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditMode ? 'เลือกวัว (${_selectedCowIds.length})' : 'วัวของฉัน'),
        leading: _isEditMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isEditMode = false;
                    _selectedCowIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  // ถ้าเลือกครบแล้วให้ล้างค่า ถ้ายังไม่ครบให้เลือกทั้งหมด
                  if (_selectedCowIds.length == cowService.cows.length) {
                    _selectedCowIds.clear();
                  } else {
                    _selectedCowIds
                        .addAll(cowService.cows.map((c) => c.animalId!));
                  }
                });
              },
              tooltip: 'เลือกทั้งหมด',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _selectedCowIds.isEmpty
                  ? null
                  : () => _confirmBatchDelete(context),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
            ),
        ],
      ),
      floatingActionButton: _isEditMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                context.go('/form');
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              tooltip: 'เพิ่มวัว',
              child: const Icon(Icons.add),
            ),
      body: RefreshIndicator(
        onRefresh: _refreshCows,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "รายการวัวทั้งหมด",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "จำนวน ${cowService.cows.length} ตัว",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list),
                        color: colorScheme.primary,
                        tooltip: 'Filter Cows',
                        onPressed: _showFilterDialog,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildCowList(cowService),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCowList(CowService cowService) {
    // ใช้ข้อมูลที่ผ่านการกรองแล้ว
    final displayCows = _filteredCows;

    if (cowService.isLoading && cowService.cows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cowService.cows.isEmpty) {
      return const Center(
        child: Text('ไม่พบข้อมูลวัว, ลองเพิ่มวัวตัวใหม่ดูสิ!'),
      );
    }

    // เพิ่มกรณีที่กรองแล้วไม่เจอกรณีที่มีวัวในระบบแต่ไม่ตรงเงื่อนไข
    if (displayCows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            const Text('ไม่พบวัวที่ตรงกับเงื่อนไขตัวกรอง'),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedGender = null;
                  _selectedBreeds.clear();
                  _ageRange = const RangeValues(0, 20);
                  _weightRange = const RangeValues(0, 1500);
                });
              },
              child: const Text('ล้างตัวกรอง'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // เปลี่ยน item count เป็นจำนวนที่กรองแล้ว
      itemCount: displayCows.length,
      itemBuilder: (context, index) {
        // ดึงข้อมูลจาก list ที่กรองแล้ว
        final cow = displayCows[index];
        final isSelected = _selectedCowIds.contains(cow.animalId);

        return _buildCowCard(
          context: context,
          cow: cow,
          isEditMode: _isEditMode,
          isSelected: isSelected,
          onSelect: () {
            setState(() {
              if (isSelected) {
                _selectedCowIds.remove(cow.animalId);
              } else {
                _selectedCowIds.add(cow.animalId!);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildCowCard({
    required BuildContext context,
    required Cow cow,
    required bool isEditMode,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final age = cow.birthDate != null
        ? DateTime.now().difference(cow.birthDate!).inDays ~/ 365
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        // จุดที่ต้องเพิ่ม: เปลี่ยนสีพื้นหลังเมื่อถูกเลือก
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : (theme.cardTheme.color ?? Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 2.w)
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          // เมื่ออยู่ในโหมดแก้ไข ให้กดเพื่อเลือกแทนการไปหน้า Detail
          onTap: isEditMode
              ? onSelect
              : () => context.go('/detail/${cow.animalId}'),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                // จุดที่ต้องเพิ่ม: แสดง Checkbox เมื่ออยู่ในโหมดแก้ไข
                if (isEditMode)
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (val) => onSelect(),
                      activeColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.3)),
                    image: (cow.facePic != null && cow.facePic!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(cow.facePic!.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (cow.facePic == null || cow.facePic!.isEmpty)
                      ? Icon(Icons.pets, color: colorScheme.primary, size: 36.r)
                      : null,
                ),
                SizedBox(width: 16.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cow.nidNumber ?? 'ไม่ระบุหมายเลข',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'ชื่อ: ${cow.animalName}',
                              style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${cow.breed ?? '-'} • ${age != null ? '$age ปี' : 'ไม่ทราบ'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          _buildMiniTag(
                            icon: cow.sex == 'MALE' ? Icons.male : Icons.female,
                            color: cow.sex == 'MALE'
                                ? Colors.blue.shade100
                                : Colors.pink.shade100,
                            textColor: cow.sex == 'MALE'
                                ? Colors.blue.shade800
                                : Colors.pink.shade800,
                          ),
                          SizedBox(width: 8.w),
                          _buildMiniTag(
                            icon: Icons.monitor_heart_outlined,
                            label: 'สุขภาพดี',
                            color: Colors.green.shade100,
                            textColor: Colors.green.shade800,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward_ios,
                    size: 16.r, color: theme.dividerColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(
      {required IconData icon,
      String? label,
      required Color color,
      required Color textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: textColor),
          if (label != null && label.isNotEmpty) ...[
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10.sp,
                  color: textColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'กรองข้อมูลวัว',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildFilterSectionHeader('เพศ', theme),
                        Row(
                          children: [
                            _buildGenderChip(
                                'ตัวผู้', 'MALE', setStateSheet, theme),
                            SizedBox(width: 10.w),
                            _buildGenderChip(
                                'ตัวเมีย', 'FEMALE', setStateSheet, theme),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        _buildFilterSectionHeader('สายพันธุ์', theme),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _breeds.map((breed) {
                            final isSelected = _selectedBreeds.contains(breed);
                            return FilterChip(
                              label: Text(breed),
                              selected: isSelected,
                              selectedColor: colorScheme.primary,
                              disabledColor: theme.cardColor,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                              backgroundColor: theme.cardColor,
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : theme.dividerColor,
                              ),
                              onSelected: (bool selected) {
                                setStateSheet(() {
                                  if (selected) {
                                    _selectedBreeds.add(breed);
                                  } else {
                                    _selectedBreeds.remove(breed);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 24.h),
                        _buildFilterSectionHeader(
                            'อายุ (${_ageRange.start.round()} - ${_ageRange.end.round()} ปี)',
                            theme),
                        RangeSlider(
                          activeColor: colorScheme.primary,
                          inactiveColor: theme.scaffoldBackgroundColor,
                          values: _ageRange,
                          min: 0,
                          max: 20,
                          divisions: 20,
                          labels: RangeLabels('${_ageRange.start.round()}',
                              '${_ageRange.end.round()}'),
                          onChanged: (val) =>
                              setStateSheet(() => _ageRange = val),
                        ),
                        _buildFilterSectionHeader(
                            'น้ำหนัก (${_weightRange.start.round()} - ${_weightRange.end.round()} กก.)',
                            theme),
                        RangeSlider(
                          activeColor: colorScheme.primary,
                          inactiveColor: theme.scaffoldBackgroundColor,
                          values: _weightRange,
                          min: 0,
                          max: 1500,
                          divisions: 150,
                          labels: RangeLabels('${_weightRange.start.round()}',
                              '${_weightRange.end.round()}'),
                          onChanged: (val) =>
                              setStateSheet(() => _weightRange = val),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setStateSheet(() {
                              _selectedGender = null;
                              _selectedBreeds.clear();
                              _ageRange = const RangeValues(0, 20);
                              _weightRange = const RangeValues(0, 1500);
                            });
                          },
                          child: const Text('ล้างค่า'),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // ปิด Dialog
                            setState(
                                () {}); // *** สำคัญ: สั่งให้หน้าจอหลักวาดใหม่ด้วยค่า Filter ล่าสุด ***
                          },
                          child: const Text('ค้นหา'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
    );
  }

  Widget _buildGenderChip(
      String label, String value, StateSetter setStateSheet, ThemeData theme) {
    final isSelected = _selectedGender == value;
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      disabledColor: theme.cardColor,
      labelStyle:
          TextStyle(color: isSelected ? colorScheme.onPrimary : Colors.black),
      backgroundColor: theme.cardColor,
      side: BorderSide(
          color: isSelected ? Colors.transparent : theme.dividerColor),
      onSelected: (bool selected) {
        setStateSheet(() {
          _selectedGender = selected ? value : null;
        });
      },
    );
  }
}
