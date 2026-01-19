import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BuyScreen extends ConsumerStatefulWidget {
  const BuyScreen({super.key});

  @override
  ConsumerState<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends ConsumerState<BuyScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตลาดซื้อขายวัว'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 10, // Mock Data
        itemBuilder: (context, index) {
          return _MarketItemCard(index: index);
        },
      ),
    );
  }
}

class _MarketItemCard extends StatefulWidget {
  final int index;

  const _MarketItemCard({required this.index});

  @override
  State<_MarketItemCard> createState() => _MarketItemCardState();
}

class _MarketItemCardState extends State<_MarketItemCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock Data
    final cowName = 'Daisy ${widget.index + 1}';
    final price = '${40 + widget.index * 2},000';
    final seller = 'ฟาร์มลุงแดง ${widget.index + 1}';
    const location = 'นครราชสีมา';

    // Mock Images & Breed Logic
    final String breed;
    final List<String> images;

    switch (widget.index % 3) {
      case 0:
        breed = 'Brahman';
        images = [
          'https://images.unsplash.com/photo-1546445317-29f4545e9d53?q=80&w=400',
          'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?q=80&w=400',
          'https://images.unsplash.com/photo-1500595046743-cd271d694d30?q=80&w=400',
        ];
        break;
      case 1:
        breed = 'Charolais';
        images = [
          'https://images.unsplash.com/photo-1596733430284-f7437764b1a9?q=80&w=400',
          'https://images.unsplash.com/photo-1536510233921-8e5043fce771?q=80&w=400',
          'https://images.unsplash.com/photo-1551651056-2cb4d5c9e330?q=80&w=400',
        ];
        break;
      default:
        breed = 'Angus';
        images = [
          'https://images.unsplash.com/photo-1527153857715-3908f2bae5e8?q=80&w=400',
          'https://images.unsplash.com/photo-1598556776374-0a47353379c9?q=80&w=400',
          'https://images.unsplash.com/photo-1612170153139-6f881d97f1f8?q=80&w=400',
        ];
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: 180.h,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      return Image.network(
                        images[pageIndex],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image_not_supported,
                                size: 50.r, color: Colors.grey),
                      );
                    },
                  ),
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '฿$price',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp),
                      ),
                    ),
                  ),
                  // Image Indicator (Dots)
                  Positioned(
                    bottom: 8.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
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

            // Details Section
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cowName,
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
                          breed,
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16.r, color: Colors.grey.shade600),
                      SizedBox(width: 4.w),
                      Text(
                        '$location • ผู้ขาย: $seller',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('ส่งคำเสนอซื้อสำหรับ $cowName แล้ว')),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('เสนอราคา'),
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