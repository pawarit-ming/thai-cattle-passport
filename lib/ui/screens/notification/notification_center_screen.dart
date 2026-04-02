import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:th_cow_passport/services/notification/farm_alert_model.dart';
import 'package:th_cow_passport/services/notification/farm_alert_service.dart';

// ─── Palette (aligned with Earth Tone theme) ───────────────────────────────
abstract final class _C {
  static const primary      = Color(0xFF795548);
  static const primaryLight = Color(0xFFD7CCC8);
  static const surface      = Colors.white;
  static const bg           = Color(0xFFF5F5F5);
  static const textPrimary  = Color(0xFF3E2723);
  static const textSecondary= Color(0xFF8D6E63);

  // urgency
  static const overdueText  = Color(0xFFBF360C);

  static const todayText    = Color(0xFFE65100);

  static const upcomingText = Color(0xFF2E7D32);
}

// ─── Urgency helpers ────────────────────────────────────────────────────────
extension _AlertExt on AlertUrgency {
  String get label => switch (this) {
        AlertUrgency.overdue  => 'เลยกำหนด',
        AlertUrgency.today    => 'วันนี้',
        AlertUrgency.upcoming => 'เร็วๆ นี้',
      };

  Color get textColor => switch (this) {
        AlertUrgency.overdue  => _C.overdueText,
        AlertUrgency.today    => _C.todayText,
        AlertUrgency.upcoming => _C.upcomingText,
      };

}

