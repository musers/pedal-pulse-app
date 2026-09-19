-- Migration: 20260919000002_wallet_and_referrals.sql
-- Description: Schema, indexes, and RLS policies for VeloCash Digital Wallet & Viral Referral Engine

-- 1. Wallets (Main Cash + Promotional Bonus Cash Ledger)
CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  main_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (main_balance >= 0.00),
  bonus_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (bonus_balance >= 0.00),
  currency TEXT NOT NULL DEFAULT 'INR',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Wallet Transactions (Immutable Audit Trail)
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0.00),
  type TEXT NOT NULL CHECK (type IN ('topUp', 'cashbackBonus', 'bookingDebit', 'subscriptionDebit', 'depositRefund', 'referralReward')),
  is_credit BOOLEAN NOT NULL,
  reference_id TEXT,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Referrals (Viral Invite & Reward Tracking)
CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referee_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  referral_code TEXT NOT NULL,
  referrer_reward_amount NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
  referee_reward_amount NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for lightning fast lookups
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_user_id ON public.wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet_id ON public.wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_created_at ON public.wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(referral_code);

-- Enable Row Level Security (RLS)
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Wallets
CREATE POLICY "Users can read their own wallet"
  ON public.wallets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet via secure functions"
  ON public.wallets FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for Wallet Transactions
CREATE POLICY "Users can view their own wallet transactions"
  ON public.wallet_transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert transactions for their wallet"
  ON public.wallet_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for Referrals
CREATE POLICY "Users can view referrals they initiated"
  ON public.referrals FOR SELECT
  USING (auth.uid() = referrer_user_id OR auth.uid() = referee_user_id);

CREATE POLICY "Users can record referrals"
  ON public.referrals FOR INSERT
  WITH CHECK (auth.uid() = referrer_user_id OR auth.uid() = referee_user_id);
