# تصميم قاعدة البيانات حسب أدوار النظام — توصيل مطاعم + بقالة

---

## منهجية التصميم

لكل Role، سنحدد **العمليات الفعلية** التي يقوم بها، ومنها نستنتج **الجداول** المطلوبة.

> قاعدة: كل "فعل" في التطبيق = عمليات CRUD على جدول أو أكثر في الـ DB.

---

## 👤 1. العميل (Customer) — Gen Z

### ماذا يفعل فعلياً؟

```
يسجل حساب جديد =>
    INSERT INTO profiles (role='customer', full_name, phone, email)
    INSERT INTO fcm_tokens (token, device_type)

يفتح التطبيق =>
    SELECT * FROM mood_categories
    SELECT * FROM restaurants WHERE is_open AND status='active'
    SELECT * FROM menu_items JOIN menu_categories WHERE restaurant_id = X

يضبط عنوانه =>
    INSERT INTO customer_addresses (label, lat, lng, details, is_default)

يضيف طلب لـ "المفضلة" =>
    INSERT INTO favorites (customer_id, restaurant_id)

يضغط "اطلب الآن" =>
    INSERT INTO cart_items (item_id, quantity, options, special_instructions)
    -- لو عايز يشارك الطلب =>
    INSERT INTO group_orders (customer_id, group_code, status='open')
    INSERT INTO group_order_members (group_id, customer_id)

يدفع =>
    UPDATE orders SET payment_method='instapay', payment_status='paid'
    INSERT INTO transactions (type='order_payment', amount, status='completed')

يتتبع الطلب =>
    SELECT * FROM order_tracking WHERE order_id = X ORDER BY timestamp DESC
    -- Realtime subscription على order_tracking

يقيم =>
    INSERT INTO order_reviews (food_rating, delivery_rating, comment, images)
    UPDATE restaurants SET total_ratings = total_ratings + 1, avg_rating = ...

يكسب XP =>
    UPDATE customer_gamification SET xp_points = xp_points + 50
    -- لو وصل لـ Level جديد => INSERT INTO customer_badges

يحصل إشعار =>
    INSERT INTO notifications (user_id, type='order_status', title, body)
    -- FCM push notification

يشارك الطلب =>
    -- UI فقط، share link بدون DB
```

### الجداول المستنتجة من أفعاله

| الجدول | الغرض |
|--------|-------|
| `profiles` | بيانات الحساب (role = 'customer') |
| `customer_addresses` | العناوين المحفوظة |
| `favorites` | المطاعم المفضلة |
| `cart_items` | سلة الطلب الحالية |
| `group_orders` | الطلبات الجماعية (Group Order) |
| `group_order_members` | أعضاء المجموعة + كل واحد طلب إيه |
| `order_reviews` | التقييمات مع الصور |
| `customer_gamification` | XP points + Level |
| `customer_badges` | الشارات اللي كسبها |
| `notifications` | الإشعارات |
| `fcm_tokens` | أجهزته للإشعارات |

---

## 🏪 2. المطعم / البقالة (Restaurant Partner)

### ماذا يفعل فعلياً؟

