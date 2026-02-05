import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import 'package:th_cow_passport/ui/screens/cow_list/widgets/cow_card.dart';
import 'package:th_cow_passport/ui/screens/cow_list/widgets/filter_bottom_sheet.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class CowListScreen extends ConsumerStatefulWidget {
  const CowListScreen({super.key});

  @override
  ConsumerState<CowListScreen> createState() => _CowListScreenState();
}

class _CowListScreenState extends ConsumerState<CowListScreen> {
  final logger = Logger();
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
      if (_selectedBreeds.isNotEmpty && !_selectedBreeds.contains(cow.breed)) {
        return false;
      }

      // 3. กรองอายุ (Age)
      if (cow.birthDate == null) {
        return false;
      }

      final age = DateTime.now().difference(cow.birthDate!).inDays / 365;

      if (age < _ageRange.start || age > _ageRange.end) {
        return false;
      }

      // 4. กรองน้ำหนัก (Weight)
      final weight = (cow.weight ?? 0).toDouble();
      if (weight < _weightRange.start || weight > _weightRange.end) {
        return false;
      }

      return true;
    }).toList();
  }

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    logger.i('Initializing CowListScreen, fetching cows...');
    Future.microtask(() => ref.read(cowServiceProvider).fetchCows());
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        // กรณี: Login ใหม่ -> บังคับโหลดข้อมูลใหม่ของ User คนนั้น
        logger.i('User Signed In: Refreshing Data');
        ref.read(cowServiceProvider).fetchCows(forceRefresh: true);

        // ล้างสถานะการเลือก (Edit Mode)
        setState(() {
          _isEditMode = false;
          _selectedCowIds.clear();
        });
      } else if (event == AuthChangeEvent.signedOut) {
        // กรณี: Logout -> ล้างข้อมูล Provider ทิ้ง (Reset เป็นค่าเริ่มต้น)
        logger.i('User Signed Out: Invalidating Provider');
        ref.invalidate(cowServiceProvider);

        // ล้างสถานะหน้าจอ
        setState(() {
          _isEditMode = false;
          _selectedCowIds.clear();
        });
      }
    });
  }

  Future<void> _refreshCows() async {
    logger.i('Manual refresh triggered');
    await ref.read(cowServiceProvider).fetchCows(forceRefresh: true);
  }

  Future<void> _confirmBatchDelete() async {
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
      logger.w('Batch deleting $count cows: $_selectedCowIds');
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterBottomSheet(
          initialGender: _selectedGender,
          initialBreeds: _selectedBreeds,
          initialAgeRange: _ageRange,
          initialWeightRange: _weightRange,
          availableBreeds: _breeds,
          onApply: (gender, breeds, ageRange, weightRange) {
            setState(() {
              _selectedGender = gender;
              _selectedBreeds.clear();
              _selectedBreeds.addAll(breeds);
              _ageRange = ageRange;
              _weightRange = weightRange;
            });
          },
        );
      },
    );
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
              onPressed:
                  _selectedCowIds.isEmpty ? null : () => _confirmBatchDelete(),
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
                        tooltip: 'กรองข้อมูล',
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
      itemCount: displayCows.length,
      itemBuilder: (context, index) {
        final cow = displayCows[index];
        final isSelected = _selectedCowIds.contains(cow.animalId);

        return CowCard(
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
}
