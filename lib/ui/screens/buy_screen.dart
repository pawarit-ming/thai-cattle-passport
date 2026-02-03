import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Model สำหรับรายการในตลาด
class MarketItem {
  final String id;
  final String name;
  final String breed;
  final String sex;
  final DateTime birthDate;
  final double weight;
  final String seller;
  final String location;
  final List<String> images;

  MarketItem({
    required this.id,
    required this.name,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.weight,
    required this.seller,
    required this.location,
    required this.images,
  });

  factory MarketItem.fromJson(Map<String, dynamic> json) {
    List<String> imgList = [];

    // ฟังก์ชันช่วยดึงรูป (รองรับทั้ง String และ List)
    void addImage(dynamic value) {
      if (value == null) return;
      if (value is List) {
        for (var v in value) {
          if (v != null && v.toString().isNotEmpty) imgList.add(v.toString());
        }
      } else {
        if (value.toString().isNotEmpty) imgList.add(value.toString());
      }
    }

    addImage(json['face_pic']);
    addImage(json['body_pic']);
    addImage(json['mark_pic']);

    // --- จัดการเพศ (Sex Normalization) ---
    // แปลงค่าจาก DB ให้เป็นมาตรฐาน M/F เพื่อให้ Filter ทำงานได้
    String rawSex = json['sex']?.toString().toLowerCase() ?? '';
    String normalizedSex = 'M'; // ค่าเริ่มต้น
    // เช็คคำที่สื่อถึงตัวเมียทั้งหมด
    if (rawSex.contains('f') ||
        rawSex.contains('female') ||
        rawSex.contains('เมีย') ||
        rawSex == 'cow') {
      normalizedSex = 'F';
    }

    // --- จัดการสายพันธุ์ (Breed) ---
    // ตัดช่องว่างหน้าหลังออก เพื่อให้การค้นหาแม่นยำขึ้น
    String normalizedBreed =
        json['breed']?.toString().trim() ?? 'ไม่ระบุสายพันธุ์';

    return MarketItem(
      id: json['animal_id']?.toString() ?? '',
      name: json['animal_name'] ?? 'ไม่มีชื่อ',
      breed: normalizedBreed,
      sex: normalizedSex,
      birthDate: DateTime.tryParse(json['birth_date']?.toString() ?? '') ??
          DateTime.now(),
      weight: double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      seller: 'รหัส: ${json['user_id'] ?? '-'}', // ปัจจุบันโชว์ ID ไปก่อน
      location: json['origin'] ?? 'ไม่ระบุพิกัด',
      images: imgList,
    );
  }
}

class BuyScreen extends ConsumerStatefulWidget {
  const BuyScreen({super.key});

