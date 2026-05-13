-- =============================================================
-- YALLA SUPER APP - COMPLETE DATABASE SCHEMA
-- Food & Grocery Delivery Platform for Gen Z
-- Target: 100k+ users/month
-- =============================================================

-- =============================================================
-- 1. PROFILES (Extended Auth)
-- =============================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone_number TEXT UNIQUE,
  email TEXT UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('customer', 'restaurant', 'rider', 'admin')),
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  banned_at TIMESTAMPTZ,
  ban_reason TEXT,
  preferred_language TEXT DEFAULT 'ar',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_phone ON profiles(phone_number);

-- =============================================================
-- 2. RESTAURANTS
-- =============================================================
CREATE TABLE restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  logo_url TEXT,
  cover_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'rejected')),
  commission_rate DECIMAL(5,2) DEFAULT 15.00,
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  avg_prep_time INT DEFAULT 20, -- minutes
  is_open BOOLEAN DEFAULT false,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  address TEXT,
  address_details TEXT,
  phone TEXT,
  total_ratings INT DEFAULT 0,
  avg_rating DECIMAL(3,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_restaurants_owner ON restaurants(owner_id);
CREATE INDEX idx_restaurants_status ON restaurants(status);
CREATE INDEX idx_restaurants_location ON restaurants(latitude, longitude);

-- =============================================================
-- 3. RESTAURANT DOCUMENTS
-- =============================================================
CREATE TABLE restaurant_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('commercial_registry', 'tax_card', 'license', 'owner_id', 'other')),
  document_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rest_docs_restaurant ON restaurant_documents(restaurant_id);

-- =============================================================
-- 4. RESTAURANT HOURS
-- =============================================================
CREATE TABLE restaurant_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  open_time TIME,
  close_time TIME,
  is_closed BOOLEAN DEFAULT false,
  UNIQUE(restaurant_id, day_of_week)
);

CREATE INDEX idx_hours_restaurant ON restaurant_hours(restaurant_id);

-- =============================================================
-- 5. CUISINE TYPES
-- =============================================================
CREATE TABLE cuisine_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  icon_url TEXT,
  sort_order INT DEFAULT 0
);

CREATE TABLE restaurant_cuisines (
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  cuisine_id UUID NOT NULL REFERENCES cuisine_types(id) ON DELETE CASCADE,
  PRIMARY KEY (restaurant_id, cuisine_id)
);

-- =============================================================
-- 6. MENU CATEGORIES
-- =============================================================
CREATE TABLE menu_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  image_url TEXT,
  sort_order INT DEFAULT 0,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_menu_cat_restaurant ON menu_categories(restaurant_id);

-- =============================================================
-- 7. MENU ITEMS
-- =============================================================
CREATE TABLE menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES menu_categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  base_price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  prep_time INT, -- minutes
  is_available BOOLEAN DEFAULT true,
  is_best_seller BOOLEAN DEFAULT false,
  is_new BOOLEAN DEFAULT false,
  is_chef_special BOOLEAN DEFAULT false,
  calories INT,
  sort_order INT DEFAULT 0,
  total_orders INT DEFAULT 0,
  avg_rating DECIMAL(3,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_menu_items_category ON menu_items(category_id);
CREATE INDEX idx_menu_items_restaurant ON menu_items(restaurant_id);
CREATE INDEX idx_menu_items_bestseller ON menu_items(restaurant_id, is_best_seller) WHERE is_best_seller = true;

-- =============================================================
-- 8. ITEM VARIATIONS (Sizes)
-- =============================================================
CREATE TABLE item_variations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  price_adjustment DECIMAL(10,2) DEFAULT 0,
  is_default BOOLEAN DEFAULT false,
  sort_order INT DEFAULT 0
);

CREATE INDEX idx_variations_item ON item_variations(item_id);

-- =============================================================
-- 9. ADD-ONS
-- =============================================================
CREATE TABLE addon_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  max_addons INT DEFAULT 5,
  sort_order INT DEFAULT 0
);

CREATE TABLE addons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES addon_groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  price DECIMAL(10,2) NOT NULL,
  is_available BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0
);

CREATE INDEX idx_addons_group ON addons(group_id);

-- =============================================================
-- 10. MODIFIERS (Required Choices)
-- =============================================================
CREATE TABLE modifier_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  type TEXT NOT NULL CHECK (type IN ('single', 'multi')),
  is_required BOOLEAN DEFAULT false,
  min_selections INT DEFAULT 1,
  max_selections INT DEFAULT 1,
  sort_order INT DEFAULT 0
);

CREATE TABLE modifier_choices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES modifier_groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  price_adjustment DECIMAL(10,2) DEFAULT 0,
  is_default BOOLEAN DEFAULT false,
  is_available BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0
);

CREATE INDEX idx_modifier_choices_group ON modifier_choices(group_id);

