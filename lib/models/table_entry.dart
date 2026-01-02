class TableEntry {
  final String phoneNumber;
  final String tableNumber;

  TableEntry({required this.phoneNumber, required this.tableNumber});

  factory TableEntry.fromJson(Map<String, dynamic> json) {
    String _stringValue(String key) => (json[key] ?? '').toString().trim();

    // Support multiple key names the Cloud Run backend might return.
    final phone = _stringValue('phoneNumber').isNotEmpty
        ? _stringValue('phoneNumber')
        : (_stringValue('phone').isNotEmpty
            ? _stringValue('phone')
            : _stringValue('phone_no'));

    final table = _stringValue('tableNumber').isNotEmpty
        ? _stringValue('tableNumber')
        : (_stringValue('table').isNotEmpty
            ? _stringValue('table')
            : (_stringValue('table_no').isNotEmpty
                ? _stringValue('table_no')
                : _stringValue('tableNo')));

    return TableEntry(
      phoneNumber: phone,
      tableNumber: table,
    );
  }
}
