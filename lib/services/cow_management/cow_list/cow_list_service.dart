import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import '../../../supabase_config.dart';
import 'package:logger/logger.dart';

final cowServiceProvider = ChangeNotifierProvider((ref) => CowService());

class CowService extends ChangeNotifier {
  final logger = Logger();
  List<Cow> _cows = [];
  bool _isLoading = false;

  List<Cow> get cows => _cows;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }


  // Fetch all cows that are not soft-deleted
  Future<void> fetchCows() async {
    _setLoading(true);
    try {
      final response = await supabase
          .from('animals')
          .select()
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      _cows = (response as List).map((data) => Cow.fromMap(data)).toList();
      logger.d("Fetched ${_cows.length} cows.");
    } catch (e) {
      logger.e('Error fetching cows: $e', error: e);
      // Optionally, set an error state here
    } finally {
      _setLoading(false);
    }
  }

  // Soft delete a cow
  Future<void> deleteCow(int id) async {
    _setLoading(true);
    try {
      await supabase
          .from('animals')
          .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('animal_id', id);

      // Remove the cow from the local list for immediate UI update
      _cows.removeWhere((cow) => cow.animalId == id);
      logger.i("Cow with ID $id soft-deleted successfully.");
    } catch (e) {
      logger.e('Error deleting cow: $e', error: e);
    } finally {
      _setLoading(false);
    }
  }
}
