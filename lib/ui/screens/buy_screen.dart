import 'package:flutter/material.dart';

class BuyScreen extends StatelessWidget {
  const BuyScreen({super.key});

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
        padding: const EdgeInsets.all(16),
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
    final location = 'นครราชสีมา';

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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              height: 180,
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
                            const Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                      );
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '฿$price',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  // Image Indicator (Dots)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
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
              padding: const EdgeInsets.all(16.0),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          breed,
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '$location • ผู้ขาย: $seller',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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