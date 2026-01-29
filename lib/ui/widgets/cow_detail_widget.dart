import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CowDetailWidget extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final List<Tab> tabs;
  final List<Widget> tabViews;
  final Widget? bottomBar;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? floatingActionButton;
  final TabController tabController;

  const CowDetailWidget({
    super.key,
    required this.title,
    this.imageUrl,
    required this.tabs,
    required this.tabViews,
    required this.tabController,
    this.bottomBar,
    this.actions,
    this.onBack,
    this.floatingActionButton,
  });

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.pets, size: 80.r, color: Colors.grey[400]),
      );
    }

    final isNetworkImage = url.startsWith('http');

    return isNetworkImage
        ? Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: Icon(Icons.error, size: 40.r, color: Colors.red),
          ),)
        : Image.file(File(url), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // ส่วนหัวที่เลื่อนเก็บได้
            SliverAppBar(
              pinned: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              centerTitle: true,
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: BackButton(onPressed: onBack),
              actions: actions,
            ),
            // ส่วนรูปภาพวัว
            SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImage(imageUrl),
              ),
            ),
            // ส่วน TabBar ที่จะค้างอยู่ด้านบน (Sticky)
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
        // ส่วนเนื้อหาที่จะเปลี่ยนไปตาม Tab
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

// Helper Class สำหรับ Sticky TabBar
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


