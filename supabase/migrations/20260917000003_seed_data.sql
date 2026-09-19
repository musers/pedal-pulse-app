-- ==============================================================================
-- 003_seed_data.sql
-- VeloRide India - Initial Seed Data for Hyderabad EV Fleet & Hubs
-- ==============================================================================

-- 1. Insert Stations (Hyderabad: Miyapur & Kondapur Hubs)
INSERT INTO public.stations (id, code, name, address, landmark, city, latitude, longitude, operating_hours, contact_phone, total_capacity, is_active)
VALUES
    ('a0000001-0000-0000-0000-000000000001', 'HYD-MYP-01', 'Miyapur Metro Station Hub', 'Miyapur X Roads, Metro Pillar A-580, Miyapur', 'Adjacent to Miyapur Metro Terminal Parking', 'Hyderabad', 17.4968, 78.3582, '24x7 Open', '+91 98765 43210', 40, TRUE),
    ('a0000001-0000-0000-0000-000000000002', 'HYD-KND-02', 'Kondapur HITEC City Hub', 'Botanical Garden Road, Near HITEC City Corridor, Kondapur', 'Opposite Sarath City Capital Mall & Cyber Towers Arch', 'Hyderabad', 17.4646, 78.3667, '06:00 AM - 11:30 PM', '+91 98765 43211', 35, TRUE)
ON CONFLICT (code) DO NOTHING;

-- 2. Insert Bike Categories
INSERT INTO public.bike_categories (id, slug, name, description, fuel_type, icon)
VALUES
    ('b0000001-0000-0000-0000-000000000001', 'smart-ev-scooters', 'Smart EV Scooters', 'Zero emissions, silent & IoT connected electric mobility', 'electric', 'electric_moped'),
    ('b0000001-0000-0000-0000-000000000002', 'heavy-duty-ev-utility', 'Heavy Duty EV Cargo & SUV', 'Extended range & cargo-grade electric scooters', 'electric', 'electric_scooter'),
    ('b0000001-0000-0000-0000-000000000003', 'petrol-scooters', 'Petrol Scooters (Coming Soon)', 'Reliable gearless automatic scooters for long commutes', 'petrol', 'two_wheeler'),
    ('b0000001-0000-0000-0000-000000000004', 'touring-cruisers', 'Touring & Cruisers (Coming Soon)', 'Iconic heavy cruisers for weekend road trips', 'petrol', 'sports_motorsports')
ON CONFLICT (slug) DO NOTHING;

-- 3. Insert 100% EV Fleet Bikes
INSERT INTO public.bikes (id, registration_number, brand, model, name, category_id, current_station_id, status, battery_percentage, range_km, hourly_rate, daily_rate, security_deposit, image_url, features, odometer_km)
VALUES
    (
        'c0000001-0000-0000-0000-000000000001',
        'TS 08 EK 4501',
        'Ather Energy',
        '450X',
        'Ather 450X Gen 3',
        'b0000001-0000-0000-0000-000000000001',
        'a0000001-0000-0000-0000-000000000002',
        'available',
        94,
        105,
        69.00,
        499.00,
        999.00,
        'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&w=800&q=80',
        '["Warp Mode", "Google Maps on Dashboard", "Zero Emission", "Fast Charging Compatible"]'::jsonb,
        3210
    ),
    (
        'c0000001-0000-0000-0000-000000000002',
        'TS 07 HM 8820',
        'Ola Electric',
        'S1 Pro',
        'Ola S1 Pro Gen 2',
        'b0000001-0000-0000-0000-000000000001',
        'a0000001-0000-0000-0000-000000000001',
        'available',
        88,
        140,
        75.00,
        549.00,
        999.00,
        'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?auto=format&fit=crop&w=800&q=80',
        '["Hyper Mode", "Hill Hold Assist", "Party Mode Audio", "Pro Cruise Control"]'::jsonb,
        2800
    ),
    (
        'c0000001-0000-0000-0000-000000000003',
        'TS 09 EQ 3310',
        'TVS Motor',
        'iQube S',
        'TVS iQube S Electric',
        'b0000001-0000-0000-0000-000000000001',
        'a0000001-0000-0000-0000-000000000002',
        'available',
        96,
        100,
        59.00,
        399.00,
        800.00,
        'https://images.unsplash.com/photo-1591637333184-19aa84b3e01f?auto=format&fit=crop&w=800&q=80',
        '["Silent Hub Motor", "Q-Park Assist", "SmartXonnect Navigation", "Large Underseat Storage"]'::jsonb,
        4150
    ),
    (
        'c0000001-0000-0000-0000-000000000004',
        'TS 08 RV 9900',
        'River Mobility',
        'Indie EV',
        'River Indie SUV of Scooters',
        'b0000001-0000-0000-0000-000000000002',
        'a0000001-0000-0000-0000-000000000001',
        'available',
        82,
        120,
        79.00,
        579.00,
        1200.00,
        'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=800&q=80',
        '["43L Gigantic Boot", "Twin Beam LED Headlamps", "Crash Guards Included", "Fast Charging Support"]'::jsonb,
        1950
    ),
    (
        'c0000001-0000-0000-0000-000000000005',
        'TS 07 CK 1240',
        'Bajaj Auto',
        'Chetak EV',
        'Bajaj Chetak Premium EV',
        'b0000001-0000-0000-0000-000000000001',
        'a0000001-0000-0000-0000-000000000002',
        'available',
        90,
        108,
        65.00,
        449.00,
        900.00,
        'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?auto=format&fit=crop&w=800&q=80',
        '["Full Steel Body", "Sequential LED Blinkers", "Soft-touch Switchgear", "IP67 Water Resistance"]'::jsonb,
        2600
    )
ON CONFLICT (registration_number) DO NOTHING;
