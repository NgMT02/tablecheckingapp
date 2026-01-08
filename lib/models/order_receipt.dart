class OrderReceipt {
  const OrderReceipt({
    required this.orderId,
    required this.ticketNumber,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.createdAt,
    this.isOffline = false,
  });

  final String orderId;
  final String ticketNumber;
  final double subtotal;
  final double tax;
  final double total;
  final DateTime createdAt;
  final bool isOffline;

  factory OrderReceipt.fromJson(Map<String, dynamic> json) {
    return OrderReceipt(
      orderId: (json['orderId'] ?? json['id'] ?? '').toString(),
      ticketNumber: (json['ticketNumber'] ??
              json['queueNumber'] ??
              json['number'] ??
              '')
          .toString(),
      subtotal: _readDouble(json['subtotal']),
      tax: _readDouble(json['tax']),
      total: _readDouble(json['total']),
      createdAt: _readDateTime(json['createdAt']),
      isOffline: json['isOffline'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'ticketNumber': ticketNumber,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'isOffline': isOffline,
    };
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
