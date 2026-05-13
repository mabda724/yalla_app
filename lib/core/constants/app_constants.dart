class AppConstants {
  AppConstants._();

  static const String appName = 'يالا';
  static const String appNameEn = 'Yalla';
  static const String appTagline = 'طلبك يوصل في السريع ⚡';

  // Roles
  static const String roleCustomer = 'customer';
  static const String roleRestaurant = 'restaurant';
  static const String roleRider = 'rider';
  static const String roleAdmin = 'admin';

  // Order statuses
  static const String orderPending = 'pending';
  static const String orderAccepted = 'accepted';
  static const String orderPreparing = 'preparing';
  static const String orderReady = 'ready';
  static const String orderRiderAssigned = 'rider_assigned';
  static const String orderPickedUp = 'picked_up';
  static const String orderOutForDelivery = 'out_for_delivery';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';

  // Payment methods
  static const String paymentCOD = 'cod';
  static const String paymentCard = 'card';
  static const String paymentInstaPay = 'instapay';
  static const String paymentVodafoneCash = 'vodafone_cash';
  static const String paymentWallet = 'wallet';

  // Storage buckets
  static const String bucketRestaurants = 'restaurants';
  static const String bucketRiders = 'riders';
  static const String bucketItems = 'menu_items';

  // Gamification
  static const int xpPerOrder = 50;
  static const int xpDigitalPayment = 25;
  static const int xpPerLevel = 200;

  // Pagination
  static const int pageSize = 20;
}
