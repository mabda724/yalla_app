class RestaurantModel {
  final String id;
  final String ownerId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final String? logoUrl;
  final String? coverUrl;
  final String status;
  final double commissionRate;
  final double deliveryFee;
  final double minOrderAmount;
  final int avgPrepTime;
  final bool isOpen;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? avgRating;
  final int totalRatings;

  RestaurantModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.logoUrl,
    this.coverUrl,
    this.status = 'pending',
    this.commissionRate = 15.0,
    this.deliveryFee = 0,
    this.minOrderAmount = 0,
    this.avgPrepTime = 20,
    this.isOpen = false,
    this.latitude,
    this.longitude,
    this.address,
    this.avgRating,
    this.totalRatings = 0,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) => RestaurantModel(
        id: map['id'] as String,
        ownerId: map['owner_id'] as String,
        name: map['name'] as String? ?? '',
        nameAr: map['name_ar'] as String?,
        description: map['description'] as String?,
        descriptionAr: map['description_ar'] as String?,
        logoUrl: map['logo_url'] as String?,
        coverUrl: map['cover_url'] as String?,
        status: map['status'] as String? ?? 'pending',
        commissionRate: (map['commission_rate'] as num?)?.toDouble() ?? 15.0,
        deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
        minOrderAmount: (map['min_order_amount'] as num?)?.toDouble() ?? 0,
        avgPrepTime: map['avg_prep_time'] as int? ?? 20,
        isOpen: map['is_open'] as bool? ?? false,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        address: map['address'] as String?,
        avgRating: (map['avg_rating'] as num?)?.toDouble(),
        totalRatings: (map['total_ratings'] as int?) ?? 0,
      );
}

class MenuCategoryModel {
  final String id;
  final String restaurantId;
  final String name;
  final String? nameAr;
  final int sortOrder;
  final bool isAvailable;
  final List<MenuItemModel> items;

  MenuCategoryModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.nameAr,
    this.sortOrder = 0,
    this.isAvailable = true,
    this.items = const [],
  });

  factory MenuCategoryModel.fromMap(Map<String, dynamic> map) => MenuCategoryModel(
        id: map['id'] as String,
        restaurantId: map['restaurant_id'] as String,
        name: map['name'] as String? ?? '',
        nameAr: map['name_ar'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
        isAvailable: map['is_available'] as bool? ?? true,
      );
}

class MenuItemModel {
  final String id;
  final String restaurantId;
  final String categoryId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final double basePrice;
  final String? imageUrl;
  final bool isAvailable;
  final bool isBestSeller;
  final double? avgRating;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    required this.basePrice,
    this.imageUrl,
    this.isAvailable = true,
    this.isBestSeller = false,
    this.avgRating,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) => MenuItemModel(
        id: map['id'] as String,
        restaurantId: map['restaurant_id'] as String,
        categoryId: map['category_id'] as String,
        name: map['name'] as String? ?? '',
        nameAr: map['name_ar'] as String?,
        description: map['description'] as String?,
        descriptionAr: map['description_ar'] as String?,
        basePrice: (map['base_price'] as num?)?.toDouble() ?? 0,
        imageUrl: map['image_url'] as String?,
        isAvailable: map['is_available'] as bool? ?? true,
        isBestSeller: map['is_best_seller'] as bool? ?? false,
        avgRating: (map['avg_rating'] as num?)?.toDouble(),
      );
}