-- =============================================================
-- 11. TAGS
-- =============================================================
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  icon_url TEXT
);

CREATE TABLE item_tags (
  item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (item_id, tag_id)
);

-- =============================================================
-- 12. COMBOS (Meal Deals)
-- =============================================================
CREATE TABLE combos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  image_url TEXT,
  combo_price DECIMAL(10,2) NOT NULL,
  savings_text TEXT, -- e.g., "وفر $3"
  is_available BOOLEAN DEFAULT true,
  valid_from TIMESTAMPTZ,
  valid_until TIMESTAMPTZ,
  total_orders INT DEFAULT 0,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_combos_restaurant ON combos(restaurant_id);

CREATE TABLE combo_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  combo_id UUID NOT NULL REFERENCES combos(id) ON DELETE CASCADE,
  label TEXT, -- e.g., "اختر البرجر", "اختر المشروب"
  label_ar TEXT,
  min_selections INT DEFAULT 1,
  max_selections INT DEFAULT 1,
  sort_order INT DEFAULT 0
);

CREATE TABLE combo_allowed_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  combo_item_id UUID NOT NULL REFERENCES combo_items(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  variation_id UUID REFERENCES item_variations(id),
  is_default BOOLEAN DEFAULT false
);

CREATE INDEX idx_combo_allowed ON combo_allowed_items(combo_item_id);

-- =============================================================
-- 13. FORMATIONS (Set Meals)
-- =============================================================
CREATE TABLE formations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  total_price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  available_from TIME,
  available_until TIME,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE formation_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  formation_id UUID NOT NULL REFERENCES formations(id) ON DELETE CASCADE,
  label TEXT,
  label_ar TEXT,
  slot_type TEXT NOT NULL CHECK (slot_type IN ('optional', 'required')),
  min_selections INT DEFAULT 0,
  max_selections INT DEFAULT 1,
  sort_order INT DEFAULT 0
);

CREATE TABLE formation_slot_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slot_id UUID NOT NULL REFERENCES formation_slots(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  variation_id UUID REFERENCES item_variations(id),
  price_adjustment DECIMAL(10,2) DEFAULT 0,
  is_default BOOLEAN DEFAULT false
);

-- =============================================================
-- 14. FLASH SALES
-- =============================================================
CREATE TABLE flash_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
  combo_id UUID REFERENCES combos(id) ON DELETE CASCADE,
  discount_price DECIMAL(10,2) NOT NULL,
  quantity_limit INT NOT NULL,
  sold_count INT DEFAULT 0,
  starts_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (item_id IS NOT NULL OR combo_id IS NOT NULL)
);

CREATE INDEX idx_flashsales_restaurant ON flash_sales(restaurant_id);
CREATE INDEX idx_flashsales_active ON flash_sales(is_active, expires_at);

-- =============================================================
-- 15. PROMOTIONS
-- =============================================================
CREATE TABLE promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  code TEXT,
  type TEXT NOT NULL CHECK (type IN ('percent', 'fixed', 'free_delivery', 'bogo')),
  value DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  max_discount DECIMAL(10,2),
  usage_limit INT,
  used_count INT DEFAULT 0,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  target_role TEXT DEFAULT 'all' CHECK (target_role IN ('all', 'new', 'returning')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_promotions_code ON promotions(code) WHERE code IS NOT NULL;
CREATE INDEX idx_promotions_active ON promotions(is_active, valid_from, valid_until);

CREATE TABLE promotion_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  order_id UUID,
  discount_amount DECIMAL(10,2) NOT NULL,
  used_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_promo_usage_customer ON promotion_usage(customer_id);

-- =============================================================
-- 16. CUSTOMER ADDRESSES
-- =============================================================
CREATE TABLE customer_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT, -- e.g., "البيت", "الشغل"
  address TEXT NOT NULL,
  address_details TEXT,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  apartment TEXT,
  floor TEXT,
  landmark TEXT,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_addresses_customer ON customer_addresses(customer_id);

-- =============================================================
-- 17. RIDERS
-- =============================================================
CREATE TABLE riders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('bicycle', 'motorcycle', 'car')),
  vehicle_plate TEXT,
  vehicle_color TEXT,
  is_online BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  current_lat DECIMAL(10,7),
  current_lng DECIMAL(10,7),
  total_deliveries INT DEFAULT 0,
  avg_rating DECIMAL(3,2) DEFAULT 5.00,
  total_earnings DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_riders_online ON riders(is_online, is_active, verification_status) WHERE is_online = true AND is_active = true AND verification_status = 'approved';
CREATE INDEX idx_riders_location ON riders(current_lat, current_lng);

-- =============================================================
-- 18. RIDER DOCUMENTS
-- =============================================================
CREATE TABLE rider_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('license', 'id_card', 'vehicle_registration', 'insurance', 'other')),
  document_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rider_docs_rider ON rider_documents(rider_id);