```
يسجل =>
    INSERT INTO profiles (role='restaurant', ...)
    INSERT INTO restaurants (owner_id, name, name_ar, cuisine_type, status='pending')
    INSERT INTO restaurant_documents (type='commercial_registry', url, status='pending')

يدير أوقات العمل =>
    INSERT INTO restaurant_hours (day_of_week, open_time, close_time)
    أو UPDATE restaurant_hours SET is_closed = true

يدير القائمة =>
    INSERT INTO menu_categories (name_ar, sort_order)
    INSERT INTO menu_items (name_ar, price, image_url, is_available)
    INSERT INTO menu_item_options (name_ar, type='single') -- size, extras
    INSERT INTO option_choices (name_ar, price_adjustment)  -- large +5, extra cheese +3
    UPDATE menu_items SET is_available = false  -- نفد من المخزون

يستقبل طلب =>
    SELECT * FROM orders WHERE restaurant_id = X AND status = 'pending'
    UPDATE orders SET status = 'accepted'
    -- بعد ما يجهز =>
    UPDATE orders SET status = 'ready'

يشوف الإحصائيات =>
    SELECT COUNT(*), SUM(total_amount) FROM orders 
    WHERE restaurant_id = X AND created_at > NOW() - INTERVAL '7 days'
    -- أكثر الأصناف مبيعاً
    SELECT menu_items.name_ar, SUM(order_items.quantity) as total_sold
    FROM order_items JOIN menu_items ... GROUP BY ... ORDER BY total_sold DESC

يسحب أرباحه =>
    SELECT balance FROM wallets WHERE owner_id = X AND owner_type = 'restaurant'
    INSERT INTO withdrawal_requests (wallet_id, amount, method='bank')
    -- Admin يوافق =>
    UPDATE wallets SET balance = balance - amount
    UPDATE withdrawal_requests SET status = 'completed'

يعمل عرض =>
    INSERT INTO promotions (restaurant_id, type='discount', value='20%', valid_until)
    -- أو عروض مؤقتة (Flash Sale) =>
    INSERT INTO flash_sales (item_id, discount_price, quantity_limit, expires_at)

يشوف تقييماته =>
    SELECT AVG(food_rating), AVG(delivery_rating) FROM order_reviews 
    WHERE restaurant_id = X
```

### الجداول المستنتجة

| الجدول | الغرض |
|--------|-------|
| `restaurants` | بيانات المطعم (الاسم، الموقع، الحالة، العمولة) |
| `restaurant_documents` | الأوراق الرسمية (سجل تجاري، رخصة) |
| `restaurant_hours` | أوقات العمل لكل يوم |
| `cuisine_types` | أنواع المأكولات (مصري، إيطالي، صيني) |
| `menu_categories` | أقسام القائمة (مقبلات، مشاوي، مشروبات) |
| `menu_items` | الأصناف (الاسم، السعر، الصورة، التوفر) |
| `menu_item_options` | خيارات التخصيص (الحجم، الإضافات) |
| `option_choices` | قيم الخيارات (وسط، كبير +5 جنيه) |
| `order_items` | الأصناف المطلوبة في كل طلب |
| `order_item_options` | الخيارات المختارة لكل صنف |
| `promotions` | العروض الترويجية |
| `flash_sales` | العروض الخاطفة (محدودة الكمية/الوقت) |
| `wallets` | المحفظة المالية |
| `transactions` | المعاملات المالية |
| `withdrawal_requests` | طلبات السحب |

---

## 🛵 3. الـ Rider (Delivery Person)

### ماذا يفعل فعلياً؟

```
يسجل =>
    INSERT INTO profiles (role='rider')
    INSERT INTO riders (profile_id, vehicle_type='motorcycle', verification_status='pending')
    INSERT INTO rider_documents (type='license', url)
    INSERT INTO rider_documents (type='id_card', url)

يدخل Online =>
    UPDATE riders SET is_online = true, current_lat = X, current_lng = Y

يستقبل طلب توصيل =>
    -- الخوارزمية تشوف أقرب Rider:
    SELECT *, (distance formula) FROM riders 
    WHERE is_online AND is_active AND verification_status='approved'
    ORDER BY distance LIMIT 1
    -- ترسل له الإشعار:
    INSERT INTO notifications (user_id, type='new_delivery', body='طلب جديد 2.5 كم')
    -- هو يشوف التفاصيل ويقرر:
    SELECT estimated_fee, estimated_tip FROM delivery_offers WHERE order_id = X

يقبل =>
    UPDATE orders SET rider_id = X, status = 'rider_assigned'
    INSERT INTO order_tracking (order_id, status='rider_assigned', timestamp)

يتجه للمطعم =>
    UPDATE riders SET current_lat, current_lng  (تحديث مستمر)
    INSERT INTO order_tracking (order_id, status='going_to_restaurant', lat, lng)

استلم الطلب =>
    UPDATE orders SET status = 'picked_up'
    INSERT INTO order_tracking (order_id, status='picked_up', timestamp)

يتجه للعميل =>
    INSERT INTO order_tracking (order_id, status='out_for_delivery', lat, lng)
    -- العميل يتابع فيリアル تايم

وصل =>
    UPDATE orders SET status = 'delivered'
    INSERT INTO order_tracking (order_id, status='delivered', timestamp)
    UPDATE riders SET total_deliveries = total_deliveries + 1

يقيم العميل (اختياري) =>
    INSERT INTO customer_reviews_by_rider (rider_id, customer_id, rating, comment)
    -- لو العميل مش محترم، Rider يقدر يرفض يوصل له مرة تانية

يشوف أرباحه =>
    SELECT SUM(amount) FROM transactions WHERE wallet_id = X AND type='earning'
    SELECT SUM(amount) FROM transactions WHERE type='tip'

يطلب سحب =>
    INSERT INTO withdrawal_requests (wallet_id, amount, method='instapay')

ياخد شفت (وردية) =>
    INSERT INTO rider_shifts (rider_id, day_of_week, start_time, end_time)
```

