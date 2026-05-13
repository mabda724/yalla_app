-- =============================================================
-- Fix: RLS Infinite Recursion in profiles table
-- Problem: Policies querying "profiles" table cause recursion
-- Solution: SECURITY DEFINER functions (bypass RLS)
-- =============================================================

-- 1. Create helper functions (in public schema, SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_restaurant_owner(restaurant_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM restaurants
    WHERE id = restaurant_id AND owner_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_rider()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM riders WHERE profile_id = auth.uid()
  );
$$;

-- 2. Drop ALL existing policies on profiles (to remove recursive ones)
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- 3. Re-create profiles policies WITHOUT recursion
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can read all profiles"
  ON profiles FOR SELECT
  USING (public.is_admin());

CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  USING (public.is_admin());

CREATE POLICY "Anyone can insert profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 4. Fix other policies that might have recursion

-- Restaurants
DROP POLICY IF EXISTS "Anyone can view active restaurants" ON restaurants;
DROP POLICY IF EXISTS "Restaurant owners can update" ON restaurants;
DROP POLICY IF EXISTS "Restaurant owners can insert" ON restaurants;

CREATE POLICY "Anyone can view active restaurants"
  ON restaurants FOR SELECT
  USING (status = 'active' OR owner_id = auth.uid() OR public.is_admin());

CREATE POLICY "Restaurant owners can update"
  ON restaurants FOR UPDATE
  USING (owner_id = auth.uid() OR public.is_admin());

CREATE POLICY "Restaurant owners can insert"
  ON restaurants FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- Menu categories - fix admin check
DROP POLICY IF EXISTS "Anyone can view menu of active restaurants" ON menu_categories;
DROP POLICY IF EXISTS "Restaurant manages own menu categories" ON menu_categories;

CREATE POLICY "Anyone can view menu of active restaurants"
  ON menu_categories FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM restaurants r
    WHERE r.id = menu_categories.restaurant_id
    AND (r.status = 'active' OR r.owner_id = auth.uid())
  ));

CREATE POLICY "Restaurant manages own menu categories"
  ON menu_categories FOR ALL
  USING (public.is_restaurant_owner(menu_categories.restaurant_id));

-- Menu items
DROP POLICY IF EXISTS "Anyone can view items of active restaurants" ON menu_items;
DROP POLICY IF EXISTS "Restaurant manages own items" ON menu_items;

CREATE POLICY "Anyone can view items of active restaurants"
  ON menu_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM restaurants r
    WHERE r.id = menu_items.restaurant_id
    AND (r.status = 'active' OR r.owner_id = auth.uid())
  ));

CREATE POLICY "Restaurant manages own items"
  ON menu_items FOR ALL
  USING (EXISTS (
    SELECT 1 FROM restaurants r
    WHERE r.id = menu_items.restaurant_id
    AND (r.owner_id = auth.uid() OR public.is_admin())
  ));

-- Orders - fix admin checks
DROP POLICY IF EXISTS "Customers see own orders" ON orders;
DROP POLICY IF EXISTS "Restaurants see their orders" ON orders;
DROP POLICY IF EXISTS "Riders see assigned orders" ON orders;
DROP POLICY IF EXISTS "Admins see all orders" ON orders;
DROP POLICY IF EXISTS "Customers can create orders" ON orders;
DROP POLICY IF EXISTS "Restaurants update their orders" ON orders;
DROP POLICY IF EXISTS "Riders update assigned orders" ON orders;

CREATE POLICY "Customers see own orders"
  ON orders FOR SELECT
  USING (customer_id = auth.uid());

CREATE POLICY "Restaurants see their orders"
  ON orders FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid()
  ));

CREATE POLICY "Riders see assigned orders"
  ON orders FOR SELECT
  USING (rider_id IN (SELECT id FROM riders WHERE profile_id = auth.uid()));

CREATE POLICY "Admins see all orders"
  ON orders FOR SELECT
  USING (public.is_admin());

CREATE POLICY "Customers can create orders"
  ON orders FOR INSERT
  WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Restaurants update their orders"
  ON orders FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid()
  ));

CREATE POLICY "Riders update assigned orders"
  ON orders FOR UPDATE
  USING (rider_id IN (SELECT id FROM riders WHERE profile_id = auth.uid()));

-- Riders
DROP POLICY IF EXISTS "Riders view own profile" ON riders;
DROP POLICY IF EXISTS "Customers can view approved riders" ON riders;
DROP POLICY IF EXISTS "Riders update own profile" ON riders;
DROP POLICY IF EXISTS "Riders insert own profile" ON riders;

CREATE POLICY "Riders view own profile"
  ON riders FOR SELECT
  USING (profile_id = auth.uid() OR public.is_admin());

CREATE POLICY "Customers can view approved riders"
  ON riders FOR SELECT
  USING (verification_status = 'approved' AND is_active = true);

CREATE POLICY "Riders update own profile"
  ON riders FOR UPDATE
  USING (profile_id = auth.uid());

CREATE POLICY "Riders insert own profile"
  ON riders FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- Wallets
DROP POLICY IF EXISTS "Owner views own wallet" ON wallets;
DROP POLICY IF EXISTS "Admin manages wallets" ON wallets;

CREATE POLICY "Owner views own wallet"
  ON wallets FOR SELECT
  USING (owner_id = auth.uid() OR public.is_admin());

CREATE POLICY "Admin manages wallets"
  ON wallets FOR UPDATE
  USING (public.is_admin());

-- Transactions
DROP POLICY IF EXISTS "Owner views own transactions" ON transactions;

CREATE POLICY "Owner views own transactions"
  ON transactions FOR SELECT
  USING (owner_id = auth.uid() OR public.is_admin());

-- Notifications
DROP POLICY IF EXISTS "User views own notifications" ON notifications;
DROP POLICY IF EXISTS "User updates own notifications" ON notifications;

CREATE POLICY "User views own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "User updates own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

-- Customer addresses
DROP POLICY IF EXISTS "Customer manages own addresses" ON customer_addresses;

CREATE POLICY "Customer manages own addresses"
  ON customer_addresses FOR ALL
  USING (customer_id = auth.uid());

-- Cart
DROP POLICY IF EXISTS "Customer manages own cart" ON cart_items;

CREATE POLICY "Customer manages own cart"
  ON cart_items FOR ALL
  USING (customer_id = auth.uid());

-- Favorites
DROP POLICY IF EXISTS "Customer manages own favorites" ON favorites;

CREATE POLICY "Customer manages own favorites"
  ON favorites FOR ALL
  USING (customer_id = auth.uid());

-- Gamification
DROP POLICY IF EXISTS "Customer views own gamification" ON customer_gamification;

CREATE POLICY "Customer views own gamification"
  ON customer_gamification FOR SELECT
  USING (customer_id = auth.uid());

-- Reviews
DROP POLICY IF EXISTS "Anyone can read reviews" ON order_reviews;
DROP POLICY IF EXISTS "Customer creates own reviews" ON order_reviews;

CREATE POLICY "Anyone can read reviews"
  ON order_reviews FOR SELECT
  USING (true);

CREATE POLICY "Customer creates own reviews"
  ON order_reviews FOR INSERT
  WITH CHECK (customer_id = auth.uid());

-- =============================================================
-- Verify no recursive policies remain
-- =============================================================
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('profiles', 'restaurants', 'orders', 'riders', 'menu_items', 'menu_categories')
ORDER BY tablename, policyname;
