class OdooProduct {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final double? quantityAvailable;
  final String? defaultCode;
  final String? barcode;

  OdooProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.quantityAvailable,
    this.defaultCode,
    this.barcode,
  });

  factory OdooProduct.fromJson(Map<String, dynamic> json) {
    // Handle category - can be a list [id, name] or just id
    int? categoryId;
    String? categoryName;
    if (json['categ_id'] != null) {
      if (json['categ_id'] is List) {
        final category = json['categ_id'] as List;
        categoryId = category.isNotEmpty ? category[0] as int? : null;
        categoryName = category.length > 1 ? category[1] as String? : null;
      } else {
        categoryId = json['categ_id'] as int?;
      }
    }

    // Handle image - Odoo stores as base64 or URL
    String? imageUrl;
    if (json['image_1920'] != null && json['image_1920'] is String) {
      final image = json['image_1920'] as String;
      if (image.startsWith('http')) {
        imageUrl = image;
      } else if (image.isNotEmpty) {
        // Base64 image - you may need to convert this
        imageUrl = 'data:image/png;base64,$image';
      }
    }

    return OdooProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['list_price'] as num?)?.toDouble() ?? 0.0,
      categoryId: categoryId,
      categoryName: categoryName,
      imageUrl: imageUrl,
      quantityAvailable: (json['qty_available'] as num?)?.toDouble(),
      defaultCode: json['default_code'] as String?,
      barcode: json['barcode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'list_price': price,
      'categ_id': categoryId,
      'categ_name': categoryName,
      'image_1920': imageUrl,
      'qty_available': quantityAvailable,
      'default_code': defaultCode,
      'barcode': barcode,
    };
  }
}

class OdooService {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String? defaultCode;
  final List<OdooSubService>? subServices;

  OdooService({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.defaultCode,
    this.subServices,
  });

  factory OdooService.fromJson(Map<String, dynamic> json) {
    int? categoryId;
    String? categoryName;
    if (json['categ_id'] != null) {
      if (json['categ_id'] is List) {
        final category = json['categ_id'] as List;
        categoryId = category.isNotEmpty ? category[0] as int? : null;
        categoryName = category.length > 1 ? category[1] as String? : null;
      } else {
        categoryId = json['categ_id'] as int?;
      }
    }

    String? imageUrl;
    if (json['image_1920'] != null && json['image_1920'] is String) {
      final image = json['image_1920'] as String;
      if (image.startsWith('http')) {
        imageUrl = image;
      } else if (image.isNotEmpty) {
        imageUrl = 'data:image/png;base64,$image';
      }
    }

    return OdooService(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['list_price'] as num?)?.toDouble() ?? 0.0,
      categoryId: categoryId,
      categoryName: categoryName,
      imageUrl: imageUrl,
      defaultCode: json['default_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'list_price': price,
      'categ_id': categoryId,
      'categ_name': categoryName,
      'image_1920': imageUrl,
      'default_code': defaultCode,
    };
  }
}

class OdooSubService {
  final int id;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final String? imageUrl;

  OdooSubService({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
    this.imageUrl,
  });

  factory OdooSubService.fromJson(Map<String, dynamic> json) {
    return OdooSubService(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['list_price'] as num?)?.toDouble(),
      durationMinutes: json['duration_minutes'] as int?,
      imageUrl: json['image_1920'] as String?,
    );
  }
}

class OdooEvent {
  final int id;
  final String name;
  final String? description;
  final DateTime? dateBegin;
  final DateTime? dateEnd;
  final String? address;
  final int? seatsAvailability;
  final int? seatsAvailable;
  final String? eventType;
  final String? imageUrl;

  OdooEvent({
    required this.id,
    required this.name,
    this.description,
    this.dateBegin,
    this.dateEnd,
    this.address,
    this.seatsAvailability,
    this.seatsAvailable,
    this.eventType,
    this.imageUrl,
  });

  factory OdooEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    String? address;
    if (json['address_id'] != null) {
      if (json['address_id'] is List) {
        final addr = json['address_id'] as List;
        address = addr.length > 1 ? addr[1] as String? : null;
      } else if (json['address_id'] is Map) {
        final addr = json['address_id'] as Map<String, dynamic>;
        address = addr['display_name'] as String?;
      }
    }

    String? eventType;
    if (json['event_type_id'] != null) {
      if (json['event_type_id'] is List) {
        final type = json['event_type_id'] as List;
        eventType = type.length > 1 ? type[1] as String? : null;
      }
    }

    String? imageUrl;
    if (json['image_1920'] != null && json['image_1920'] is String) {
      final image = json['image_1920'] as String;
      if (image.startsWith('http')) {
        imageUrl = image;
      } else if (image.isNotEmpty) {
        imageUrl = 'data:image/png;base64,$image';
      }
    }

    return OdooEvent(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      dateBegin: parseDate(json['date_begin'] as String?),
      dateEnd: parseDate(json['date_end'] as String?),
      address: address,
      seatsAvailability: json['seats_availability'] as int?,
      seatsAvailable: json['seats_available'] as int?,
      eventType: eventType,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date_begin': dateBegin?.toIso8601String(),
      'date_end': dateEnd?.toIso8601String(),
      'address': address,
      'seats_availability': seatsAvailability,
      'seats_available': seatsAvailable,
      'event_type': eventType,
      'image_url': imageUrl,
    };
  }
}

class OdooStock {
  final int id;
  final int productId;
  final String? locationName;
  final double quantity;
  final double reservedQuantity;

  OdooStock({
    required this.id,
    required this.productId,
    this.locationName,
    required this.quantity,
    required this.reservedQuantity,
  });

  factory OdooStock.fromJson(Map<String, dynamic> json) {
    String? locationName;
    if (json['location_id'] != null) {
      if (json['location_id'] is List) {
        final location = json['location_id'] as List;
        locationName = location.length > 1 ? location[1] as String? : null;
      }
    }

    int? productId;
    if (json['product_id'] != null) {
      if (json['product_id'] is List) {
        final product = json['product_id'] as List;
        productId = product.isNotEmpty ? product[0] as int? : null;
      } else {
        productId = json['product_id'] as int?;
      }
    }

    return OdooStock(
      id: json['id'] as int,
      productId: productId ?? 0,
      locationName: locationName,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      reservedQuantity: (json['reserved_quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