### الجداول المستنتجة

| الجدول | الغرض |
|--------|-------|
| `riders` | بيانات الـ Rider (المركبة، الحالة، الموقع) |
| `rider_documents` | المستندات (الرخصة، البطاقة) |
| `rider_shifts` | أوقات العمل الوردية |
| `delivery_offers` | عروض التوصيل المرسلة للـ Rider |
| `order_tracking` | نقاط التتبع (فيリアル تايم) |
| `customer_reviews_by_rider` | تقييم Rider للعميل |
| `wallets` | المحفظة |
| `transactions` | الأرباح + الإكراميات |
| `withdrawal_requests` | طلبات السحب |

---

## 👑 4. Admin (مشرف المنصة)

### ماذا يفعل فعلياً؟

```
يشوف الـ Dashboard =>
    -- طلبات اليوم:
    SELECT COUNT(*) FROM orders WHERE created_at::date = CURRENT_DATE
    -- إيرادات اليوم:
    SELECT SUM(total_amount) FROM orders WHERE status='delivered' AND created_at::date = CURRENT_DATE
    -- Riders نشطين دلوقتي:
    SELECT COUNT(*) FROM riders WHERE is_online = true
    -- المطاعم المفتوحة:
    SELECT COUNT(*) FROM restaurants WHERE is_open = true
    -- خريطة حية:
    SELECT rider_id, current_lat, current_lng, status FROM riders WHERE is_online

يوافق على مطعم جديد =>
    UPDATE restaurants SET status = 'active' WHERE id = X
    INSERT INTO wallets (owner_id, owner_type='restaurant', balance=0)

يوافق على Rider جديد =>
    UPDATE riders SET verification_status = 'approved'

يقفل مطعم مخالف =>
    UPDATE restaurants SET status = 'suspended', ban_reason = 'نقاط صحية منخفضة'

يدير العمولات =>
    UPDATE restaurants SET commission_rate = 20

يعرض عروض =>
    INSERT INTO promotions (type='platform', code='YALLA50', discount_value=50, valid_until)

يشوف التقارير =>
    -- أكثر المطاعم مبيعاً:
    SELECT restaurant_id, COUNT(*), SUM(total_amount) 
    FROM orders GROUP BY restaurant_id ORDER BY COUNT(*) DESC LIMIT 10
    -- أكثر الـ Riders نشاطاً:
    SELECT rider_id, COUNT(*), AVG(delivery_time) 
    FROM orders GROUP BY rider_id ORDER BY COUNT(*) DESC

يعالج شكوى =>
    UPDATE orders SET status = 'refund_requested'
    INSERT INTO refund_requests (order_id, reason, amount)
    -- بعد الموافقة:
    UPDATE refund_requests SET status = 'approved'
    INSERT INTO transactions (type='refund', amount)

يدفع للمطاعم والـ Riders =>
    SELECT restaurant_id, SUM(amount) FROM transactions 
    WHERE status='completed' AND created_at BETWEEN X AND Y
    INSERT INTO payouts (restaurant_id, amount, period_start, period_end, status='processing')
    -- بعد التحويل البنكي:
    UPDATE payouts SET status = 'completed'

يدير المستخدمين =>
    UPDATE profiles SET banned_at = NOW(), ban_reason = 'تقييمات وهمية'
    WHERE id = X AND role = 'customer'

يشوف سجل التوصيل =>
    SELECT * FROM order_status_history WHERE order_id = X ORDER BY changed_at
```

