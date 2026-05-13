# يالا (Yalla) — Food & Grocery Delivery Super App 🚀

تطبيق توصيل مطاعم و بقالة بنمط **Neubrutalism** يستهدف **Gen Z**.
مبني بـ **Flutter 3.41** + **Supabase**، يدعم 100k+ مستخدم شهرياً.

---

## 📦 هيكل المشروع

```
yalla_app/
├── lib/
│   ├── main.dart                    # Splash + Routing (4 Roles)
│   ├── core/
│   │   ├── theme/                   # Neubrutalism (ألوان جريئة، حدود سوداء، Hard Shadows)
│   │   │   ├── app_colors.dart
│   │   │   └── app_theme.dart       # Light + Dark
│   │   ├── services/
│   │   │   └── supabase_service.dart # Auth + DB + Storage
│   │   ├── widgets/
│   │   │   ├── neubrutalism_button.dart  # NeoButton, NeoOutlineButton
│   │   │   ├── neubrutalism_card.dart    # NeoCard, NeoTile
│   │   │   └── neubrutalism_text_field.dart
│   │   └── constants/
│   │       └── app_constants.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── restaurant_model.dart    # Restaurant + MenuCategory + MenuItem
│   │   └── order_model.dart         # Order + CartItem
│   └── features/
│       ├── auth/
│       │   ├── providers/auth_provider.dart
│       │   └── screens/
│       │       ├── login_screen.dart
│       │       └── register_screen.dart
│       ├── role_selection_screen.dart
│       ├── customer/                # 👤 العميل (Gen Z)
│       │   ├── providers/
│       │   └── screens/
│       │       ├── home_screen.dart  # Mood Bar + قائمة مطاعم
│       │       └── cart_screen.dart  # سلة + COD / InstaPay
│       ├── restaurant/              # 🏪 المطعم
│       │   ├── providers/restaurant_provider.dart
│       │   └── screens/
│       │       ├── restaurant_nav_screen.dart
│       │       ├── restaurant_dashboard_screen.dart  # إحصائيات + Online/Offline
│       │       ├── menu_management_screen.dart       # أقسام + أصناف
│       │       └── order_management_screen.dart      # قبول/رفض طلبات
│       ├── rider/                   # 🛵 Rider
│       │   ├── providers/rider_provider.dart
│       │   └── screens/rider_home_screen.dart
│       └── admin/                   # 👑 Admin
│           └── screens/admin_dashboard_screen.dart
│
├── docs/                            # ملفات التخطيط والتحليل
│   ├── دراسة_الجدوى_الكاملة.md       # Feasibility Study
│   ├── roles_database_design.md      # Roles → Actions → Tables
│   ├── menu_payments_analysis.md     # COD vs Card + Menu Structure
│   ├── supabase_complete_schema_v2.sql  # 52 جدول كامل
│   ├── supabase_fix_rls_recursion.sql   # Fix RLS recursion
│   └── supabase_fix_publication.sql     # Fix Realtime publication
│
└── assets/
    └── .env                         # Supabase credentials
```

---

## 🎯 الأدوار (4 Roles)

| الدور | المسار | المهام |
|-------|--------|--------|
| **👤 عميل (Gen Z)** | `/home` | تصفح مطاعم، طلب، COD، سلة، Group Order، Gamification |
| **🏪 مطعم** | `/restaurant` | لوحة تحكم، إدارة منيو، استقبال طلبات، إحصائيات |
| **🛵 Rider** | `/rider` | Online/Offline، استقبال توصيل، تتبع، أرباح |
| **👑 Admin** | `/admin` | موافقات مطاعم/Riders، تقارير، تسويات مالية |

---

## 🗄️ قاعدة البيانات (Supabase PostgreSQL — 52 جدول)

- **Profiles & Auth** — `profiles`, `fcm_tokens`
- **Restaurants** — `restaurants`, `restaurant_hours`, `cuisine_types`, `restaurant_documents`
- **Menu** — `menu_categories`, `menu_items`, `item_variations`, `addons`, `modifier_choices`, `tags`
- **Combos & Deals** — `combos`, `formations`, `flash_sales`, `promotions`
- **Orders** — `orders`, `order_items`, `order_item_addons`, `order_tracking`, `group_orders`
- **Delivery** — `riders`, `rider_documents`, `rider_shifts`, `delivery_offers`
- **Finance** — `wallets`, `transactions`, `withdrawal_requests`, `payouts`, `refund_requests`
- **Gamification** — `customer_gamification`, `badges`, `customer_badges`
- **Gen Z** — `mood_categories`, `restaurant_moods`

🔐 **RLS Policies** — كل role يرى فقط بياناته (مع دوال `SECURITY DEFINER` لمنع recursion)

---

## 🎨 Neubrutalism Design

- حدود سوداء سميكة (3px) على كل العناصر
- Hard shadows بدون blur (offset: 4,4)
- ألوان جريئة: أصفر نيون، سماوي، زهري، أخضر
- خطوط عريضة (w800, w900)
- Flat design بدون gradients

---

## 💳 الدفع

| الطريقة | الحالة |
|--------|--------|
| 💵 COD (Cash on Delivery) | مدعوم (85%+ من السوق المصري) |
| 💳 InstaPay | مدعوم |
| 📱 Vodafone Cash | مدعوم |
| 💳 بطاقة ائتمان | مدعوم |
| 🏦 Wallet (محفظة التطبيق) | مدعوم (شحن بـ COD/InstaPay) |

---

## 🚀 التشغيل

```bash
# 1. Clone
git clone <repo-url>
cd yalla_app

# 2. Install dependencies
flutter pub get

# 3. Create assets/.env
echo "SUPABASE_URL=https://your-project.supabase.co" > assets/.env
echo "SUPABASE_ANON_KEY=your-anon-key" >> assets/.env

# 4. Run SQL in Supabase
#    docs/supabase_complete_schema_v2.sql
#    docs/supabase_fix_rls_recursion.sql

# 5. Run
flutter run -d chrome    # Web
flutter run -d windows   # Desktop
flutter run              # Connected device
```

---

## 📐 التوسع لـ 100k+ مستخدم

| العنصر | الحل |
|--------|------|
| Database | Supabase (PostgreSQL) — Scale-to-zero → Dedicated |
| Auth | Supabase Auth —托管، 100k+ مستخدم |
| Real-time | Supabase Realtime (WebSockets) |
| Storage | Supabase Storage + CDN |
| Notifications | Firebase Cloud Messaging |
| Payments | Paymob + Fawry + InstaPay + Vodafone Cash |
| Monitoring | Sentry + Supabase Logs |
| Analytics | Mixpanel / Firebase Analytics |

---

## 📄 التراخيص

MIT License — مبني على Faster App الأصلي.
