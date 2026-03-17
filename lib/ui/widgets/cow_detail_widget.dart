import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/widgets/common/app_segmented_tab.dart';

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
  final Widget? banner;
  final Widget? profileHeader;

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
    this.banner,
    this.profileHeader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),

              automaticallyImplyLeading: false,
              // ถ้าไม่มี onBack ให้ใช้ SizedBox.shrink() แทน null เพื่อความชัวร์
              leading: onBack != null
                  ? BackButton(onPressed: onBack)
                  : const SizedBox.shrink(),
              // ถ้าไม่มี onBack ให้ตั้งความกว้างเป็น 0 ไปเลย
              leadingWidth: onBack != null ? null : 0,

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
            // Banner (เช่น แจ้งเตือนวัวตาย)
            if (banner != null) SliverToBoxAdapter(child: banner!),
            // Profile Header (ดึงจาก Detail Screen มาใส่เพื่อให้มันอยู่เหนือ Tab และไม่หายไปตอนสลับ Tab)
            if (profileHeader != null)
              SliverToBoxAdapter(child: profileHeader!),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: AppSegmentedTab(
                  controller: tabController,
                  tabs: tabs,
                ),
                height: 64.h,
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
              onTap: widget.isEditable
                  ? widget.onTap
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _FullScreenImageViewer(
                            images: widget.images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
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
  final Widget child;
  final double height;
  final Color backgroundColor;

  _StickyTabBarDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child ||
        height != oldDelegate.height ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final url = widget.images[index];
              final isNetworkImage = url.startsWith('http');
              final imageProvider = isNetworkImage
                  ? NetworkImage(url)
                  : FileImage(File(url)) as ImageProvider;

              return InteractiveViewer(
                clipBehavior: Clip.none,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 10.w,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30.r),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