// ─── Screen ─────────────────────────────────────────────────────────────────
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});
  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {

  /// null = ทั้งหมด
  AlertUrgency? _filter;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(farmAlertsProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        title: Text(
          'การแจ้งเตือน',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: _C.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'แสดงการแจ้งเตือนที่ dismiss ไปแล้ว',
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _C.textSecondary),
              onPressed: () async {
                await ref.read(farmAlertServiceProvider).clearAllDismissed();
                ref.invalidate(farmAlertsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('แสดงทั้งหมดแล้ว',
                          style: GoogleFonts.prompt()),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),

      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
        ),
        data: (all) {
          final pending = all.toList()
            ..sort((a, b) => a.urgency.index.compareTo(b.urgency.index));

          final overdueCnt =
              pending.where((a) => a.urgency == AlertUrgency.overdue).length;
          final todayCnt =
              pending.where((a) => a.urgency == AlertUrgency.today).length;
          final upcomingCnt =
              pending.where((a) => a.urgency == AlertUrgency.upcoming).length;

          final filtered = _filter == null
              ? pending
              : pending.where((a) => a.urgency == _filter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Filter chips ──────────────────────────────────────────
              _FilterBar(
                selected: _filter,
                overdueCnt: overdueCnt,
                todayCnt: todayCnt,
                upcomingCnt: upcomingCnt,
                onSelect: (v) => setState(() => _filter = v),
              ),

              // (Removed swipe hint)

              // ── List ─────────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: _C.primary,
                  onRefresh: () async {
                    ref.invalidate(farmAlertsProvider);
                    try {
                      await ref.read(farmAlertsProvider.future);
                    } catch (_) {}
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            _EmptyState(
                              hasAnyPending: pending.isNotEmpty,
                              filter: _filter,
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => _AlertCard(
                            alert: filtered[i],
                            isLast: i == filtered.length - 1,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Filter chip bar ─────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final AlertUrgency? selected;
  final int overdueCnt, todayCnt, upcomingCnt;
  final ValueChanged<AlertUrgency?> onSelect;

  const _FilterBar({
    required this.selected,
    required this.overdueCnt,
    required this.todayCnt,
    required this.upcomingCnt,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surface,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'ทั้งหมด',
              count: overdueCnt + todayCnt + upcomingCnt,
              isSelected: selected == null,
              color: _C.primary,
              onTap: () => onSelect(null),
            ),
            SizedBox(width: 8.w),
            _Chip(
              label: 'เลยกำหนด',
              count: overdueCnt,
              isSelected: selected == AlertUrgency.overdue,
              color: _C.overdueText,
              onTap: () => onSelect(
                selected == AlertUrgency.overdue ? null : AlertUrgency.overdue,
              ),
            ),
            SizedBox(width: 8.w),
            _Chip(
              label: 'วันนี้',
              count: todayCnt,
              isSelected: selected == AlertUrgency.today,
              color: _C.todayText,
              onTap: () => onSelect(
                selected == AlertUrgency.today ? null : AlertUrgency.today,
              ),
            ),
            SizedBox(width: 8.w),
            _Chip(
              label: 'เร็วๆ นี้',
              count: upcomingCnt,
              isSelected: selected == AlertUrgency.upcoming,
              color: _C.upcomingText,
              onTap: () => onSelect(
                selected == AlertUrgency.upcoming
                    ? null
                    : AlertUrgency.upcoming,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color : _C.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : _C.primaryLight,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _C.textSecondary,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.prompt(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ── Alert Card ────────────────────────────────────────────────────────────────
class _AlertCard extends ConsumerWidget {
  final FarmAlert alert;
  final bool isLast;
  const _AlertCard({required this.alert, required this.isLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgency = alert.urgency;
    final accentColor = urgency.textColor;
    final diff = alert.dueDate.difference(DateTime.now()).inDays;
    final dayLabel = diff < 0
        ? 'เลย ${diff.abs()} วันแล้ว'
        : diff == 0
            ? 'วันนี้'
            : 'อีก $diff วัน';

    return GestureDetector(
      onTap: () => context.push('/detail/${alert.cowId}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _C.primaryLight.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── แถบสีซ้าย (urgency accent) ─────────────────────────
                Container(width: 5.w, color: accentColor),

                // ── icon container ──────────────────────────────────────
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: alert.type.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: alert.type.assetIcon != null
                      ? Image.asset(alert.type.assetIcon!, width: 22.r, height: 22.r)
                      : Icon(alert.type.icon, color: alert.type.iconColor, size: 22.r),
                ),

                // ── เนื้อหา ─────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 12.h, bottom: 12.h, right: 0.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // แถวบน: ชื่อวัว
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.cowName,
                                style: GoogleFonts.prompt(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _C.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),

                        // ชื่อ task
                        Text(
                          alert.type.titleTh,
                          style: GoogleFonts.prompt(
                            fontSize: 13.sp,
                            color: _C.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6.h),

                        // วันที่ + เหลือกี่วัน
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12.r, color: _C.textSecondary),
                            SizedBox(width: 4.w),
                            Text(
                              '${_thaiDate(alert.dueDate)}  ·  $dayLabel',
                              style: GoogleFonts.prompt(
                                fontSize: 11.sp,
                                color: diff < 0 ? accentColor : _C.textSecondary,
                                fontWeight: diff < 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _thaiDate(DateTime d) {
    const m = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year + 543}';
  }
}


// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasAnyPending;
  final AlertUrgency? filter;
  const _EmptyState({this.hasAnyPending = false, this.filter});

  @override
  Widget build(BuildContext context) {
    final label = filter == null
        ? 'ไม่มีการแจ้งเตือน 🎉'
        : 'ไม่มีรายการ "${filter!.label}"';
    final sub = hasAnyPending && filter != null
        ? 'ลองเปลี่ยน filter ดูครับ'
        : 'ฟาร์มดูแลดีมาก ไม่มีงานค้างชำระ';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.r, height: 80.r,
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.task_alt_rounded,
                size: 40.r, color: _C.primary.withValues(alpha: 0.5)),
          ),
          SizedBox(height: 16.h),
          Text(label,
              style: GoogleFonts.prompt(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: _C.textPrimary)),
          SizedBox(height: 4.h),
          Text(sub,
              style: GoogleFonts.prompt(
                  fontSize: 13.sp, color: _C.textSecondary)),
        ],
      ),
    );
  }
}


