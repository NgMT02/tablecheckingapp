import 'package:flutter/foundation.dart';

import '../models/table_entry.dart';
import '../services/table_lookup_service.dart';

enum TableLookupStatus { idle, loading, success, notFound, error }

class TableLookupViewModel extends ChangeNotifier {
  TableLookupViewModel({required TableLookupService service})
      : _service = service;

  final TableLookupService _service;

  TableLookupStatus status = TableLookupStatus.idle;
  TableEntry? result;
  String? message;

  bool get isLoading => status == TableLookupStatus.loading;

  Future<void> lookup(String phone) async {
    status = TableLookupStatus.loading;
    message = null;
    result = null;
    notifyListeners();

    try {
      final entry = await _service.lookupTableByPhone(phone);
      result = entry;
      status = TableLookupStatus.success;
    } on TableNotFoundException catch (e) {
      status = TableLookupStatus.notFound;
      message = e.message;
    } on FormatException catch (e) {
      status = TableLookupStatus.error;
      message = e.message;
    } on LookupException catch (e) {
      status = TableLookupStatus.error;
      message = e.message;
    } on Exception catch (e) {
      status = TableLookupStatus.error;
      message = 'Something went wrong: $e';
    } finally {
      notifyListeners();
    }
  }
}
