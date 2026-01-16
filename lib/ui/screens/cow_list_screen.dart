import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CowListScreen extends StatefulWidget {
  const CowListScreen({super.key});

  @override
  State<CowListScreen> createState() => _CowListScreenState();
}

class _CowListScreenState extends State<CowListScreen> {
  // --- ไม่มีการกำหนดสี Hardcode ตรงนี้แล้ว ---

  // --- ตัวแปรสำหรับ Filter (State) ---
  String? _selectedGender;
  final List<String> _selectedBreeds = [];
  RangeValues _ageRange = const RangeValues(0, 20);
  RangeValues _weightRange = const RangeValues(0, 1500);

  final List<String> _breeds = [
    'Brahman',
    'Charolais',
    'Wagyu',
    'Angus',
    'Hindu Brazil',
    'Native (พื้นเมือง)'
  ];

  @override
  Widget build(BuildContext context) {
    // เรียก Theme มาใช้
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // backgroundColor ใช้ค่า default จาก Theme (scaffoldBackgroundColor)
      appBar: AppBar(
        // backgroundColor/foregroundColor ใช้ค่า default จาก Theme
        title: const Text('วัวของฉัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/form');
        },
        // ใช้ค่า default จาก Theme หรือกำหนดชัดเจนหากต้องการเน้น
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: 'เพิ่มวัว',
        child: const Icon(Icons.add),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
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
                        "จำนวน 5 ตัว",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      // color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 16),

              // --- Cow List ---
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final cowId = 101 + index;
                  final String name = 'Bessie ${index + 1}';
                  final String breed = _breeds[index % _breeds.length];
                  final String gender = index % 2 == 0 ? 'Male' : 'Female';

                  return _buildCowCard(
                    context: context,
                    id: cowId.toString(),
                    name: name,
                    breed: breed,
                    gender: gender,
                    age: '${index + 2} ปี',
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget การ์ดแสดงข้อมูลวัว ---
  Widget _buildCowCard({
    required BuildContext context, // รับ context เข้ามาเพื่อดึง Theme
    required String id,
    required String name,
    required String breed,
    required String gender,
    required String age,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/detail'),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 1. รูปภาพ/ไอคอนวัว
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor, // ใช้สีพื้นหลังแอป
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.pets, color: colorScheme.primary, size: 36),
                ),
                const SizedBox(width: 16),

                // 2. ข้อมูลหลัก
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: $id',
                              style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$breed • $age',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      // Tags (Gender/Status) - สี Functional (ฟ้า/ชมพู/เขียว) เก็บไว้ได้
                      Row(
                        children: [
                          _buildMiniTag(
                            icon: gender == 'Male' ? Icons.male : Icons.female,
                            label: gender,
                            color: gender == 'Male'
                                ? Colors.blue.shade100
                                : Colors.pink.shade100,
                            textColor: gender == 'Male'
                                ? Colors.blue.shade900
                                : Colors.pink.shade900,
                          ),
                          const SizedBox(width: 8),
                          _buildMiniTag(
                            icon: Icons.check_circle_outline,
                            label: 'สมบูรณ์',
                            color: Colors.green.shade100,
                            textColor: Colors.green.shade800,
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: theme.dividerColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(
      {required IconData icon,
      required String label,
      required Color color,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- ฟังก์ชันแสดงหน้าต่าง Filter ---
  void _showFilterDialog() {
    // ต้องดึง Theme นอก builder เพื่อส่งเข้าไป หรือดึงใหม่ข้างในก็ได้
    // แต่ตรงนี้ context มี theme อยู่แล้ว

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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'กรองข้อมูลวัว',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      children: [
                        _buildFilterSectionHeader('เพศ', theme),
                        Row(
                          children: [
                            _buildGenderChip(
                                'ตัวผู้', 'Male', setStateSheet, theme),
                            const SizedBox(width: 10),
                            _buildGenderChip('ตัวเมีย', 'Female',
                                setStateSheet, theme),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildFilterSectionHeader('สายพันธุ์', theme),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _breeds.map((breed) {
                            final isSelected = _selectedBreeds.contains(breed);
                            return FilterChip(
                              label: Text(breed),
                              selected: isSelected,
                              selectedColor: colorScheme.primary,
                              disabledColor: theme.cardColor,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected ? colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                              backgroundColor: theme.cardColor,
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : theme.dividerColor,
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
                        const SizedBox(height: 24),
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

                  // Buttons
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
                          // Style จะถูกดึงมาจาก Theme (OutlinedButtonThemeData)
                          child: const Text('ล้างค่า'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          // Style จะถูกดึงมาจาก Theme (ElevatedButtonThemeData)
                          child: const Text('ค้นหา'),
                        ),
                      ),
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
      padding: const EdgeInsets.only(bottom: 8.0),
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
