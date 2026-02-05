import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final String sellerId;

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
    required this.sellerId,
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

    return MarketItem(
      id: json['animal_id']?.toString() ?? '',
      name: json['animal_name'] ?? 'ไม่มีชื่อ',
      breed: normalizedBreed,
      sex: normalizedSex,
      birthDate: DateTime.tryParse(json['birth_date']?.toString() ?? '') ??
          DateTime.now(),
      weight: double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      sellerId: json['user_id']?.toString() ?? '',
      seller: 'รหัส: ${json['user_id'] ?? '-'}',
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

  // เพิ่มตัวแปรเก็บ ID วัวที่เราเคยเสนอซื้อไปแล้ว
  Set<String> _myOfferIds = {};

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
      final myUserId = supabase.auth.currentUser?.id;

      var query = supabase.from('animals').select();

      // 1. กรอง User ID ตัวเองออก
      if (myUserId != null) {
        query = query.neq('user_id', myUserId);
      }

      // 2. กรองวัวที่ขายแล้วออก
      query = query.neq('status', 'SOLD');

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
            item.breed.toLowerCase().contains(query);

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
            ? SizedBox(
                height: 40.h,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อวัว หรือ ผู้ขาย...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  ),
                  onChanged: (val) => _applyFilters(),
                ),
              )
            : const Text('ตลาดซื้อขายวัว'),
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
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.primary))
                : RefreshIndicator(
                    onRefresh: _fetchAnimals,
                    child: _filteredItems.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 100.h),
                              const Center(
                                child: Text('ไม่พบวัวที่คุณค้นหา',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16.r),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              // เช็คว่าไอดีนี้อยู่ใน Set ที่เสนอซื้อแล้วหรือไม่
                              final hasOffered = _myOfferIds.contains(item.id);

                              return _MarketItemCard(
                                item: item,
                                hasOffered: hasOffered, // ส่งค่านี้เข้าไป
                                onOfferSubmitted: () =>
                                    _handleOfferSubmitted(item.id),
                              );
                            },
                          ),
                  ),
          ),
        ],
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
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Positioned(
                    bottom: 8.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.map_outlined,
                        size: 100.r, color: Colors.blue.withOpacity(0.1)),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 48.r, color: Colors.red),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: const [
                                BoxShadow(blurRadius: 4, color: Colors.black12)
                              ]),
                          child: Text(
                            widget.item.location,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12.sp),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
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