-- =============================================================
-- 19. RIDER SHIFTS
-- =============================================================
CREATE TABLE rider_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN DEFAULT true,
  UNIQUE(rider_id, day_of_week, start_time)
);

CREATE INDEX idx_shifts_rider ON rider_shifts(rider_id);

-- =============================================================
-- 20. ORDERS
-- =============================================================
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  rider_id UUID REFERENCES riders(id),
  address_id UUID REFERENCES customer_addresses(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'accepted', 'preparing', 'ready', 'rider_assigned',
    'picked_up', 'out_for_delivery', 'delivered', 'cancelled', 'refund_requested'
  )),
  subtotal DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  service_fee DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cod', 'card', 'instapay', 'vodafone_cash', 'wallet')),
  payment_status TEXT DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded', 'partial')),
  cod_secure_deposit DECIMAL(10,2) DEFAULT 0,
  order_type TEXT DEFAULT 'instant' CHECK (order_type IN ('instant', 'scheduled')),
  scheduled_time TIMESTAMPTZ,
  customer_notes TEXT,
  is_group_order BOOLEAN DEFAULT false,
  group_code TEXT,
  estimated_delivery_time INT, -- minutes
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_rider ON orders(rider_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_group ON orders(group_code) WHERE group_code IS NOT NULL;

-- =============================================================
-- 21. ORDER ITEMS
-- =============================================================
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES menu_items(id),
  variation_id UUID REFERENCES item_variations(id),
  item_name TEXT NOT NULL,
  item_name_ar TEXT,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  special_instructions TEXT,
  combo_id UUID REFERENCES combos(id),
  formation_id UUID REFERENCES formations(id)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);

-- =============================================================
-- 22. ORDER ITEM ADDONS & MODIFIERS
-- =============================================================
CREATE TABLE order_item_addons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
  addon_name TEXT NOT NULL,
  addon_name_ar TEXT,
  quantity INT DEFAULT 1,
  price DECIMAL(10,2) NOT NULL
);

CREATE INDEX idx_order_addons_item ON order_item_addons(order_item_id);

CREATE TABLE order_item_modifiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
  group_name TEXT NOT NULL,
  group_name_ar TEXT,
  choice_name TEXT NOT NULL,
  choice_name_ar TEXT,
  price_adjustment DECIMAL(10,2) DEFAULT 0
);

CREATE INDEX idx_order_modifiers_item ON order_item_modifiers(order_item_id);

-- =============================================================
-- 23. GROUP ORDERS
-- =============================================================
CREATE TABLE group_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES profiles(id),
  group_code TEXT NOT NULL UNIQUE,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'ordered')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE group_order_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES group_orders(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES profiles(id),
  items_json JSONB, -- snapshot of their items
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid')),
  paid_amount DECIMAL(10,2) DEFAULT 0,
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_group_members_group ON group_order_members(group_id);

-- =============================================================
-- 24. DELIVERY OFFERS
-- =============================================================
CREATE TABLE delivery_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  rider_id UUID NOT NULL REFERENCES riders(id),
  estimated_fee DECIMAL(10,2) NOT NULL,
  estimated_tip DECIMAL(10,2) DEFAULT 0,
  estimated_distance_km DECIMAL(5,2),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_delivery_offers_order ON delivery_offers(order_id);
CREATE INDEX idx_delivery_offers_rider ON delivery_offers(rider_id, status);

-- =============================================================
-- 25. ORDER TRACKING (Realtime)
-- =============================================================
CREATE TABLE order_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  note TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tracking_order ON order_tracking(order_id, timestamp DESC);

-- =============================================================
-- 26. ORDER STATUS HISTORY (Audit Log)
-- =============================================================
CREATE TABLE order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID REFERENCES profiles(id),
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_status_history_order ON order_status_history(order_id, changed_at DESC);

-- =============================================================
-- 27. REVIEWS
-- =============================================================
CREATE TABLE order_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE UNIQUE,
  customer_id UUID NOT NULL REFERENCES profiles(id),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id),
  rider_id UUID REFERENCES riders(id),
  food_rating INT NOT NULL CHECK (food_rating BETWEEN 1 AND 5),
  delivery_rating INT CHECK (delivery_rating BETWEEN 1 AND 5),
  speed_rating INT CHECK (speed_rating BETWEEN 1 AND 5),
  comment TEXT,
  comment_ar TEXT,
  images JSONB, -- array of URLs
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reviews_restaurant ON order_reviews(restaurant_id);
CREATE INDEX idx_reviews_rider ON order_reviews(rider_id);

-- =============================================================
-- 28. ITEM REVIEWS
-- =============================================================
CREATE TABLE item_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES profiles(id),
  order_id UUID REFERENCES orders(id),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_item_reviews_item ON item_reviews(item_id);

