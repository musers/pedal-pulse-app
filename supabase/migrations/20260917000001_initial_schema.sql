-- ==============================================================================
-- 001_initial_schema.sql
-- VeloRide India - Core Relational Schema
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Helper function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ==============================================================================
-- 1. PROFILES (Extends Supabase Auth users)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100) DEFAULT '',
    email VARCHAR(255),
    role VARCHAR(20) DEFAULT 'customer' CHECK (role IN ('customer', 'admin', 'station_staff')),
    kyc_status VARCHAR(20) DEFAULT 'not_submitted' CHECK (kyc_status IN ('not_submitted', 'pending_review', 'verified', 'rejected')),
    driving_license_number VARCHAR(50),
    driving_license_doc_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- 2. STATIONS (Pickup & Drop Hubs)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.stations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(30) UNIQUE NOT NULL,
    name VARCHAR(120) NOT NULL,
    address TEXT NOT NULL,
    landmark VARCHAR(150),
    city VARCHAR(80) NOT NULL,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    operating_hours VARCHAR(100) DEFAULT '06:00 AM - 11:00 PM' NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    total_capacity INT DEFAULT 20 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_stations_city ON public.stations(city);
CREATE INDEX IF NOT EXISTS idx_stations_active ON public.stations(is_active);

CREATE TRIGGER set_stations_updated_at
    BEFORE UPDATE ON public.stations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- 3. BIKE CATEGORIES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.bike_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(80) NOT NULL,
    description TEXT,
    fuel_type VARCHAR(20) DEFAULT 'petrol' CHECK (fuel_type IN ('electric', 'petrol')),
    icon VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ==============================================================================
-- 4. BIKES (Fleet Inventory)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.bikes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_number VARCHAR(30) UNIQUE NOT NULL,
    brand VARCHAR(60) NOT NULL,
    model VARCHAR(80) NOT NULL,
    name VARCHAR(120) NOT NULL,
    category_id UUID NOT NULL REFERENCES public.bike_categories(id) ON DELETE RESTRICT,
    current_station_id UUID NOT NULL REFERENCES public.stations(id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'in_use', 'maintenance', 'retired')),
    battery_percentage INT CHECK (battery_percentage BETWEEN 0 AND 100),
    range_km INT NOT NULL,
    hourly_rate NUMERIC(10, 2) NOT NULL,
    daily_rate NUMERIC(10, 2) NOT NULL,
    security_deposit NUMERIC(10, 2) NOT NULL,
    image_url TEXT NOT NULL,
    features JSONB DEFAULT '[]'::jsonb,
    odometer_km INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_bikes_station ON public.bikes(current_station_id);
CREATE INDEX IF NOT EXISTS idx_bikes_category ON public.bikes(category_id);
CREATE INDEX IF NOT EXISTS idx_bikes_status ON public.bikes(status);

CREATE TRIGGER set_bikes_updated_at
    BEFORE UPDATE ON public.bikes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- 5. BOOKINGS (State Machine & Financial Records)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_number VARCHAR(40) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    bike_id UUID NOT NULL REFERENCES public.bikes(id) ON DELETE RESTRICT,
    pickup_station_id UUID NOT NULL REFERENCES public.stations(id) ON DELETE RESTRICT,
    return_station_id UUID NOT NULL REFERENCES public.stations(id) ON DELETE RESTRICT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    actual_pickup_time TIMESTAMPTZ,
    actual_return_time TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'confirmed' CHECK (status IN ('pending_payment', 'confirmed', 'active', 'completed', 'cancelled')),
    rental_fare NUMERIC(10, 2) NOT NULL,
    gst_amount NUMERIC(10, 2) NOT NULL,
    security_deposit NUMERIC(10, 2) NOT NULL,
    discount_amount NUMERIC(10, 2) DEFAULT 0.0 NOT NULL,
    total_payable NUMERIC(10, 2) NOT NULL,
    deposit_status VARCHAR(20) DEFAULT 'held' CHECK (deposit_status IN ('pending', 'held', 'refund_initiated', 'refunded', 'deducted')),
    starting_odometer INT,
    ending_odometer INT,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    CONSTRAINT check_booking_time_validity CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_bookings_customer ON public.bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_bike ON public.bookings(bike_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);

CREATE TRIGGER set_bookings_updated_at
    BEFORE UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- 6. DOUBLE-BOOKING CONCURRENCY GUARD
-- Ensures that no bike can have overlapping confirmed or active bookings
-- ==============================================================================
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    overlap_count INT;
BEGIN
    -- Only check for active/confirmed bookings
    IF NEW.status IN ('confirmed', 'active') THEN
        SELECT COUNT(*)
        INTO overlap_count
        FROM public.bookings
        WHERE bike_id = NEW.bike_id
          AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
          AND status IN ('confirmed', 'active')
          AND (start_time, end_time) OVERLAPS (NEW.start_time, NEW.end_time);

        IF overlap_count > 0 THEN
            RAISE EXCEPTION 'Concurrency Conflict: Bike is already reserved or in-use for this time interval.'
                USING ERRCODE = '23P01'; -- exclusion_violation
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_double_booking_before_insert_or_update
    BEFORE INSERT OR UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION prevent_double_booking();

-- ==============================================================================
-- 7. RENTAL LOGS (Checklist, Odometer, Inspection)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.rental_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    log_type VARCHAR(20) NOT NULL CHECK (log_type IN ('pickup', 'return', 'incident')),
    odometer_reading INT NOT NULL,
    checklist_items JSONB DEFAULT '[]'::jsonb,
    photos JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    inspected_by UUID REFERENCES public.profiles(id),
    logged_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rental_logs_booking ON public.rental_logs(booking_id);
