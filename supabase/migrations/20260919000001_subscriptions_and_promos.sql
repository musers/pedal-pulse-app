-- Migration: 20260919000001_subscriptions_and_promos.sql
-- Description: Schema and policies for Subscriptions and Dynamic Promo Engine

-- 1. Subscription Plans
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  tagline TEXT,
  vehicle_type TEXT NOT NULL,
  category_id TEXT NOT NULL REFERENCES public.bike_categories(id),
  duration_days INTEGER NOT NULL DEFAULT 30,
  billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('weekly', 'monthly', 'quarterly')),
  price NUMERIC(10, 2) NOT NULL,
  security_deposit NUMERIC(10, 2) NOT NULL,
  daily_km_cap INTEGER NOT NULL DEFAULT 80,
  is_unlimited_km BOOLEAN NOT NULL DEFAULT FALSE,
  free_maintenance_included BOOLEAN NOT NULL DEFAULT TRUE,
  swappable_battery_access BOOLEAN NOT NULL DEFAULT TRUE,
  helmet_included BOOLEAN NOT NULL DEFAULT TRUE,
  doorstep_delivery BOOLEAN NOT NULL DEFAULT TRUE,
  highlights JSONB DEFAULT '[]'::jsonb,
  is_popular BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Subscriptions (Long-Term Passes)
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_number TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES public.subscription_plans(id),
  plan_name TEXT NOT NULL,
  assigned_bike_id UUID REFERENCES public.bikes(id),
  assigned_bike_name TEXT,
  pickup_station_id TEXT NOT NULL REFERENCES public.stations(id),
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  amount_paid NUMERIC(10, 2) NOT NULL,
  security_deposit NUMERIC(10, 2) NOT NULL,
  promo_code_used TEXT,
  discount_applied NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
  deposit_status TEXT NOT NULL DEFAULT 'held' CHECK (deposit_status IN ('held', 'refunded', 'claimed')),
  auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Promo Codes & Dynamic Coupons
CREATE TABLE IF NOT EXISTS public.promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  description TEXT NOT NULL,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'flat')),
  discount_value NUMERIC(10, 2) NOT NULL,
  min_order_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  max_discount_amount NUMERIC(10, 2),
  valid_from TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ NOT NULL,
  usage_limit INTEGER NOT NULL DEFAULT 0,
  used_count INTEGER NOT NULL DEFAULT 0,
  applicable_type TEXT NOT NULL DEFAULT 'all' CHECK (applicable_type IN ('all', 'rental', 'subscription')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Atomically increment coupon usage RPC
CREATE OR REPLACE FUNCTION public.increment_promo_usage(p_code TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE public.promo_codes
  SET used_count = used_count + 1
  WHERE code = UPPER(p_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Row Level Security Policies
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

-- Subscription plans are publicly viewable
CREATE POLICY "Subscription plans viewable by everyone"
  ON public.subscription_plans FOR SELECT
  USING (true);

-- User subscriptions viewable by owner & admins
CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions FOR SELECT
  USING (auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Users can create own subscriptions"
  ON public.user_subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update subscriptions"
  ON public.user_subscriptions FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- Promo codes viewable by all, manageable by admins
CREATE POLICY "Promo codes viewable by everyone"
  ON public.promo_codes FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage promo codes"
  ON public.promo_codes FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
