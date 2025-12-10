class OdooProduct {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? categoryId;
  final String? categoryName;
  final List<int>? publicCategoryIds;
  final List<String>? publicCategoryNames;
  final String? imageUrl;
  final double? quantityAvailable;
  final String? defaultCode;
  final String? barcode;
  final String? type;

  OdooProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.publicCategoryIds,
    this.publicCategoryNames,
    this.imageUrl,
    this.quantityAvailable,
    this.defaultCode,
    this.barcode,
    this.type,
  });

  factory OdooProduct.fromJson(Map<String, dynamic> json) {
      // Parse type (service/goods/combo)
      String? type = json['type'] is String ? json['type'] as String : null;
    // Handle category - can be a list [id, name] or just id
    int? categoryId;
    String? categoryName;
    final rawCateg = json['categ_id'];
    if (rawCateg != null) {
      if (rawCateg is List) {
        final category = rawCateg;
        categoryId = category.isNotEmpty && category[0] is int ? category[0] as int : null;
        categoryName = category.length > 1 && category[1] is String ? category[1] as String : null;
      } else if (rawCateg is int) {
        categoryId = rawCateg;
      } else {
        // Some Odoo instances return `false` or other non-int when no category is set.
        categoryId = null;
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

    // Parse public categories (many2many). Odoo may return:
    // - a list of ints: [1,2]
    // - a list of pairs: [[1, 'Name'], [2, 'Name']]
    // - a special command wrapper: [[6, 0, [1,2]]]
    List<int>? publicCategoryIds;
    List<String>? publicCategoryNames;
    if (json['public_categ_ids'] != null) {
      final rawVal = json['public_categ_ids'];
      if (rawVal is List) {
        // If wrapper like [[6,0,[1,2]]], extract the nested ids
        if (rawVal.isNotEmpty && rawVal.first is List && rawVal.first.length >= 3 && rawVal.first[0] == 6 && rawVal.first[2] is List) {
          final inner = rawVal.first[2] as List;
          publicCategoryIds = inner.whereType<int>().toList();
        } else {
          // Flatten possible [id] or [ [id,name], ... ]
          final ids = <int>[];
          final names = <String>[];
          for (var e in rawVal) {
            if (e is int) {
              ids.add(e);
            } else if (e is List && e.isNotEmpty) {
              // [id, name]
              final id = e[0];
              final name = e.length > 1 ? e[1] : null;
              if (id is int) ids.add(id);
              if (name is String) names.add(name);
            }
          }
          if (ids.isNotEmpty) publicCategoryIds = ids;
          if (names.isNotEmpty) publicCategoryNames = names;
        }
      }
    }

    // Defensive parsing for fields that may be booleans (false) instead of null/strings
    final nameVal = json['name'] is String ? json['name'] as String : '';
    final descVal = json['description'] is String ? json['description'] as String : null;
    final listPriceRaw = json['list_price'];
    final priceVal = listPriceRaw is num ? (listPriceRaw).toDouble() : 0.0;
    final qtyRaw = json['qty_available'];
    final qtyVal = qtyRaw is num ? (qtyRaw).toDouble() : null;
    final defaultCodeVal = json['default_code'] is String ? json['default_code'] as String : null;
    final barcodeVal = json['barcode'] is String ? json['barcode'] as String : null;

    return OdooProduct(
      id: json['id'] as int,
      name: nameVal,
      description: descVal,
      price: priceVal,
      categoryId: categoryId,
      categoryName: categoryName,
      publicCategoryIds: publicCategoryIds,
      publicCategoryNames: publicCategoryNames,
      imageUrl: imageUrl,
      quantityAvailable: qtyVal,
      defaultCode: defaultCodeVal,
      barcode: barcodeVal,
      type: type,
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
      'public_categ_ids': publicCategoryIds,
      'public_categ_names': publicCategoryNames,
      'image_1920': imageUrl,
      'qty_available': quantityAvailable,
      'default_code': defaultCode,
      'barcode': barcode,
      'type': type,
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
  final bool hasAppointment;
  final int? appointmentTypeId;
  final String? appointmentLink;
  final List<OdooSubService>? subServices;
  final List<int>? publicCategoryIds;
  final List<String>? publicCategoryNames;

  OdooService({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.defaultCode,
    this.hasAppointment = false,
    this.appointmentTypeId,
    this.appointmentLink,
    this.subServices,
    this.publicCategoryIds,
    this.publicCategoryNames,
  });

  factory OdooService.fromJson(Map<String, dynamic> json) {
    int? categoryId;
    String? categoryName;
    final rawCateg = json['categ_id'];
    if (rawCateg != null) {
      if (rawCateg is List) {
        final category = rawCateg;
        categoryId = category.isNotEmpty && category[0] is int ? category[0] as int : null;
        categoryName = category.length > 1 && category[1] is String ? category[1] as String : null;
      } else if (rawCateg is int) {
        categoryId = rawCateg;
      } else {
        // Handle cases where Odoo returns false or unexpected values for categ_id
        categoryId = null;
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

    // Parse public categories (same robust logic as for products)
    List<int>? publicCategoryIds;
    List<String>? publicCategoryNames;
    if (json['public_categ_ids'] != null) {
      final rawVal = json['public_categ_ids'];
      if (rawVal is List) {
        if (rawVal.isNotEmpty && rawVal.first is List && rawVal.first.length >= 3 && rawVal.first[0] == 6 && rawVal.first[2] is List) {
          final inner = rawVal.first[2] as List;
          publicCategoryIds = inner.whereType<int>().toList();
        } else {
          final ids = <int>[];
          final names = <String>[];
          for (var e in rawVal) {
            if (e is int) {
              ids.add(e);
            } else if (e is List && e.isNotEmpty) {
              final id = e[0];
              final name = e.length > 1 ? e[1] : null;
              if (id is int) ids.add(id);
              if (name is String) names.add(name);
            }
          }
          if (ids.isNotEmpty) publicCategoryIds = ids;
          if (names.isNotEmpty) publicCategoryNames = names;
        }
      }
    }

    final nameVal = json['name'] is String ? json['name'] as String : '';
    final descVal = json['description'] is String ? json['description'] as String : null;
    final listPriceRaw = json['list_price'];
    final priceVal = listPriceRaw is num ? (listPriceRaw).toDouble() : 0.0;
    final defaultCodeVal = json['default_code'] is String ? json['default_code'] as String : null;

    // Appointment-related fields - Multiple ways to detect appointment-based services:
    // 1. Explicit appointment flags (custom fields)
    // 2. Has appointment_type_id linked
    // 3. Product has "appointment" in description/internal notes
    // 4. Service type products linked to appointments
    final hasAppointmentTypeId = json['appointment_type_id'] != null && 
        json['appointment_type_id'] != false &&
        json['appointment_type_id'] != 0;
    
    final hasExplicitFlag = json['x_studio_has_appointment'] == true ||
        json['has_appointment'] == true ||
        json['x_has_appointment'] == true;
    
    // Consider it appointment-based if ANY indicator is present
    final hasAppointmentVal = hasAppointmentTypeId || hasExplicitFlag;

    final appointmentIdVal = json['appointment_type_id'] is List
        ? (json['appointment_type_id'] as List)[0] as int?
        : (json['appointment_type_id'] is int ? json['appointment_type_id'] as int? : null);

    final appointmentLinkVal = json['x_studio_appointment_link'] is String
        ? json['x_studio_appointment_link'] as String?
        : null;

    return OdooService(
      id: json['id'] as int,
      name: nameVal,
      description: descVal,
      price: priceVal,
      categoryId: categoryId,
      categoryName: categoryName,
      imageUrl: imageUrl,
      defaultCode: defaultCodeVal,
      hasAppointment: hasAppointmentVal,
      appointmentTypeId: appointmentIdVal,
      appointmentLink: appointmentLinkVal,
      publicCategoryIds: publicCategoryIds,
      publicCategoryNames: publicCategoryNames,
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
      'public_categ_ids': publicCategoryIds,
      'public_categ_names': publicCategoryNames,
      'image_1920': imageUrl,
      'default_code': defaultCode,
      'has_appointment': hasAppointment,
      'appointment_type_id': appointmentTypeId,
      'appointment_link': appointmentLink,
    };
  }
}

class OdooCategory {
  final int id;
  final String name;
  final int? parentId;
  final String? parentName;
  final String? imageUrl;

  OdooCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
    this.imageUrl,
  });

  factory OdooCategory.fromJson(Map<String, dynamic> json) {
    int? parentId;
    String? parentName;
    if (json['parent_id'] != null) {
      if (json['parent_id'] is List) {
        final p = json['parent_id'] as List;
        parentId = p.isNotEmpty ? p[0] as int? : null;
        parentName = p.length > 1 ? p[1] as String? : null;
      } else if (json['parent_id'] is int) {
        parentId = json['parent_id'] as int?;
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

    return OdooCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      parentId: parentId,
      parentName: parentName,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'parent_name': parentName,
      'image_1920': imageUrl,
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
  
  // Appointment-related fields
  final bool hasAppointment;
  final int? appointmentId;
  final String? appointmentLink;
  final List<String>? consultants;
  final String? meetingType;

  OdooSubService({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
    this.imageUrl,
    this.hasAppointment = false,
    this.appointmentId,
    this.appointmentLink,
    this.consultants,
    this.meetingType,
  });

  factory OdooSubService.fromJson(Map<String, dynamic> json) {
    final nameVal = json['name'] is String ? json['name'] as String : '';
    final descVal = json['description'] is String ? json['description'] as String : null;
    final priceRaw = json['list_price'];
    final priceVal = priceRaw is num ? (priceRaw).toDouble() : null;
    final durVal = json['duration_minutes'] is int ? json['duration_minutes'] as int : null;
    final imgVal = json['image_1920'] is String ? json['image_1920'] as String : null;
    
    // Parse appointment-related fields
    final hasAppointmentVal = json['x_studio_has_appointment'] == true || 
                              json['has_appointment'] == true ||
                              json['appointment_type_id'] != null && json['appointment_type_id'] != false;
    
    final appointmentIdVal = json['appointment_type_id'] is List 
        ? (json['appointment_type_id'] as List)[0] as int?
        : (json['appointment_type_id'] is int ? json['appointment_type_id'] as int? : null);
    
    final appointmentLinkVal = json['x_studio_appointment_link'] is String 
        ? json['x_studio_appointment_link'] as String? 
        : null;
    
    List<String>? consultantsVal;
    if (json['x_studio_consultants'] is List) {
      consultantsVal = (json['x_studio_consultants'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['staff_user_ids'] is List) {
      consultantsVal = (json['staff_user_ids'] as List)
          .where((e) => e is List && e.length > 1)
          .map((e) => (e as List)[1].toString())
          .toList();
    }
    
    final meetingTypeVal = json['appointment_tz'] is String 
        ? json['appointment_tz'] as String?
        : (json['x_studio_meeting_type'] is String ? json['x_studio_meeting_type'] as String? : null);

    return OdooSubService(
      id: json['id'] as int,
      name: nameVal,
      description: descVal,
      price: priceVal,
      durationMinutes: durVal,
      imageUrl: imgVal,
      hasAppointment: hasAppointmentVal,
      appointmentId: appointmentIdVal,
      appointmentLink: appointmentLinkVal,
      consultants: consultantsVal,
      meetingType: meetingTypeVal,
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


class OdooAppointmentType {
  final int id;
  final String name;
  final int? productId; // Link to the service product
  final double? duration; // Duration in hours
  final String? location;
  final String? websiteUrl; // URL to book

  OdooAppointmentType({
    required this.id,
    required this.name,
    this.productId,
    this.duration,
    this.location,
    this.websiteUrl,
  });

  factory OdooAppointmentType.fromJson(Map<String, dynamic> json) {
    int? productId;
    if (json['product_id'] != null) {
      if (json['product_id'] is List) {
        final p = json['product_id'] as List;
        productId = p.isNotEmpty ? p[0] as int? : null;
      } else {
        productId = json['product_id'] as int?;
      }
    }

    return OdooAppointmentType(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      productId: productId,
      duration: (json['appointment_duration'] as num?)?.toDouble(),
      location: json['location'] as String?,
      websiteUrl: json['website_url'] as String?, // Odoo 16+ usually has this or we construct it
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_id': productId,
      'appointment_duration': duration,
      'location': location,
      'website_url': websiteUrl,
    };
  }
}

/// Staff/Consultant model for appointment booking
class OdooStaff {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? imageUrl;

  OdooStaff({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.imageUrl,
  });

  factory OdooStaff.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['image_128'] != null && json['image_128'] is String) {
      final image = json['image_128'] as String;
      if (image.startsWith('http')) {
        imageUrl = image;
      } else if (image.isNotEmpty) {
        imageUrl = 'data:image/png;base64,$image';
      }
    }

    return OdooStaff(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      imageUrl: imageUrl,
    );
  }
}

/// Represents a single available time slot
class OdooAppointmentSlot {
  final DateTime startTime;
  final DateTime endTime;
  final int staffId;
  final String? staffName;

  OdooAppointmentSlot({
    required this.startTime,
    required this.endTime,
    required this.staffId,
    this.staffName,
  });

  String get formattedTime {
    final hour = startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get formattedTimeRange {
    final startHour = startTime.hour;
    final startMin = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour;
    final endMin = endTime.minute.toString().padLeft(2, '0');
    
    String formatHour(int h, int m) {
      final period = h >= 12 ? 'PM' : 'AM';
      final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$displayH:$m $period';
    }
    
    return '${formatHour(startHour, int.parse(startMin))} - ${formatHour(endHour, int.parse(endMin))}';
  }
}

/// Availability schedule for a day
class OdooAppointmentAvailability {
  final DateTime date;
  final List<OdooAppointmentSlot> slots;

  OdooAppointmentAvailability({
    required this.date,
    required this.slots,
  });
}