-- =============================================================
-- 29. RIDER REVIEWS (Rider rates customer)
-- =============================================================
CREATE TABLE customer_reviews_by_rider (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES riders(id),
  customer_id UUID NOT NULL REFERENCES profiles(id),
  order_id UUID REFERENCES orders(id),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(rider_id, order_id)
);

CREATE INDEX idx_rider_reviews_customer ON customer_reviews_by_rider(customer_id);

-- =============================================================
-- 30. FAVORITES
-- =============================================================
CREATE TABLE favorites (
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (customer_id, restaurant_id)
);

-- =============================================================
-- 31. CART ITEMS
-- =============================================================
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  restaurant_id UUID NOT NULL REFERENCES restaurants(id),
  item_id UUID NOT NULL REFERENCES menu_items(id),
  variation_id UUID REFERENCES item_variations(id),
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  addons_json JSONB, -- [{"addon_id": 1, "quantity": 2, "price": 1.5}]
  modifiers_json JSONB, -- [{"group_id": 1, "choice_id": 2, "price": 0}]
  special_instructions TEXT,
  combo_id UUID REFERENCES combos(id),
  formation_id UUID REFERENCES formations(id),
  item_total DECIMAL(10,2),
  saved_for_later BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cart_customer ON cart_items(customer_id);
CREATE INDEX idx_cart_restaurant ON cart_items(customer_id, restaurant_id);

-- =============================================================
-- 32. WALLETS
-- =============================================================
CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  owner_type TEXT NOT NULL CHECK (owner_type IN ('restaurant', 'rider')),
  balance DECIMAL(12,2) DEFAULT 0,
  currency TEXT DEFAULT 'EGP',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wallets_owner ON wallets(owner_id);

-- =============================================================
-- 33. TRANSACTIONS
-- =============================================================
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID REFERENCES wallets(id),
  order_id UUID REFERENCES orders(id),
  owner_id UUID NOT NULL REFERENCES profiles(id),
  amount DECIMAL(12,2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('earning', 'commission', 'withdrawal', 'refund', 'tip', 'deposit', 'payout')),
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
  description TEXT,
  reference TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX idx_transactions_owner ON transactions(owner_id, created_at DESC);

-- =============================================================
-- 34. WITHDRAWAL REQUESTS
-- =============================================================
CREATE TABLE withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES wallets(id),
  owner_id UUID NOT NULL REFERENCES profiles(id),
  amount DECIMAL(12,2) NOT NULL,
  method TEXT NOT NULL CHECK (method IN ('bank', 'instapay', 'vodafone_cash', 'fawry')),
  account_number TEXT,
  account_holder TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  admin_id UUID REFERENCES profiles(id),
  admin_note TEXT,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_withdrawal_owner ON withdrawal_requests(owner_id, status);

-- =============================================================
-- 35. PAYOUTS (Admin settlements)
-- =============================================================
CREATE TABLE payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id),
  owner_type TEXT NOT NULL CHECK (owner_type IN ('restaurant', 'rider')),
  amount DECIMAL(12,2) NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  notes TEXT,
  processed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payouts_owner ON payouts(owner_id, period_start, period_end);

-- =============================================================
-- 36. REFUND REQUESTS
-- =============================================================
CREATE TABLE refund_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES profiles(id),
  amount DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'processing', 'cancelled')),
  admin_id UUID REFERENCES profiles(id),
  admin_note TEXT,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 37. NOTIFICATIONS
-- =============================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('order_status', 'promotion', 'payment', 'system', 'chat', 'delivery')),
  title TEXT NOT NULL,
  title_ar TEXT,
  body TEXT,
  body_ar TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  action_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- =============================================================
-- 38. FCM TOKENS
-- =============================================================
CREATE TABLE fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  device_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_fcm_user ON fcm_tokens(user_id);

-- =============================================================
-- 39. GAMIFICATION
-- =============================================================
CREATE TABLE customer_gamification (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  xp_points INT DEFAULT 0,
  level INT DEFAULT 1,
  total_orders INT DEFAULT 0,
  streak_days INT DEFAULT 0,
  last_order_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,
  icon_url TEXT,
  xp_required INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE customer_badges (
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (customer_id, badge_id)
);

-- =============================================================
-- 40. MOOD CATEGORIES (Gen Z Feature)
-- =============================================================
CREATE TABLE mood_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  icon_url TEXT,
  emoji TEXT,
  sort_order INT DEFAULT 0
);

CREATE TABLE restaurant_moods (
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  mood_id UUID NOT NULL REFERENCES mood_categories(id) ON DELETE CASCADE,
  PRIMARY KEY (restaurant_id, mood_id)
);

