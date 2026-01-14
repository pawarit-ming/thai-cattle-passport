import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:table_calendar/table_calendar.dart'; // Comment ไว้ก่อนถ้ายังไม่ได้ใช้

class CowListScreen extends StatefulWidget {
  const CowListScreen({super.key});

  @override
  State<CowListScreen> createState() => _CowListScreenState();
}

class _CowListScreenState extends State<CowListScreen> {
  // --- ตัวแปรสำหรับ Filter (State) ---
  String? _selectedGender; // 'Male', 'Female'
  String? _selectedBreed;
  RangeValues _ageRange = const RangeValues(0, 10); // อายุ 0-10 ปี
  RangeValues _weightRange = const RangeValues(0, 1000); // น้ำหนัก 0-1000 กก.

  // ข้อมูลจำลองสำหรับ Dropdown สายพันธุ์
  final List<String> _breeds = [
    'Brahman',
    'Charolais',
    'Wagyu',
    'Angus',
    'Hindu Brazil',
    'Native (พื้นเมือง)'
  ];

  @override
  void initState() {
    super.initState();
  }

  // --- ฟังก์ชันแสดงหน้าต่าง Filter ---
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ให้ขยายเต็มจอได้เมื่อมีเนื้อหาเยอะ
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // ใช้ StatefulBuilder เพื่อให้ update state (เช่น เลื่อน Slider) ใน BottomSheet ได้
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              // ความสูงของหน้าจอ
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'กรองข้อมูลวัว (Filter)',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),

                  Expanded(
                    child: ListView(
                      children: [
                        // 1. เพศ (Gender)
                        const Text('เพศ (Gender)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildGenderChip(
                                'ตัวผู้ (Male)', 'Male', setStateSheet),
                            const SizedBox(width: 10),
                            _buildGenderChip(
                                'ตัวเมีย (Female)', 'Female', setStateSheet),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 2. สายพันธุ์ (Breed)
                        const Text('สายพันธุ์ (Breed)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButtonFormField<String>(
                          value: _selectedBreed,
                          hint: const Text('เลือกสายพันธุ์'),
                          isExpanded: true,
                          items: _breeds.map((String breed) {
                            return DropdownMenuItem<String>(
                              value: breed,
                              child: Text(breed),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setStateSheet(() {
                              _selectedBreed = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // 3. อายุ (Age)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('อายุ (Age)',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                '${_ageRange.start.round()} - ${_ageRange.end.round()} ปี'),
                          ],
                        ),
                        RangeSlider(
                          values: _ageRange,
                          min: 0,
                          max: 20,
                          divisions: 20,
                          labels: RangeLabels(
                            '${_ageRange.start.round()} ปี',
                            '${_ageRange.end.round()} ปี',
                          ),
                          onChanged: (RangeValues values) {
                            setStateSheet(() {
                              _ageRange = values;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // 4. น้ำหนัก (Weight)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('น้ำหนัก (Weight)',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                '${_weightRange.start.round()} - ${_weightRange.end.round()} กก.'),
                          ],
                        ),
                        RangeSlider(
                          values: _weightRange,
                          min: 0,
                          max: 1500,
                          divisions: 150, // ขยับทีละ 10 กก.
                          labels: RangeLabels(
                            '${_weightRange.start.round()} กก.',
                            '${_weightRange.end.round()} กก.',
                          ),
                          onChanged: (RangeValues values) {
                            setStateSheet(() {
                              _weightRange = values;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // --- Buttons Bottom ---
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Reset ค่าทั้งหมด
                            setStateSheet(() {
                              _selectedGender = null;
                              _selectedBreed = null;
                              _ageRange = const RangeValues(0, 20);
                              _weightRange = const RangeValues(0, 1500);
                            });
                          },
                          child: const Text('ล้างค่า (Reset)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            // TODO: ส่งค่า Filter กลับไปประมวลผลที่หน้าหลัก
                            Navigator.pop(context);
                            print(
                                "Filter: Breed=$_selectedBreed, Gender=$_selectedGender, Age=${_ageRange.start}-${_ageRange.end}, Weight=${_weightRange.start}-${_weightRange.end}");
                          },
                          child: const Text('ค้นหา (Apply)'),
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

  // Widget ย่อยสำหรับสร้าง Chip เลือกเพศ
  Widget _buildGenderChip(
      String label, String value, StateSetter setStateSheet) {
    final isSelected = _selectedGender == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setStateSheet(() {
          _selectedGender = selected ? value : null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Cows',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "My Cows",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // Cow List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                final cowId = 100 + index;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.pets,
                        color: theme.colorScheme.primary, size: 40),
                    title: Text('Cow #$cowId',
                        style: theme.textTheme.headlineSmall),
                    subtitle: Text('Name: Bessie ${index + 1}\nBreed: Brahman',
                        style: theme.textTheme.bodyMedium),
                    isThreeLine:
                        true, // เพิ่มบรรทัดเพื่อให้เห็นข้อมูลสายพันธุ์ตัวอย่าง
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/detail'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
