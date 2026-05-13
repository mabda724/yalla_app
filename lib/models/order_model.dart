class OrderModel {
  final String id;
  final String customerId;
  final String restaurantId;
  final String? riderId;
  final String? addressId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderType;
  final bool isGroupOrder;
  final String? groupCode;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.riderId,
    this.addressId,
    this.status = 'pending',
    required this.subtotal,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.orderType = 'instant',
    this.isGroupOrder = false,
    this.groupCode,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] as String,
        customerId: map['customer_id'] as String,
        restaurantId: map['restaurant_id'] as String,
        riderId: map['rider_id'] as String?,
        addressId: map['address_id'] as String?,
        status: map['status'] as String? ?? 'pending',
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
        serviceFee: (map['service_fee'] as num?)?.toDouble() ?? 0,
        discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
        totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: map['payment_method'] as String? ?? 'cod',
        paymentStatus: map['payment_status'] as String? ?? 'unpaid',
        orderType: map['order_type'] as String? ?? 'instant',
        isGroupOrder: map['is_group_order'] as bool? ?? false,
        groupCode: map['group_code'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  String get statusLabel {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'accepted': return 'تم القبول';
      case 'preparing': return 'جاري التجهيز';
      case 'ready': return 'جاهز';
      case 'rider_assigned': return 'Rider في الطريق';
      case 'picked_up': return 'تم الاستلام';
      case 'out_for_delivery': return 'في الطريق إليك';
      case 'delivered': return 'تم التوصيل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}

class CartItemModel {
  final String id;
  final String itemId;
  final String name;
  final double unitPrice;
  int quantity;
  final String? variationName;
  final List<Map<String, dynamic>> addons;
  final String? specialInstructions;
  final String? imageUrl;

  CartItemModel({
    required this.id,
    required this.itemId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
    this.variationName,
    this.addons = const [],
    this.specialInstructions,
    this.imageUrl,
  });

  double get totalPrice {
    double addonTotal = 0;
    for (final addon in addons) {
      addonTotal += (addon['price'] as num?)?.toDouble() ?? 0;
    }
    return (unitPrice + addonTotal) * quantity;
  }
}
