import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/ui/screens/cow_list/widgets/cow_card.dart';

class OffspringPreviewSection extends ConsumerWidget {
  final int cowId;

  const OffspringPreviewSection({super.key, required this.cowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final offspringAsync = ref.watch(offspringProvider(cowId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Text(
            'ลูกโค',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        offspringAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
              child:
                  Text('Error: $error', style: TextStyle(color: Colors.red))),
          data: (offspring) {
            if (offspring.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16.r),
                child: Center(
                  child: Text(
                    'ไม่มีข้อมูลลูกโค',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            final showViewMore = offspring.length > 5;
            final displayList =
                showViewMore ? offspring.take(5).toList() : offspring;

            return Column(
              children: [
                ...displayList.map((cow) => CowCard(
                      cow: cow,
                      onSelect:
                          () {}, // Provide empty callback for read-only view
                    )),
                if (showViewMore)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Navigate to full OffspringTab view
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar:
                                    AppBar(title: const Text('ข้อมูลลูกโค')),
                                body: OffspringTab(cowId: cowId),
                              ),
                            ),
                          );
                        },
                        child: const Text('ดูเพิ่มเติม'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class OffspringTab extends ConsumerWidget {
  final int cowId;
  const OffspringTab({super.key, required this.cowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offspringAsync = ref.watch(offspringProvider(cowId));

    return offspringAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('เกิดข้อผิดพลาด: $error')),
      data: (offspring) {
        if (offspring.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.family_restroom_outlined,
                    size: 48.r, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'ไม่มีข้อมูลลูกโค',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(offspringProvider(cowId).future),
          child: ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: offspring.length,
            itemBuilder: (context, index) {
              return CowCard(
                cow: offspring[index],
                onSelect: () {}, // Not used in view mode
              );
            },
          ),
        );
      },
    );
  }
}
