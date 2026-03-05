import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider ที่ดึงจำนวนรายการ Offer ที่ status = 'pending'
/// สำหรับผู้ขาย (seller_id = current user)
final pendingOfferCountProvider = StreamProvider<int>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return Stream.value(0);
  }

  // ใช้ Supabase Realtime Stream เพื่ออัปเดตตัวเลขแบบ live
  return Supabase.instance.client
      .from('offers')
      .stream(primaryKey: ['id'])
      .eq('seller_id', user.id)
      .map((rows) {
        // นับเฉพาะ offer ที่ status = 'pending'
        return rows.where((row) => row['status'] == 'pending').length;
      });
});
