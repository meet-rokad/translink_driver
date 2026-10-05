-- ============================================================
-- Return Translink — Core Schema Migration
-- 0002_core_schema.sql
-- ============================================================
-- Drop old incorrect tables from Phase 1 experiments
DROP TABLE IF EXISTS public.driver_activities CASCADE;
DROP TABLE IF EXISTS public.driver_earnings CASCADE;
DROP TABLE IF EXISTS public.driver_trips CASCADE;
DROP TABLE IF EXISTS public.driver_loads CASCADE;

-- ============================================================
-- PARTNERS
-- Core partner identity. Firebase handles authentication.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.partners (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid        TEXT UNIQUE NOT NULL,
    mobile_number       TEXT NOT NULL,
    whatsapp_number     TEXT,
    full_name           TEXT,
    email               TEXT,
    profile_photo_url   TEXT,
    city                TEXT,
    state               TEXT,
    language            TEXT DEFAULT 'en',
    status              TEXT NOT NULL DEFAULT 'NEW',
    -- Status lifecycle:
    -- NEW → PROFILE_INCOMPLETE → TRUCK_INCOMPLETE → DOCUMENTS_INCOMPLETE
    -- → PAYMENT_PENDING → VERIFICATION_PENDING → APPROVED → ACTIVE
    -- Also: REJECTED, SUSPENDED, INACTIVE
    verification_status TEXT NOT NULL DEFAULT 'PENDING',
    -- PENDING, APPROVED, REJECTED
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TRUCKS
-- One partner → one active truck enforced via unique partial index.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.trucks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id      UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    vehicle_number  TEXT NOT NULL,
    vehicle_type    TEXT,          -- e.g. Tata 407, Eicher 10.90, Container
    body_type       TEXT,          -- Open, Closed, Container, Flatbed
    capacity        TEXT,          -- e.g. "14"
    capacity_unit   TEXT DEFAULT 'Ton',
    status          TEXT DEFAULT 'ACTIVE',   -- ACTIVE, INACTIVE, REPLACED
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Enforce: 1 active truck per partner
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_truck_per_partner
    ON public.trucks(partner_id)
    WHERE is_active = TRUE;

-- ============================================================
-- DOCUMENTS
-- Partner identity docs + truck docs. Files in Supabase Storage.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id        UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    truck_id          UUID REFERENCES public.trucks(id) ON DELETE SET NULL,
    document_type     TEXT NOT NULL,
    -- Partner docs: AADHAAR, PAN, PROFILE_PHOTO
    -- Truck docs:   RC, INSURANCE, FITNESS, PERMIT, POLLUTION
    file_url          TEXT,
    status            TEXT NOT NULL DEFAULT 'NOT_UPLOADED',
    -- NOT_UPLOADED, UPLOADED, UNDER_REVIEW, APPROVED, REJECTED, EXPIRED
    document_number   TEXT,
    issue_date        DATE,
    expiry_date       DATE,
    rejection_reason  TEXT,
    reviewed_by       UUID,
    reviewed_at       TIMESTAMPTZ,
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- RETURN REQUIREMENTS
-- The core MVP entity. 1 active requirement per partner at a time.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.return_requirements (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id              UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    truck_id                UUID REFERENCES public.trucks(id) ON DELETE SET NULL,

    -- Origin (GPS or manual)
    origin_address          TEXT,
    origin_city             TEXT,
    origin_state            TEXT,
    origin_latitude         DOUBLE PRECISION,
    origin_longitude        DOUBLE PRECISION,
    origin_accuracy         DOUBLE PRECISION,
    origin_timestamp        TIMESTAMPTZ,
    origin_source           TEXT DEFAULT 'GPS',   -- GPS, MANUAL

    -- Destination
    destination_address     TEXT,
    destination_city        TEXT,
    destination_state       TEXT,
    destination_latitude    DOUBLE PRECISION,
    destination_longitude   DOUBLE PRECISION,

    -- Date / Time
    required_date           DATE,
    time_window_start       TIME,
    time_window_end         TIME,

    -- Truck details (snapshot at creation)
    capacity                TEXT,
    capacity_unit           TEXT DEFAULT 'Ton',
    vehicle_type            TEXT,
    body_type               TEXT,

    -- Lifecycle
    status                  TEXT NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, ACTIVE, MATCHED, COMPLETED, EXPIRED, CANCELLED
    expires_at              TIMESTAMPTZ,
    completed_at            TIMESTAMPTZ,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- Enforce: 1 active requirement per partner
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_requirement_per_partner
    ON public.return_requirements(partner_id)
    WHERE status = 'ACTIVE';

-- ============================================================
-- CONTACT EVENTS
-- Saved whenever customer presses Call or WhatsApp.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.contact_events (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id          UUID REFERENCES public.partners(id) ON DELETE SET NULL,
    requirement_id      UUID REFERENCES public.return_requirements(id) ON DELETE SET NULL,
    contact_type        TEXT NOT NULL,   -- CALL, WHATSAPP
    session_reference   TEXT,            -- anonymous session token if available
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- NOTIFICATIONS
-- In-app notification center for partners.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id      UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    type            TEXT NOT NULL,
    -- DOCUMENT_APPROVED, DOCUMENT_REJECTED, DOCUMENT_EXPIRING,
    -- PARTNER_VERIFIED, REQUIREMENT_ACTIVE, REQUIREMENT_EXPIRING,
    -- CONTACT_RECEIVED, SYSTEM
    title           TEXT NOT NULL,
    message         TEXT,
    reference_type  TEXT,
    reference_id    UUID,
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PAYMENTS
-- Onboarding payment records. Success only from trusted backend.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.payments (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id                  UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    amount                      NUMERIC,
    currency                    TEXT DEFAULT 'INR',
    purpose                     TEXT,     -- ONBOARDING, SUBSCRIPTION_RENEWAL
    status                      TEXT NOT NULL DEFAULT 'PENDING',
    -- PENDING, INITIATED, SUCCESS, FAILED, REFUNDED
    transaction_reference       TEXT,
    payment_gateway_reference   TEXT,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- AUDIT LOGS
-- Every important state change is recorded.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_type  TEXT,              -- PARTNER, ADMIN, SYSTEM
    actor_id    TEXT,
    action      TEXT NOT NULL,
    entity_type TEXT,              -- partner, truck, document, requirement, payment
    entity_id   UUID,
    old_data    JSONB,
    new_data    JSONB,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trucks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.return_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Partners: can only see/edit their own record
-- Match on firebase_uid stored in JWT claim
CREATE POLICY "partner_self_access"
    ON public.partners FOR ALL
    TO authenticated
    USING (firebase_uid = (current_setting('request.jwt.claims', true)::json->>'sub')::text);

-- Also allow insert for new partner creation
CREATE POLICY "partner_insert"
    ON public.partners FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);

-- Trucks: partner sees only their trucks
CREATE POLICY "truck_owner_access"
    ON public.trucks FOR ALL
    TO authenticated
    USING (partner_id IN (
        SELECT id FROM public.partners
        WHERE firebase_uid = (current_setting('request.jwt.claims', true)::json->>'sub')::text
    ));

-- Documents: partner sees only their docs
CREATE POLICY "document_owner_access"
    ON public.documents FOR ALL
    TO authenticated
    USING (partner_id IN (
        SELECT id FROM public.partners
        WHERE firebase_uid = (current_setting('request.jwt.claims', true)::json->>'sub')::text
    ));

-- Return Requirements: partner sees own; customers see ACTIVE ones (anon search)
CREATE POLICY "requirement_owner_access"
    ON public.return_requirements FOR ALL
    TO authenticated
    USING (partner_id IN (
        SELECT id FROM public.partners
        WHERE firebase_uid = (current_setting('request.jwt.claims', true)::json->>'sub')::text
    ));

CREATE POLICY "requirement_customer_search"
    ON public.return_requirements FOR SELECT
    TO anon, authenticated
    USING (status = 'ACTIVE');

-- Notifications: partner sees only their own
CREATE POLICY "notification_owner_access"
    ON public.notifications FOR ALL
    TO authenticated
    USING (partner_id IN (
        SELECT id FROM public.partners
        WHERE firebase_uid = (current_setting('request.jwt.claims', true)::json->>'sub')::text
    ));

-- Payments: partner sees only their own
CREATE POLICY "payment_owner_access"
    ON public.payments FOR ALL
    TO authenticated
    USING (partner_id IN (
        SELECT id FROM public.partners
        WHERE firebase_uid = (current_setting('request.jwt.claims', true)::json->>'sub')::text
    ));

-- Contact events: anonymous inserts allowed (customer contacts partner)
CREATE POLICY "contact_event_insert"
    ON public.contact_events FOR INSERT
    TO anon, authenticated
    WITH CHECK (TRUE);

-- Allow anon key access for Flutter client (since Flutter app uses Firebase Auth)
CREATE POLICY "anon_all_partners" ON public.partners FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "anon_all_trucks" ON public.trucks FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "anon_all_documents" ON public.documents FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "anon_all_requirements" ON public.return_requirements FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "anon_all_contact_events" ON public.contact_events FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "anon_all_notifications" ON public.notifications FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "anon_all_payments" ON public.payments FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('documents', 'documents', true),
    ('profiles', 'profiles', true),
    ('partner-documents', 'partner-documents', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "public_storage_select" ON storage.objects FOR SELECT USING (true);
CREATE POLICY "public_storage_insert" ON storage.objects FOR INSERT WITH CHECK (true);
CREATE POLICY "public_storage_update" ON storage.objects FOR UPDATE USING (true);
CREATE POLICY "public_storage_delete" ON storage.objects FOR DELETE USING (true);

