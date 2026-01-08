import 'dart:convert';
import 'dart:typed_data';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.isPopular = false,
    this.imageUrl,
    this.imageBase64,
    this.assetPath,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final bool isPopular;
  final String? imageUrl;
  final String? imageBase64;
  final String? assetPath;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: (json['id'] ?? json['menuId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'Menu').toString(),
      price: _readPrice(json['price']),
      isPopular: json['isPopular'] == true,
      imageUrl: _readOptionalString(json['imageUrl'] ?? json['image_url']),
      imageBase64: _readOptionalString(
        json['imageBase64'] ?? json['image_base64'] ?? json['image'],
      ),
      assetPath: _readOptionalString(
        json['assetPath'] ?? json['asset_path'] ?? json['imageAsset'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'isPopular': isPopular,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'assetPath': assetPath,
    };
  }

  static double _readPrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String? _readOptionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Uint8List? get imageBytes {
    final raw = imageBase64?.trim();
    if (raw == null || raw.isEmpty) return null;
    final cleaned = raw.contains(',') ? raw.split(',').last : raw;
    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }
}