  @override
  ConsumerState<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends ConsumerState<BuyScreen> {
  List<MarketItem> _allItems = [];
  List<MarketItem> _filteredItems = [];

  // เพิ่มตัวแปรเช็คสถานะการโหลด
  bool _isLoading = true;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnimals() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. หา User ID ของคนปัจจุบันที่ล็อกอินอยู่
      final myUserId = supabase.auth.currentUser?.id;

      // 2. สร้าง Query พื้นฐาน
      var query = supabase.from('animals').select();

      // 3. เพิ่มเงื่อนไข: ถ้าล็อกอินอยู่ ให้กรอง User ID ของตัวเองออก
      if (myUserId != null) {
        query = query.neq('user_id', myUserId);
      }

      // 4. สั่งดึงข้อมูลและเรียงลำดับตามปกติ
      final data = await query.order('created_at', ascending: false);

      setState(() {
        _allItems =
            (data as List).map((item) => MarketItem.fromJson(item)).toList();
        _filteredItems = _allItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      final query = _searchController.text.toLowerCase().trim();

      _filteredItems = _allItems.where((item) {
        // 1. Search Logic (ปรับปรุงใหม่)
        // ให้ค้นหาเจอทั้ง ชื่อวัว, รหัสผู้ขาย, และ สายพันธุ์
        final matchSearch = item.name.toLowerCase().contains(query) ||
            item.seller.toLowerCase().contains(query) ||
            item.breed.toLowerCase().contains(query);

        // 2. Filter: Gender
        if (_selectedGender != null && item.sex != _selectedGender) {
          return false;
        }

        // 3. Filter: Breed
        // เช็คแบบแม่นยำขึ้น
        if (_selectedBreeds.isNotEmpty) {
          bool isBreedMatch = false;
          for (var selected in _selectedBreeds) {
            if (item.breed.contains(selected)) {
              isBreedMatch = true;
              break;
            }
          }
          if (!isBreedMatch) return false;
        }

        // 4. Filter: Age
        final age = DateTime.now().difference(item.birthDate).inDays / 365;
        if (age < _ageRange.start || age > _ageRange.end) {
          return false;
        }

        // 5. Filter: Weight
        if (item.weight < _weightRange.start ||
            item.weight > _weightRange.end) {
          return false;
        }

        // ถ้าผ่านเงื่อนไข Filter ทั้งหมด ให้ดูผลลัพธ์การ Search
        return matchSearch;
      }).toList();
    });
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(builder: (context, setStateSheet) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: theme.cardColor, // ใช้สีเดียวกับ Cow List (สีขาว)
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
                  'กรองสินค้า',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: ListView(
                    children: [
                      _buildFilterSectionHeader('เพศ', theme),
                      Row(
                        children: [
                          _buildGenderChip('ตัวผู้', 'M', setStateSheet, theme),
                          SizedBox(width: 10.w),
                          _buildGenderChip(
                              'ตัวเมีย', 'F', setStateSheet, theme),
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
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        child: const Text('ค้นหา'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ?
            // --- 1. ปรับแต่งช่องค้นหา (Search Box) ---
            SizedBox(
                height: 40.h, // กำหนดความสูงของช่องค้นหา
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  //style: TextStyle(color: Colors.black, fontSize: 16.sp), // สีและขนาดตัวอักษรที่พิมพ์
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อวัว หรือ ผู้ขาย...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none, // เอาเส้นขอบเดิมออก
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h), // ระยะห่างข้อความข้างใน
                    prefixIcon: const Icon(Icons.search,
                        color: Colors
                            .grey), // เพิ่มไอคอนแว่นขยายข้างใน (ถ้าต้องการ)
                  ),
                  onChanged: (val) => _applyFilters(),
                ),
              )
            : const Text(
                'ตลาดซื้อขายวัว',
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _applyFilters();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. ส่วนแสดงจำนวนผลลัพธ์ (เหมือนเดิม)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Text(
                  'ผลลัพธ์ ${_filteredItems.length} รายการ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 2. ส่วนแสดงรายการ (เพิ่มเช็ค _isLoading)
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color:
                            theme.colorScheme.primary)) // แสดงหมุนๆ เมื่อโหลด
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Text('ไม่พบวัวที่คุณค้นหา',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: EdgeInsets.all(16.r),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          return _MarketItemCard(item: _filteredItems[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MarketItemCard extends StatefulWidget {
  final MarketItem item;

  const _MarketItemCard({required this.item});

  @override
  State<_MarketItemCard> createState() => _MarketItemCardState();
}

class _MarketItemCardState extends State<_MarketItemCard> {
  int _currentImageIndex = 0;

  // ฟังก์ชันแสดงข้อมูลผู้ขายและแผนที่
  void _showSellerDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          height:
              MediaQuery.of(context).size.height * 0.7, // ความสูง 70% ของหน้าจอ
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ขีดจับด้านบน
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

              // หัวข้อ
              Text(
                'ข้อมูลผู้ขายและสถานที่',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),

              // --- 1. ส่วนจำลองแผนที่ ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[50], // สีพื้นฟ้าอ่อนจำลองน้ำ/แผนที่
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Stack(
                    children: [
                      // เส้นตารางจำลองถนน
                      Center(
                        child: Icon(Icons.map_outlined,
                            size: 100.r, color: Colors.blue.withOpacity(0.1)),
                      ),
                      // หมุดปักสถานที่
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 48.r, color: Colors.red),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 4, color: Colors.black12)
                                  ]),
                              child: Text(
                                widget.item.location,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp),
                              ),
                            )
                          ],
                        ),
                      ),
                      // ปุ่มนำทางมุมขวา
                      Positioned(
                        bottom: 16.h,
                        right: 16.w,
                        child: FloatingActionButton.small(
                          onPressed: () {},
                          backgroundColor: Colors.blue,
                          child:
                              const Icon(Icons.navigation, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // --- 2. ส่วนข้อมูลผู้ขาย ---
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.person,
                          size: 30.r, color: colorScheme.primary),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.seller,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'เบอร์โทร: 08x-xxx-xxxx', // ข้อมูลสมมติ
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, size: 14.r, color: Colors.amber),
                              Text(' 4.8 (รีวิว)',
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey[600]))
                            ],
                          )
                        ],
                      ),
                    ),
                    // ปุ่มโทร/แชท
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () {},
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.green),
                          icon: const Icon(Icons.phone, color: Colors.white),
                        ),
                        SizedBox(width: 8.w),
                        IconButton.filled(
                          onPressed: () {},
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.blue),
                          icon: const Icon(Icons.message, color: Colors.white),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ปุ่มปิด (แบบทึบ)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colorScheme.primary, // สีพื้นหลัง (สีน้ำตาล)
                    foregroundColor: Colors.white, // สีตัวอักษร (สีขาว)
                  ),
                  child: const Text('ปิด'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item; // We use this to access our data

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ส่วนรูปภาพ ---
            Container(
              height: 180.h,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: item.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      return Image.network(
                        item.images[pageIndex],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            size: 50.r,
                            color: Colors.grey),
                      );
                    },
                  ),

                  // *** FIX 1: Removed price overlay since 'price' is no longer in model ***
                  // If you want to show something else here, like the ID or status, you can.

                  // Image Indicator (Dots)
                  Positioned(
                    bottom: 8.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // *** FIX 2: Changed 'images' to 'item.images' ***
                      children: item.images.asMap().entries.map((entry) {
                        return Container(
                          width: 8.w,
                          height: 8.h,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. ส่วนรายละเอียด ---
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... rest of your code (Name, Breed, Sex, etc.) remains the same
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.breed,
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(item.sex == 'M' ? Icons.male : Icons.female,
                          size: 18.r,
                          color: item.sex == 'M' ? Colors.blue : Colors.pink),
                      SizedBox(width: 8.w),
                      Text(
                        'เพศ: ${item.sex == 'M' ? 'ตัวผู้' : 'ตัวเมีย'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.monitor_weight_outlined,
                          size: 18.r, color: Colors.grey.shade600),
                      SizedBox(width: 8.w),
                      Text(
                        'น้ำหนัก: ${item.weight.toStringAsFixed(0)} กก.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 18.r, color: Colors.grey.shade600),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ผู้ขาย: ${item.seller}',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18.r, color: Colors.grey.shade600),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'สถานที่: ${item.location}',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showSellerDetails(context),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('เสนอซื้อ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
