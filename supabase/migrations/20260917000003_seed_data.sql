-- ==============================================================================
-- 003_seed_data.sql
-- VeloRide India - Initial Seed Data for Bengaluru Fleet & Hubs
-- ==============================================================================

-- 1. Insert Stations
INSERT INTO public.stations (id, code, name, address, landmark, city, latitude, longitude, operating_hours, contact_phone, total_capacity, is_active)
VALUES
    ('a0000001-0000-0000-0000-000000000001', 'BLR-KRM-01', 'Koramangala 5th Block Hub', 'Near Jyoti Nivas College, 1st Cross, 5th Block, Koramangala', 'Opposite Empire Restaurant', 'Bengaluru', 12.9352, 77.6245, '06:00 AM - 11:00 PM', '+91 98765 43210', 25, TRUE),
    ('a0000001-0000-0000-0000-000000000002', 'BLR-IND-02', 'Indiranagar 100ft Road Hub', '100 Feet Rd, Defence Colony, Indiranagar', 'Near Indiranagar Metro Station Gate 2', 'Bengaluru', 12.9784, 77.6408, '24x7 Open', '+91 98765 43211', 30, TRUE),
    ('a0000001-0000-0000-0000-000000000003', 'BLR-HSR-03', 'HSR Layout Sector 1 Hub', '27th Main Rd, Sector 1, HSR Layout', 'Adjacent to Agara Lake Park', 'Bengaluru', 12.9116, 77.6389, '06:00 AM - 11:00 PM', '+91 98765 43212', 20, TRUE),
    ('a0000001-0000-0000-0000-000000000004', 'BLR-WTF-04', 'Whitefield ITPL Hub', 'ITPB Main Road, Whitefield', 'Near Pattandur Agrahara Metro Station', 'Bengaluru', 12.9863, 77.7314, '07:00 AM - 10:30 PM', '+91 98765 43213', 35, TRUE)
ON CONFLICT (code) DO NOTHING;

-- 2. Insert Bike Categories
INSERT INTO public.bike_categories (id, slug, name, description, fuel_type, icon)
VALUES
    ('b0000001-0000-0000-0000-000000000001', 'electric-scooters', 'Electric Scooters', 'Zero emissions, silent & effortless city commuting', 'electric', 'bolt'),
    ('b0000001-0000-0000-0000-000000000002', 'city-scooters', 'City Scooters', 'Reliable gearless automatic scooters for everyday errands', 'petrol', 'moped'),
    ('b0000001-0000-0000-0000-000000000003', 'street-motorcycles', 'Street Motorcycles', 'Sporty, efficient commuter bikes for fast city navigation', 'petrol', 'two_wheeler'),
    ('b0000001-0000-0000-0000-000000000004', 'touring-cruisers', 'Touring & Cruisers', 'Iconic heavy cruisers for weekend getaways and road trips', 'petrol', 'sports_motorsports')
ON CONFLICT (slug) DO NOTHING;

-- 3. Insert Fleet Bikes
INSERT INTO public.bikes (id, registration_number, brand, model, name, category_id, current_station_id, status, battery_percentage, range_km, hourly_rate, daily_rate, security_deposit, image_url, features, odometer_km)
VALUES
    (
        'c0000001-0000-0000-0000-000000000001',
        'KA 01 EK 4501',
        'Ather Energy',
        '450X',
        'Ather 450X Gen 3',
        'b0000001-0000-0000-0000-000000000001',
        'a0000001-0000-0000-0000-000000000002',
        'available',
        92,
        105,
        69.00,
        499.00,
        999.00,
        'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&w=800&q=80',
        '["Warp Mode", "Google Navigation on Dashboard", "Zero Emission", "Fast Charging Compatible"]'::jsonb,
        4210
    ),
    (
        'c0000001-0000-0000-0000-000000000002',
        'KA 03 HM 8820',
        'Ola Electric',
        'S1 Pro',
        'Ola S1 Pro Gen 2',
        'b0000001-0000-0000-0000-000000000001',
        'a0000001-0000-0000-0000-000000000001',
        'available',
        85,
        140,
        75.00,
        549.00,
        999.00,
        'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?auto=format&fit=crop&w=800&q=80',
        '["Hyper Mode", "Hill Hold Assist", "Party Mode Audio", "Pro Cruise Control"]'::jsonb,
        3100
    ),
    (
        'c0000001-0000-0000-0000-000000000003',
        'KA 05 JR 1290',
        'Honda',
        'Activa 6G',
        'Honda Activa 6G Deluxe',
        'b0000001-0000-0000-0000-000000000002',
        'a0000001-0000-0000-0000-000000000001',
        'available',
        NULL,
        260,
        49.00,
        349.00,
        500.00,
        'https://images.unsplash.com/photo-1591637333184-19aa84b3e01f?auto=format&fit=crop&w=800&q=80',
        '["PGM-FI Engine", "Telescopic Suspension", "Silent ACG Starter", "High Fuel Efficiency"]'::jsonb,
        8750
    ),
    (
        'c0000001-0000-0000-0000-000000000004',
        'KA 01 MR 3500',
        'Royal Enfield',
        'Hunter 350 Dapper',
        'Royal Enfield Hunter 350',
        'b0000001-0000-0000-0000-000000000004',
        'a0000001-0000-0000-0000-000000000002',
        'available',
        NULL,
        380,
        119.00,
        899.00,
        1999.00,
        'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=800&q=80',
        '["349cc J-Series Engine", "Dual Channel ABS", "Digi-Analog Console", "Exhaust Beat"]'::jsonb,
        6120
    ),
    (
        'c0000001-0000-0000-0000-000000000005',
        'KA 51 YM 1550',
        'Yamaha',
        'MT-15 V2',
        'Yamaha MT-15 V2',
        'b0000001-0000-0000-0000-000000000003',
        'a0000001-0000-0000-0000-000000000003',
        'available',
        NULL,
        420,
        99.00,
        749.00,
        1500.00,
        'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?auto=format&fit=crop&w=800&q=80',
        '["155cc Liquid Cooled VVA", "Upside Down Front Forks", "Traction Control", "Assist & Slipper Clutch"]'::jsonb,
        5400
    )
ON CONFLICT (registration_number) DO NOTHING;
