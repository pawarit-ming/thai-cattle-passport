import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CowDetailWidget extends StatelessWidget {
  final String title;
  // 1. เปลี่ยนจาก String? เป็น List<String> เพื่อรับหลายรูป
  final List<String> images;
  final List<Tab> tabs;
  final List<Widget> tabViews;
  final Widget? bottomBar;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? floatingActionButton;
  final TabController tabController;
  final bool isEditable;
  final VoidCallback? onImageTap;

  const CowDetailWidget({
    super.key,
    required this.title,
    // รับเป็น List แทน (ถ้าไม่มีให้ส่งเป็น empty list [])
    this.images = const [],
    required this.tabs,
    required this.tabViews,
    required this.tabController,
    this.bottomBar,
    this.actions,
    this.onBack,
    this.floatingActionButton,
    this.isEditable = false,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: BackButton(onPressed: onBack),
              actions: actions,
            ),
            // 2. เรียกใช้ Widget แสดงรูปภาพแบบสไลด์ที่สร้างขึ้นใหม่ด้านล่าง
            SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _ImageCarousel(
                  images: images,
                  isEditable: isEditable,
                  onTap: onImageTap,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 3.w,
                  tabs: tabs,
                ),
                backgroundColor: theme.scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: tabController,
          children: tabViews,
        ),
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

// --- Widget สำหรับแสดงรูปภาพแบบเลื่อนได้ (Carousel) ---
class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  final bool isEditable;
  final VoidCallback? onTap;

  const _ImageCarousel({
    required this.images,
    this.isEditable = false,
    this.onTap,
  });

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _currentIndex = 0;

  Widget _buildSingleImage(String? url) {
    if (url == null || url.isEmpty) {
      if (widget.isEditable) {
        return Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 48.r, color: Colors.grey[600]),
              SizedBox(height: 8.h),
              Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        );
      }
      return Container(
        color: Colors.grey[300],
        child: Image.asset('assets/images/cow.png', width: 80.r, height: 80.r),
      );
    }

    final isNetworkImage = url.startsWith('http');
    Widget imageWidget;

    if (isNetworkImage) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.error, size: 40.r, color: Colors.red),
        ),
      );
    } else {
      imageWidget = Image.file(File(url), fit: BoxFit.cover);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        if (widget.isEditable)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo,
                    size: 32.r, color: Theme.of(context).primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // กรณีไม่มีรูปเลย
    if (widget.images.isEmpty) {
      return GestureDetector(
        onTap: widget.isEditable ? widget.onTap : null,
        child: _buildSingleImage(null),
      );
    }

    return Stack(
      children: [
        // ส่วนแสดงรูปภาพ (Slide)
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: widget.isEditable ? widget.onTap : null,
              child: _buildSingleImage(widget.images[index]),
            );
          },
        ),

        // ส่วนจุดแสดงสถานะ (Indicators)
        if (widget.images.length > 1)
          Positioned(
            bottom: 10.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images.asMap().entries.map((entry) {
                return Container(
                  width: 8.w,
                  height: 8.h,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _StickyTabBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
