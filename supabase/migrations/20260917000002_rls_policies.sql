-- ==============================================================================
-- 002_rls_policies.sql
-- VeloRide India - Row Level Security (RLS) Policies
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bike_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bikes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_logs ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- Helper Function: Check Admin or Staff Status
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.is_admin_or_staff()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role IN ('admin', 'station_staff')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- 1. PROFILES POLICIES
-- ==============================================================================
-- Allow users to view their own profile
CREATE POLICY "Users can view their own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id OR public.is_admin_or_staff());

-- Allow users to update their own profile (name, driving license)
CREATE POLICY "Users can update their own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow profile creation on user signup
CREATE POLICY "Users can insert their own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ==============================================================================
-- 2. STATIONS POLICIES (Public read, admin write)
-- ==============================================================================
CREATE POLICY "Anyone can view active stations"
    ON public.stations
    FOR SELECT
    USING (is_active = TRUE OR public.is_admin_or_staff());

CREATE POLICY "Admin/Staff can manage stations"
    ON public.stations
    FOR ALL
    USING (public.is_admin_or_staff())
    WITH CHECK (public.is_admin_or_staff());

-- ==============================================================================
-- 3. BIKE CATEGORIES POLICIES (Public read, admin write)
-- ==============================================================================
CREATE POLICY "Anyone can view bike categories"
    ON public.bike_categories
    FOR SELECT
    USING (TRUE);

CREATE POLICY "Admin can manage bike categories"
    ON public.bike_categories
    FOR ALL
    USING (public.is_admin_or_staff())
    WITH CHECK (public.is_admin_or_staff());

-- ==============================================================================
-- 4. BIKES POLICIES (Public read active fleet, admin manage)
-- ==============================================================================
CREATE POLICY "Anyone can view fleet bikes"
    ON public.bikes
    FOR SELECT
    USING (status != 'retired' OR public.is_admin_or_staff());

CREATE POLICY "Admin/Staff can manage bikes"
    ON public.bikes
    FOR ALL
    USING (public.is_admin_or_staff())
    WITH CHECK (public.is_admin_or_staff());

-- ==============================================================================
-- 5. BOOKINGS POLICIES
-- ==============================================================================
-- Customers can view their own bookings
CREATE POLICY "Customers can view own bookings"
    ON public.bookings
    FOR SELECT
    USING (customer_id = auth.uid() OR public.is_admin_or_staff());

-- Customers can insert bookings for themselves
CREATE POLICY "Customers can create own bookings"
    ON public.bookings
    FOR INSERT
    WITH CHECK (customer_id = auth.uid());

-- Customers can cancel pending/confirmed bookings; Staff can update all
CREATE POLICY "Customers can cancel own booking"
    ON public.bookings
    FOR UPDATE
    USING (customer_id = auth.uid() OR public.is_admin_or_staff())
    WITH CHECK (
        (customer_id = auth.uid() AND status = 'cancelled')
        OR public.is_admin_or_staff()
    );

-- ==============================================================================
-- 6. RENTAL LOGS POLICIES
-- ==============================================================================
-- Customers can view inspection logs of their own bookings
CREATE POLICY "Customers can view logs of own bookings"
    ON public.rental_logs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id AND b.customer_id = auth.uid()
        )
        OR public.is_admin_or_staff()
    );

-- Only Admin or Station Staff can create inspection logs
CREATE POLICY "Staff can insert rental logs"
    ON public.rental_logs
    FOR INSERT
    WITH CHECK (public.is_admin_or_staff());