-- =============================================================
-- 41. DELIVERY ZONES
-- =============================================================
CREATE TABLE delivery_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_ar TEXT,
  boundaries JSONB NOT NULL, -- GeoJSON polygon
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  min_order DECIMAL(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE zone_restaurants (
  zone_id UUID NOT NULL REFERENCES delivery_zones(id) ON DELETE CASCADE,
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  PRIMARY KEY (zone_id, restaurant_id)
);

-- =============================================================
-- 42. APP SETTINGS
-- =============================================================
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================
CREATE INDEX idx_menu_items_search ON menu_items USING gin(to_tsvector('arabic', coalesce(name_ar, name)));
CREATE INDEX idx_restaurants_search ON restaurants USING gin(to_tsvector('arabic', coalesce(name_ar, name)));

-- =============================================================
-- FUNCTIONS
-- =============================================================

-- Function: Calculate cart item total
CREATE OR REPLACE FUNCTION calculate_item_total(
  p_base_price DECIMAL,
  p_variation_adjustment DECIMAL,
  p_addons_json JSONB,
  p_quantity INT
) RETURNS DECIMAL AS $$
DECLARE
  v_addon_total DECIMAL := 0;
  v_addon RECORD;
BEGIN
  IF p_addons_json IS NOT NULL THEN
    FOR v_addon IN SELECT * FROM jsonb_to_recordset(p_addons_json) AS x(price DECIMAL, quantity INT)
    LOOP
      v_addon_total := v_addon_total + (v_addon.price * v_addon.quantity);
    END LOOP;
  END IF;
  RETURN ((p_base_price + COALESCE(p_variation_adjustment, 0) + v_addon_total) * p_quantity);
END;
$$ LANGUAGE plpgsql;

-- Function: Auto-create gamification profile on first order
CREATE OR REPLACE FUNCTION handle_first_order()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO customer_gamification (customer_id)
  VALUES (NEW.customer_id)
  ON CONFLICT (customer_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Update gamification XP on order delivered
CREATE OR REPLACE FUNCTION update_gamification_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_xp INT;
BEGIN
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    v_xp := 50;
    IF NEW.payment_method != 'cod' THEN v_xp := v_xp + 25; END IF;

    INSERT INTO customer_gamification (customer_id, xp_points, total_orders, last_order_date)
    VALUES (NEW.customer_id, v_xp, 1, CURRENT_DATE)
    ON CONFLICT (customer_id) DO UPDATE SET
      xp_points = customer_gamification.xp_points + v_xp,
      total_orders = customer_gamification.total_orders + 1,
      last_order_date = CURRENT_DATE,
      updated_at = NOW();

    -- Level up check
    UPDATE customer_gamification
    SET level = floor(xp_points / 200) + 1
    WHERE customer_id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Auto-create wallet on restaurant/rider approval
CREATE OR REPLACE FUNCTION handle_wallet_creation()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.verification_status = 'approved' AND (OLD IS NULL OR OLD.verification_status != 'approved') THEN
    INSERT INTO wallets (owner_id, owner_type)
    VALUES (NEW.profile_id, 'rider')
    ON CONFLICT (owner_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handle_restaurant_wallet()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'active' AND (OLD IS NULL OR OLD.status != 'active') THEN
    INSERT INTO wallets (owner_id, owner_type)
    VALUES (NEW.owner_id, 'restaurant')
    ON CONFLICT (owner_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Add order tracking entry
CREATE OR REPLACE FUNCTION add_tracking_entry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO order_tracking (order_id, status, note)
    VALUES (NEW.id, NEW.status, 'Status changed to ' || NEW.status);

    INSERT INTO order_status_history (order_id, from_status, to_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, NEW.rider_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Update restaurant avg rating
CREATE OR REPLACE FUNCTION update_restaurant_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE restaurants SET
    avg_rating = (SELECT AVG(food_rating) FROM order_reviews WHERE restaurant_id = NEW.restaurant_id),
    total_ratings = (SELECT COUNT(*) FROM order_reviews WHERE restaurant_id = NEW.restaurant_id)
  WHERE id = NEW.restaurant_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Update rider stats on delivery
CREATE OR REPLACE FUNCTION update_rider_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'delivered' AND (OLD IS NULL OR OLD.status != 'delivered') THEN
    UPDATE riders SET
      total_deliveries = total_deliveries + 1
    WHERE id = NEW.rider_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate distance between two points (km)
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 DECIMAL, lng1 DECIMAL,
  lat2 DECIMAL, lng2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
  dlat DECIMAL;
  dlng DECIMAL;
  a DECIMAL;
  c DECIMAL;
BEGIN
  dlat := radians(lat2 - lat1);
  dlng := radians(lng2 - lng1);
  a := sin(dlat/2)^2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng/2)^2;
  c := 2 * asin(sqrt(a));
  RETURN 6371 * c;
END;
$$ LANGUAGE plpgsql;

-- Function: Find nearest riders for a delivery
CREATE OR REPLACE FUNCTION find_nearest_riders(
  p_lat DECIMAL,
  p_lng DECIMAL,
  p_limit INT DEFAULT 5
) RETURNS TABLE (
  rider_id UUID,
  distance_km DECIMAL,
  profile_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT r.id, calculate_distance(p_lat, p_lng, r.current_lat, r.current_lng) as dist, r.profile_id
  FROM riders r
  WHERE r.is_online = true
    AND r.is_active = true
    AND r.verification_status = 'approved'
    AND r.current_lat IS NOT NULL
    AND r.current_lng IS NOT NULL
  ORDER BY dist ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =============================================================
-- TRIGGERS
-- =============================================================
CREATE TRIGGER trigger_first_order
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION handle_first_order();

CREATE TRIGGER trigger_gamification_delivery
  AFTER UPDATE OF status ON orders
  FOR EACH ROW
  WHEN (NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered'))
  EXECUTE FUNCTION update_gamification_on_delivery();

CREATE TRIGGER trigger_rider_wallet
  AFTER UPDATE OF verification_status ON riders
  FOR EACH ROW
  EXECUTE FUNCTION handle_wallet_creation();

CREATE TRIGGER trigger_restaurant_wallet
  AFTER UPDATE OF status ON restaurants
  FOR EACH ROW
  EXECUTE FUNCTION handle_restaurant_wallet();

CREATE TRIGGER trigger_order_tracking
  AFTER UPDATE OF status ON orders
  FOR EACH ROW
  EXECUTE FUNCTION add_tracking_entry();

CREATE TRIGGER trigger_restaurant_rating
  AFTER INSERT OR UPDATE ON order_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_restaurant_rating();

CREATE TRIGGER trigger_rider_delivery_stats
  AFTER UPDATE OF status ON orders
  FOR EACH ROW
  WHEN (NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered'))
  EXECUTE FUNCTION update_rider_stats();

-- =============================================================
-- RLS POLICIES
-- =============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_variations ENABLE ROW LEVEL SECURITY;
ALTER TABLE addon_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE addons ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_choices ENABLE ROW LEVEL SECURITY;
ALTER TABLE combos ENABLE ROW LEVEL SECURITY;
ALTER TABLE combo_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE combo_allowed_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE formations ENABLE ROW LEVEL SECURITY;
ALTER TABLE formation_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE formation_slot_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE flash_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE riders ENABLE ROW LEVEL SECURITY;
ALTER TABLE rider_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_gamification ENABLE ROW LEVEL SECURITY;

-- =============================================================
-- PROFILES RLS
-- =============================================================
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can read all profiles"
  ON profiles FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- =============================================================
-- RESTAURANTS RLS
-- =============================================================
CREATE POLICY "Anyone can view active restaurants"
  ON restaurants FOR SELECT
  USING (status = 'active' OR owner_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Restaurant owners can update"
  ON restaurants FOR UPDATE
  USING (owner_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Restaurant owners can insert"
  ON restaurants FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- =============================================================
-- MENU RLS (Restaurant manages own menu)
-- =============================================================
CREATE POLICY "Anyone can view menu of active restaurants"
  ON menu_categories FOR SELECT
  USING (EXISTS (SELECT 1 FROM restaurants r WHERE r.id = menu_categories.restaurant_id AND (r.status = 'active' OR r.owner_id = auth.uid())));

CREATE POLICY "Restaurant manages own menu categories"
  ON menu_categories FOR ALL
  USING (EXISTS (SELECT 1 FROM restaurants WHERE id = menu_categories.restaurant_id AND owner_id = auth.uid()));

CREATE POLICY "Anyone can view items of active restaurants"
  ON menu_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM restaurants r WHERE r.id = menu_items.restaurant_id AND (r.status = 'active' OR r.owner_id = auth.uid())));

CREATE POLICY "Restaurant manages own items"
  ON menu_items FOR ALL
  USING (EXISTS (SELECT 1 FROM restaurants WHERE id = menu_items.restaurant_id AND owner_id = auth.uid()));

-- Variations / Addons / Modifiers - same pattern
CREATE POLICY "Anyone can view variations"
  ON item_variations FOR SELECT
  USING (EXISTS (SELECT 1 FROM menu_items mi JOIN restaurants r ON r.id = mi.restaurant_id WHERE mi.id = item_variations.item_id AND (r.status = 'active' OR r.owner_id = auth.uid())));

CREATE POLICY "Restaurant manages variations"
  ON item_variations FOR ALL
  USING (EXISTS (SELECT 1 FROM menu_items mi JOIN restaurants r ON r.id = mi.restaurant_id WHERE mi.id = item_variations.item_id AND r.owner_id = auth.uid()));

CREATE POLICY "Anyone can view addons"
  ON addons FOR SELECT
  USING (EXISTS (SELECT 1 FROM addon_groups ag JOIN menu_items mi ON mi.id = ag.item_id JOIN restaurants r ON r.id = mi.restaurant_id WHERE ag.id = addons.group_id AND (r.status = 'active' OR r.owner_id = auth.uid())));

CREATE POLICY "Restaurant manages addons"
  ON addons FOR ALL
  USING (EXISTS (SELECT 1 FROM addon_groups ag JOIN menu_items mi ON mi.id = ag.item_id JOIN restaurants r ON r.id = mi.restaurant_id WHERE ag.id = addons.group_id AND r.owner_id = auth.uid()));

CREATE POLICY "Anyone can view modifiers"
  ON modifier_choices FOR SELECT
  USING (EXISTS (SELECT 1 FROM modifier_groups mg JOIN menu_items mi ON mi.id = mg.item_id JOIN restaurants r ON r.id = mi.restaurant_id WHERE mg.id = modifier_choices.group_id AND (r.status = 'active' OR r.owner_id = auth.uid())));

CREATE POLICY "Restaurant manages modifiers"
  ON modifier_choices FOR ALL
  USING (EXISTS (SELECT 1 FROM modifier_groups mg JOIN menu_items mi ON mi.id = mg.item_id JOIN restaurants r ON r.id = mi.restaurant_id WHERE mg.id = modifier_choices.group_id AND r.owner_id = auth.uid()));

-- Combos
CREATE POLICY "Anyone can view combos"
  ON combos FOR SELECT
  USING (EXISTS (SELECT 1 FROM restaurants WHERE id = combos.restaurant_id AND (status = 'active' OR owner_id = auth.uid())));

CREATE POLICY "Restaurant manages combos"
  ON combos FOR ALL
  USING (EXISTS (SELECT 1 FROM restaurants WHERE id = combos.restaurant_id AND owner_id = auth.uid()));

-- =============================================================
-- ORDERS RLS
-- =============================================================
CREATE POLICY "Customers see own orders"
  ON orders FOR SELECT
  USING (customer_id = auth.uid());

CREATE POLICY "Restaurants see their orders"
  ON orders FOR SELECT
  USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

CREATE POLICY "Riders see assigned orders"
  ON orders FOR SELECT
  USING (rider_id IN (SELECT id FROM riders WHERE profile_id = auth.uid()));

CREATE POLICY "Admins see all orders"
  ON orders FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Customers can create orders"
  ON orders FOR INSERT
  WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Restaurants update their orders"
  ON orders FOR UPDATE
  USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()))
  WITH CHECK (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

CREATE POLICY "Riders update assigned orders"
  ON orders FOR UPDATE
  USING (rider_id IN (SELECT id FROM riders WHERE profile_id = auth.uid()))
  WITH CHECK (rider_id IN (SELECT id FROM riders WHERE profile_id = auth.uid()));

-- =============================================================
-- RIDERS RLS
-- =============================================================
CREATE POLICY "Riders view own profile"
  ON riders FOR SELECT
  USING (profile_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Customers can view approved riders"
  ON riders FOR SELECT
  USING (verification_status = 'approved' AND is_active = true);

CREATE POLICY "Riders update own profile"
  ON riders FOR UPDATE
  USING (profile_id = auth.uid());

CREATE POLICY "Riders insert own profile"
  ON riders FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- =============================================================
-- WALLETS RLS
-- =============================================================
CREATE POLICY "Owner views own wallet"
  ON wallets FOR SELECT
  USING (owner_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admin manages wallets"
  ON wallets FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- =============================================================
-- TRANSACTIONS RLS
-- =============================================================
CREATE POLICY "Owner views own transactions"
  ON transactions FOR SELECT
  USING (owner_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- =============================================================
-- CUSTOMER ADDRESSES RLS
-- =============================================================
CREATE POLICY "Customer manages own addresses"
  ON customer_addresses FOR ALL
  USING (customer_id = auth.uid());

-- =============================================================
-- CART RLS
-- =============================================================
CREATE POLICY "Customer manages own cart"
  ON cart_items FOR ALL
  USING (customer_id = auth.uid());

-- =============================================================
-- FAVORITES RLS
-- =============================================================
CREATE POLICY "Customer manages own favorites"
  ON favorites FOR ALL
  USING (customer_id = auth.uid());

-- =============================================================
-- GAMIFICATION RLS
-- =============================================================
CREATE POLICY "Customer views own gamification"
  ON customer_gamification FOR SELECT
  USING (customer_id = auth.uid());

-- =============================================================
-- NOTIFICATIONS RLS
-- =============================================================
CREATE POLICY "User views own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "User updates own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

-- =============================================================
-- REVIEWS RLS
-- =============================================================
CREATE POLICY "Anyone can read reviews"
  ON order_reviews FOR SELECT
  USING (true);

CREATE POLICY "Customer creates own reviews"
  ON order_reviews FOR INSERT
  WITH CHECK (customer_id = auth.uid());

-- =============================================================
-- SEED DATA
-- =============================================================

-- App Settings
INSERT INTO app_settings (key, value, description) VALUES
  ('platform_name', '"يالا"', 'اسم المنصة'),
  ('platform_name_en', '"Yalla"', 'Platform name in English'),
  ('default_commission_rate', '15', 'Default commission rate for restaurants (%)'),
  ('default_delivery_fee', '5', 'Default delivery fee (EGP)'),
  ('cod_secure_deposit', '10', 'COD secure deposit amount (EGP)'),
  ('min_withdrawal', '100', 'Minimum withdrawal amount'),
  ('max_rider_distance_km', '10', 'Max distance for rider assignment (km)'),
  ('free_delivery_threshold', '50', 'Order amount for free delivery (EGP)'),
  ('referral_xp_bonus', '100', 'XP bonus for referral'),
  ('new_user_xp_bonus', '200', 'XP bonus for new users'),
  ('maintenance_mode', 'false', 'Enable maintenance mode'),
  ('supported_payment_methods', '["cod","instapay","vodafone_cash","card","wallet"]', 'Available payment methods');

-- Cuisine Types
INSERT INTO cuisine_types (name, name_ar, sort_order) VALUES
  ('Egyptian', 'مصري', 1),
  ('Italian', 'إيطالي', 2),
  ('Chinese', 'صيني', 3),
  ('Indian', 'هندي', 4),
  ('Mexican', 'مكسيكي', 5),
  ('Japanese', 'ياباني', 6),
  ('Lebanese', 'لبناني', 7),
  ('American', 'أمريكي', 8),
  ('Seafood', 'مأكولات بحرية', 9),
  ('Grill', 'مشاوي', 10),
  ('Fast Food', 'وجبات سريعة', 11),
  ('Healthy', 'صحي', 12),
  ('Desserts', 'حلويات', 13),
  ('Bakery', 'مخبوزات', 14),
  ('Beverages', 'مشروبات', 15),
  ('Grocery', 'بقالة', 16);

-- Tags
INSERT INTO tags (name, name_ar) VALUES
  ('vegetarian', 'نباتي'),
  ('vegan', 'فيجن'),
  ('gluten_free', 'خالي من الجلوتين'),
  ('spicy', 'حار'),
  ('healthy', 'صحي'),
  ('protein', 'بروتين عالي'),
  ('low_cal', 'قليل السعرات'),
  ('kids', 'مناسب للأطفال'),
  ('chef_special', 'طبق الشيف'),
  ('new', 'جديد');

-- Mood Categories
INSERT INTO mood_categories (name, name_ar, emoji, sort_order) VALUES
  ('craving_fast', 'عاوز حاجة بسرعة', '⚡', 1),
  ('healthy_bite', 'حاجة صحي', '🥗', 2),
  ('comfort_food', 'أكل البيت', '😌', 3),
  ('feeling_adventurous', 'جرب حاجة جديدة', '🚀', 4),
  ('sweet_tooth', 'نفسي في حلو', '🍰', 5),
  ('saving_money', 'عاوز أقل سعر', '💰', 6),
  ('group_feast', 'مع الأصحاب', '👥', 7),
  ('late_night', 'الليل المتأخر', '🌙', 8),
  ('hangover_fix', 'صحصح دماغي', '😵', 9),
  ('breakfast_anytime', 'فطار أي وقت', '🥞', 10);

-- Badges
INSERT INTO badges (name, name_ar, description, xp_required) VALUES
  ('first_order', 'أول طلب', 'أول طلب لك على يالا', 0),
  ('regular', 'زبون دائم', 'أكملت 10 طلبات', 500),
  ('vip', 'عميل VIP', 'أكملت 50 طلب', 2500),
  ('legend', 'أسطورة', 'أكملت 100 طلب', 5000),
  ('foodie', 'ذواقة', 'طلبت من 10 مطاعم مختلفة', 1000),
  ('early_bird', 'طائر مبكر', 'طلبت 5 مرات قبل الـ 10 صباحاً', 300),
  ('night_owl', 'بومة الليل', 'طلبت 5 مرات بعد الـ 12 صباحاً', 300),
  ('group_organizer', 'منظم المجموعة', 'أنشأت 3 طلبات جماعية', 400),
  ('review_master', 'ناقد محترف', 'كتبت 10 تقييمات', 350),
  ('streak_7', 'تحدي أسبوع', 'طلبت 7 أيام متتالية', 1000);

-- =============================================================
-- REALTIME SUBSCRIPTIONS
-- =============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_tracking;
ALTER PUBLICATION supabase_realtime ADD TABLE riders;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- =============================================================
-- FINAL NOTES
-- =============================================================
-- Schema version: 1.0
-- Total tables: 52 (+ junction/index tables)
-- For 100k+ users/month:
--   - Enable connection pooling on Supabase
--   - Add pg_bouncer for transaction pooling
--   - Consider read replicas for analytics queries
-- =============================================================