### الجداول المستنتجة

| الجدول | الغرض |
|--------|-------|
| `restaurants` | الموافقة / الإيقاف / تعديل العمولة |
| `riders` | توثيق / إيقاف |
| `promotions` | إنشاء عروض المنصة |
| `refund_requests` | معالجة طلبات الاسترداد |
| `payouts` | التسويات المالية للمطاعم والـ Riders |
| `order_status_history` | سجل كامل لكل تغيير حالة (للتدقيق) |
| `app_settings` | إعدادات المنصة (عمولة افتراضية، حد أدنى) |

---

## 📊 ملخص — كل جدول وأفعال الـ Roles عليه

| # | الجدول | ينشئه | يقرأه | يعدّله | يحذفه |
|---|--------|-------|-------|--------|-------|
| 1 | `profiles` | Customer, Rider, Restaurant | Admin | Admin | Admin |
| 2 | `restaurants` | Restaurant | Customer, Admin, Rider | Restaurant, Admin | Admin |
| 3 | `restaurant_documents` | Restaurant | Admin | — | Admin |
| 4 | `restaurant_hours` | Restaurant | Customer | Restaurant | Restaurant |
| 5 | `cuisine_types` | Admin | Customer | Admin | Admin |
| 6 | `menu_categories` | Restaurant | Customer | Restaurant | Restaurant |
| 7 | `menu_items` | Restaurant | Customer, Rider | Restaurant | Restaurant |
| 8 | `menu_item_options` | Restaurant | Customer | Restaurant | Restaurant |
| 9 | `option_choices` | Restaurant | Customer | Restaurant | Restaurant |
| 10 | `customer_addresses` | Customer | Customer | Customer | Customer |
| 11 | `cart_items` | Customer | Customer | Customer | Customer |
| 12 | `orders` | Customer | Customer, Restaurant, Rider, Admin | Restaurant, Rider, Admin | — |
| 13 | `order_items` | Customer (عند checkout) | Customer, Restaurant, Rider | — | — |
| 14 | `order_item_options` | Customer (عند checkout) | Restaurant | — | — |
| 15 | `group_orders` | Customer | Group Members | Customer | Customer |
| 16 | `group_order_members` | Customer | Group Members | Customer | Customer |
| 17 | `order_tracking` | Rider (آلياً) | Customer, Rider, Admin | — | — |
| 18 | `order_status_history` | Trigger آلي | Admin | — | — |
| 19 | `order_reviews` | Customer | Customer, Restaurant, Admin | Customer | Admin |
| 20 | `riders` | Rider | Admin, Customer | Rider, Admin | Admin |
| 21 | `rider_documents` | Rider | Admin | — | Admin |
| 22 | `rider_shifts` | Rider | System, Rider | Rider | Rider |
| 23 | `delivery_offers` | System | Rider | Rider (accept/reject) | — |
| 24 | `customer_reviews_by_rider` | Rider | Rider, Admin | — | — |
| 25 | `customer_gamification` | System (عند أول طلب) | Customer | System (XP update) | — |
| 26 | `badges` | Admin | Customer | — | — |
| 27 | `customer_badges` | System (عند تحقيق badge) | Customer | — | — |
| 28 | `promotions` | Restaurant / Admin | Customer | Restaurant / Admin | Restaurant / Admin |
| 29 | `promotion_usage` | System | Admin | — | — |
| 30 | `flash_sales` | Restaurant | Customer | Restaurant | Restaurant |
| 31 | `favorites` | Customer | Customer | — | Customer |
| 32 | `wallets` | System (عند التفعيل) | Restaurant, Rider | System (update balance) | — |
| 33 | `transactions` | System | Restaurant, Rider, Admin | — | — |
| 34 | `withdrawal_requests` | Restaurant / Rider | Restaurant, Rider, Admin | Admin | — |
| 35 | `payouts` | Admin | Restaurant, Rider, Admin | Admin | — |
| 36 | `refund_requests` | Customer | Admin | Admin | — |
| 37 | `notifications` | System | Customer, Rider, Restaurant | Customer (read) | — |
| 38 | `fcm_tokens` | Customer, Rider, Restaurant | System | System | — |
| 39 | `app_settings` | Admin | All | Admin | Admin |
| 40 | `delivery_zones` | Admin | Customer, System | Admin | Admin |
| 41 | `mood_categories` | Admin | Customer | Admin | Admin |
| 42 | `restaurant_moods` | Admin, Restaurant | Customer | Admin, Restaurant | Admin, Restaurant |

