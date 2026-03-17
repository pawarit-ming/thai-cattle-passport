import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/ui/widgets/adaptive_map_widget.dart';
import 'package:th_cow_passport/ui/screens/cow_detail_screen.dart';
import 'package:th_cow_passport/ui/widgets/common/app_shimmer.dart';
import 'package:th_cow_passport/ui/widgets/common/app_empty_state.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. Model สำหรับรายการในตลาด
class MarketItem {
  final String id;
  final String name;
  final String breed;
  final String sex;
  final DateTime birthDate;
  final double weight;
  final String seller;
  final bool isVerified;
  final String location;
  final List<String> images;
  final String sellerId;
  final double? latitude;
  final double? longitude;

  MarketItem({
    required this.id,
    required this.name,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.weight,
    required this.seller,
    this.isVerified = false,
    required this.location,
    required this.images,
    required this.sellerId,
    this.latitude,
    this.longitude,
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

    // --- จัดการเพศ (Sex Normalization) ---
    String rawSex = json['sex']?.toString().toLowerCase() ?? '';
    String normalizedSex = 'M';
    if (rawSex.contains('f') ||
        rawSex.contains('female') ||
        rawSex.contains('เมีย') ||
        rawSex == 'cow') {
      normalizedSex = 'F';
    }

    String normalizedBreed =
        json['breed']?.toString().trim() ?? 'ไม่ระบุสายพันธุ์';

    // --- ส่วนดึงพิกัด ---
    Map<String, dynamic>? farmData;

    try {
      final rawFarms = json['farms'];

      if (rawFarms != null) {
        if (rawFarms is List && rawFarms.isNotEmpty) {
          // กรณีมาเป็น List (เช่น [{...}])
          farmData = rawFarms[0] as Map<String, dynamic>;
        } else if (rawFarms is Map) {
          // กรณีมาเป็น Object (เช่น {...})
          farmData = rawFarms as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดตอนดึงพิกัด: $e');
    }

    dynamic rawProfiles = json['profiles'];
    Map<String, dynamic>? profileData;

    if (rawProfiles != null) {
      if (rawProfiles is List && rawProfiles.isNotEmpty) {
        profileData = rawProfiles[0] as Map<String, dynamic>;
      } else if (rawProfiles is Map<String, dynamic>) {
        profileData = rawProfiles;
      }
    }

    String sellerDisplayName = 'ไม่ระบุชื่อผู้ขาย';
    bool isSellerVerified = false;

    if (profileData != null) {
      final firstName = profileData['first_name']?.toString() ?? '';
      final lastName = profileData['last_name']?.toString() ?? '';
      sellerDisplayName = '$firstName $lastName'.trim();
      isSellerVerified = profileData['is_dld_verified'] ?? false;

      // ถ้าดึงชื่อมาได้แต่ดันเป็นค่าว่าง ให้แสดงรหัส ID แทน
      if (sellerDisplayName.isEmpty) {
        sellerDisplayName = 'รหัส: ${json['user_id'] ?? '-'}';
      }
    } else {
      // กรณี profileData เป็น null (หาในตาราง profiles ไม่เจอ)
      // ให้พยายามแสดงรหัส ID แทนคำว่าไม่ระบุชื่อ เพื่อให้รู้ว่าวัวเป็นของใคร
      sellerDisplayName = 'รหัส: ${json['user_id'] ?? '-'}';
    }

    // 1. ดึงชื่อฟาร์ม (ถ้าไม่มีใช้ origin)
    String fName = farmData?['farm_name']?.toString() ??
        json['origin'] ??
        'ไม่ระบุชื่อฟาร์ม';

    // 2. ดึงชื่อจังหวัด
    String fProvince = farmData?['province']?.toString() ?? '';

    // 3. รวมเข้าด้วยกัน
    String displayLocation =
        fProvince.isNotEmpty ? '$fName จ.$fProvince' : fName;

    return MarketItem(
      id: json['animal_id']?.toString() ?? '',
      name: json['animal_name'] ?? 'ไม่มีชื่อ',
      breed: normalizedBreed,
      sex: normalizedSex,
      birthDate: DateTime.tryParse(json['birth_date']?.toString() ?? '') ??
          DateTime.now(),
      weight: double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      sellerId: json['user_id']?.toString() ?? '',
      seller: sellerDisplayName,
      isVerified: isSellerVerified,
      location: displayLocation,
      images: imgList,
      latitude: farmData?['latitude'] != null
          ? double.tryParse(farmData!['latitude'].toString())
          : null,
      longitude: farmData?['longitude'] != null
          ? double.tryParse(farmData!['longitude'].toString())
          : null,
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

  // เพิ่มตัวแปรเก็บ ID วัวที่เราเคยเสนอซื้อไปแล้ว
  Set<String> _myOfferIds = {};

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
      final myUserId = supabase.auth.currentUser?.id;

      var query = supabase.from('animals').select('''
      *,
      profiles:user_id (
      first_name,
      last_name,
      is_dld_verified
      ),
      farms:farm_id (
        farm_name,
        province,
        latitude,
        longitude
      )
      ''');

      // 1. กรอง User ID ตัวเองออก
      if (myUserId != null) {
        query = query.neq('user_id', myUserId);
      }

      // 2. กรองวัวที่ขายแล้วออก
      query = query.neq('status', 'SOLD');

      // กรองวัวที่ตายแล้วออก
      query = query.neq('status', 'DEATH');

      // กรองวัวที่ถูกลบออก (Soft Delete)
      query = query.eq('is_deleted', false);

      final data = await query.order('created_at', ascending: false);

      // 3. [เพิ่มใหม่] ดึงข้อมูล Offer ของเรามาเช็คว่าเคยเสนอซื้อตัวไหนไปแล้วบ้าง
      Set<String> myOffers = {};
      if (myUserId != null) {
        final offersData = await supabase
            .from('offers')
            .select('animal_id')
            .eq('buyer_id', myUserId); // ดึงเฉพาะของฉัน

        myOffers =
            (offersData as List).map((e) => e['animal_id'].toString()).toSet();
      }

      if (mounted) {
        setState(() {
          _allItems =
              (data as List).map((item) => MarketItem.fromJson(item)).toList();

          // บันทึกรายการที่เสนอซื้อแล้ว
          _myOfferIds = myOffers;

          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชัน Callback เมื่อมีการกดเสนอซื้อสำเร็จ จะเอา ID ใส่ Set ทันที (ไม่ต้องโหลดใหม่ทั้งหมด)
  void _handleOfferSubmitted(String animalId) {
    setState(() {
      _myOfferIds.add(animalId);
    });
  }

  void _applyFilters() {
    setState(() {
      final query = _searchController.text.toLowerCase().trim();

      _filteredItems = _allItems.where((item) {
        final matchSearch = item.name.toLowerCase().contains(query) ||
            item.seller.toLowerCase().contains(query) ||
            item.breed.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query);

        if (_selectedGender != null && item.sex != _selectedGender) {
          return false;
        }

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

        final age = DateTime.now().difference(item.birthDate).inDays / 365;
        if (age < _ageRange.start || age > _ageRange.end) {
          return false;
        }

        if (item.weight < _weightRange.start ||
            item.weight > _weightRange.end) {
          return false;
        }

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
      // 1. AppBar เอาปุ่มออกทั้งหมด (เหลือแค่ชื่อ)
      appBar: AppBar(
        title: const Text('ตลาดซื้อขายวัว'),
        centerTitle: true,
        // actions: [], // ไม่ใส่ actions ตามที่ขอ (เอา reset และ filter เดิมออก)
      ),

      // 2. Body ให้ทุกอย่างเลื่อนได้ (Scroll with parent)
      body: RefreshIndicator(
        onRefresh: _fetchAnimals,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          // item 0 คือส่วนหัว (ค้นหา + ผลลัพธ์ + ปุ่มกรอง), ที่เหลือคือรายการวัว
          itemCount: _filteredItems.isEmpty ? 2 : _filteredItems.length + 1,
          itemBuilder: (context, index) {
            // --- ส่วนหัว (Index 0) ---
            if (index == 0) {
              return Column(
                children: [
                  // ช่องค้นหา
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'ค้นหาชื่อวัว, สายพันธุ์, ผู้ขาย หรือจังหวัด...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide:
                              BorderSide(color: theme.colorScheme.primary),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (val) => _applyFilters(),
                    ),
                  ),

                  // ส่วนแสดงผลลัพธ์ และ ปุ่ม Filter
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // ชิดซ้าย-ขวา
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 8.w),
                            Text(
                              'ผลลัพธ์ ${_filteredItems.length} รายการ',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // ปุ่ม Filter (ด้านขวา)
                        IconButton(
                          icon: Icon(Icons.filter_list,
                              color: theme.colorScheme.primary),
                          tooltip: 'ตัวกรอง',
                          onPressed: _showFilterSheet,
                          padding: EdgeInsets.all(8.r),
                          constraints: const BoxConstraints(), // ให้ปุ่มกระชับ
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // --- ส่วนแสดงสถานะ (Index 1 กรณีไม่มีข้อมูล) ---
            if (_isLoading) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: AppShimmer(
                      child: Container(
                        height: 250.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            if (_filteredItems.isEmpty) {
              return AppEmptyState(
                title: 'ไม่พบวัวที่คุณค้นหา',
                subtitle: 'ลองปรับตัวเลือกการกรองด้านบนเพื่อค้นหาใหม่',
                imageAsset: 'assets/images/cow.png',
                buttonText: 'ล้างตัวกรอง',
                onButtonPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedGender = null;
                    _selectedBreeds.clear();
                    _ageRange = const RangeValues(0, 20);
                    _weightRange = const RangeValues(0, 1500);
                  });
                  _applyFilters();
                },
              );
            }

            // --- รายการวัว (Index 1, 2, 3...) ---
            final item = _filteredItems[index - 1];
            final hasOffered = _myOfferIds.contains(item.id);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _MarketItemCard(
                item: item,
                hasOffered: hasOffered,
                onOfferSubmitted: () => _handleOfferSubmitted(item.id),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarketItemCard extends StatefulWidget {
  final MarketItem item;
  final bool hasOffered; // เพิ่มตัวแปรนี้
  final VoidCallback? onOfferSubmitted; // เพิ่ม callback

  const _MarketItemCard({
    required this.item,
    required this.hasOffered,
    this.onOfferSubmitted,
  });

  @override
  State<_MarketItemCard> createState() => _MarketItemCardState();
}

class _MarketItemCardState extends State<_MarketItemCard> {
  int _currentImageIndex = 0;

  void _showSellerDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SellerDetailsSheet(
          item: widget.item,
          onOfferSubmitted: widget.onOfferSubmitted, // ส่งต่อ callback
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => CowDetailScreen(
                cowId: int.tryParse(item.id) ?? 0,
                isReadOnly: true,
                hideBackButton:
                    false, // ✅ ระบุชัดเจนว่าให้แสดงปุ่ม Back (แม้จะเป็น default)
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180.h,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: item.images.isEmpty
                  ? Center(
                      child: Image.asset(
                        'assets/images/cow.png',
                        width: 100.r,
                        height: 100.r,
                      ),
                    )
                  : Stack(
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Image.asset(
                                  'assets/images/cow.png',
                                  width: 80.r,
                                  height: 80.r,
                                ),
                              ),
                            );
                          },
                        ),
                        if (item.images.length > 1)
                          Positioned(
                            bottom: 8.h,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  item.images.asMap().entries.map((entry) {
                                return Container(
                                  width: 8.w,
                                  height: 8.h,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          color: colorScheme.primary.withValues(alpha: 0.1),
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
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'ผู้ขาย: ${item.seller}',
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.isVerified)
                              Padding(
                                padding: EdgeInsets.only(left: 4.w),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 16.r,
                                ),
                              ),
                          ],
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
                    // 4. Logic เปลี่ยนปุ่ม: ถ้าเสนอซื้อแล้ว ให้ปิดปุ่ม
                    child: widget.hasOffered
                        ? FilledButton.icon(
                            onPressed: null, // ปิดการกด (Disabled)
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade600,
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('ส่งข้อเสนอแล้ว'),
                          )
                        : FilledButton.icon(
                            onPressed: () {
                              _showSellerDetails(context);
                            },
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

class SellerDetailsSheet extends StatefulWidget {
  final MarketItem item;
  final VoidCallback? onOfferSubmitted; // เพิ่ม callback

  const SellerDetailsSheet({
    super.key,
    required this.item,
    this.onOfferSubmitted,
  });

  @override
  State<SellerDetailsSheet> createState() => _SellerDetailsSheetState();
}

class _SellerDetailsSheetState extends State<SellerDetailsSheet> {
  bool _isSubmitting = false;

  // ฟังก์ชันสำหรับเปิดแอปแผนที่
  Future<void> _launchMap(double lat, double lng) async {
    final bool isIos = Theme.of(context).platform == TargetPlatform.iOS;

    // 1. ลองใช้ Apple Maps สำหรับ iOS
    if (isIos) {
      final Uri appleUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 2. ลองใช้ geo: สำหรับ Android (จะเปิดแอปแผนที่อะไรก็ได้ในเครื่อง เช่น Petal Maps, Google Maps)
    final Uri geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (!isIos && await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      return;
    }

    // 3. ตัวสำรอง (Google Maps Web URL)
    final Uri webUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดแผนที่ได้')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // เตรียมตำแหน่งพิกัด (ถ้าไม่มีพิกัด ให้ไปลงที่กรุงเทพฯ เป็น Default)
    final double lat = widget.item.latitude ?? 13.7563;
    final double lng = widget.item.longitude ?? 100.5018;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
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
            'ข้อมูลผู้ขายและสถานที่',
            style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: AdaptiveDisplayMap(
                latitude: lat,
                longitude: lng,
                markerId: widget.item.id,
                markerTitle: widget.item.name,
                onMarkerTap: () => _launchMap(lat, lng),
                zoom: 15,
              ),
            ),
          ),
          SizedBox(height: 24.h),
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
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person,
                      size: 30.r, color: colorScheme.primary),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.item.seller,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (widget.item.isVerified)
                            Padding(
                              padding: EdgeInsets.only(left: 4.w),
                              child: Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20.r,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'เบอร์โทร: 08x-xxx-xxxx',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ยืนยันการเสนอซื้อ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitOffer() async {
    setState(() {
      _isSubmitting = true;
    });

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) return;

    try {
      await supabase.from('offers').insert({
        'animal_id': widget.item.id,
        'buyer_id': user.id,
        'seller_id': widget.item.sellerId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // แจ้งหน้าหลักว่าทำรายการสำเร็จแล้ว (เพื่อให้ปุ่มเปลี่ยนสถานะทันที)
      widget.onOfferSubmitted?.call();

      if (mounted) navigator.pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('ส่งคำเสนอซื้อเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }
}