---

## 🧠 العلاقات الأساسية (ER Diagram)

```
profiles (role: customer | restaurant | rider | admin)
  │
  ├── customer_addresses (1:N)
  ├── favorites (1:N)
  ├── cart_items (1:N)
  ├── customer_gamification (1:1)
  ├── customer_badges (N:N) ─── badges
  ├── group_orders (1:N) ─── group_order_members
  │
  ├── restaurants (1:1) [owner_id]
  │     ├── restaurant_documents (1:N)
  │     ├── restaurant_hours (1:N)
  │     ├── cuisine_types (N:N)
  │     ├── menu_categories (1:N) ─── menu_items (1:N)
  │     │                                  └── menu_item_options (1:N) ─── option_choices
  │     ├── promotions (1:N)
  │     ├── flash_sales (1:N)
  │     ├── wallets (1:1)
  │     └── order_reviews (1:N)
  │
  ├── riders (1:1)
  │     ├── rider_documents (1:N)
  │     ├── rider_shifts (1:N)
  │     ├── customer_reviews_by_rider (1:N)
  │     └── wallets (1:1)
  │
  ├── delivery_zones (N:N)
  └── mood_categories (N:N) ─── restaurant_moods
              │
orders ─── order_items (1:N) ─── order_item_options (1:N)
  │          │
  │          └── group_order_members (1:N)
  │
  ├── order_tracking (1:N)
  ├── order_status_history (1:N)
  ├── order_reviews (1:N)
  ├── delivery_offers (1:N)
  ├── refund_requests (1:1)
  ├── transactions (1:N)
  ├── payouts (1:1)
  └── promotion_usage (1:1)
```

---

## 🎯 الخلاصة

1. **كل جدول = فعل حقيقي يقوم به Role معين**
   - `restaurant_hours` = المطعم يحدد أوقات العمل
   - `order_tracking` = Rider يتحرك على الخريطة
   - `customer_gamification` = العميل يكسب XP
   - `group_orders` = العميل يشارك الطلب مع أصحابه

2. **فصل الكيانات (Restaurant ≠ Rider)**
   - في Faster كان "مقدم الخدمة" شخص واحد
   - هنا: المطعم يجهز، والـ Rider يوصل — كيانان منفصلان بجداول منفصلة

3. **جاهز للتوسع**
   - `mood_categories` + `restaurant_moods` = اكتشاف بالمزاج (خاص بـ Gen Z)
   - `customer_gamification` + `badges` = نظام لعب وتحفيز
   - `group_orders` = طلب جماعي (مشاركة مع الأصدقاء)

4. **RLS Policy جاهز**
   ```
   -- Restaurant يرى فقط طلباته
   CREATE POLICY "Restaurant sees own orders" ON orders
   FOR ALL USING (restaurant_id = auth.uid());
   
   -- Rider يرى فقط طلباته المعينة له
   CREATE POLICY "Rider sees assigned orders" ON orders
   FOR ALL USING (rider_id = auth.uid());
   ```
