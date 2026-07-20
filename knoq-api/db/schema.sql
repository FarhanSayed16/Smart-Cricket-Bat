-- KnoQ PostgreSQL Schema (Phase 2 — Multi-Academy/Multi-Coach)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: academies
CREATE TABLE academies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    owner_uid VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    plan VARCHAR(50) DEFAULT 'free',
    join_code VARCHAR(50) UNIQUE,
    max_players INT DEFAULT 50,
    max_coaches INT DEFAULT 5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('player', 'coach', 'admin')),
    batting_hand VARCHAR(10) CHECK (batting_hand IN ('Left', 'Right')),
    age INT,
    onboarding_complete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    profile_image_url TEXT,
    fcm_token TEXT,
    app_version VARCHAR(50),
    last_login_at TIMESTAMP WITH TIME ZONE,
    deletion_requested_at TIMESTAMP WITH TIME ZONE
);

-- Table: academy_memberships (N:M — users ↔ academies)
CREATE TABLE academy_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('player', 'coach', 'admin')),
    status VARCHAR(50) DEFAULT 'active',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, academy_id)
);

-- Table: coach_assignments (N:M — coaches ↔ players, scoped to academy)
CREATE TABLE coach_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coach_id UUID REFERENCES users(id) ON DELETE CASCADE,
    player_id UUID REFERENCES users(id) ON DELETE CASCADE,
    academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(coach_id, player_id, academy_id)
);

-- Table: devices
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mac_address VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) DEFAULT 'KnoQ-Bat-V1',
    academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
    firmware_version VARCHAR(50),
    current_assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP WITH TIME ZONE
);

-- Table: sessions
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES users(id) ON DELETE CASCADE,
    academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'completed',
    total_hits INT DEFAULT 0,
    sweet_spot_pct INT DEFAULT 0,
    avg_power INT DEFAULT 0,
    peak_power INT DEFAULT 0,
    avg_swing DECIMAL(7,2),
    peak_swing DECIMAL(7,2),
    zone_distribution JSONB,
    consistency_score INT,
    insights JSONB,
    coach_note TEXT,
    app_version VARCHAR(50),
    firmware_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: shots
CREATE TABLE shots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    shot_number INT NOT NULL,
    zone VARCHAR(50) NOT NULL,
    power INT NOT NULL CHECK (power >= 0 AND power <= 100),
    swing DECIMAL(7,2),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: coach_notes
CREATE TABLE coach_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coach_id UUID REFERENCES users(id) ON DELETE CASCADE,
    player_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: pending_invites
CREATE TABLE pending_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('player', 'coach')),
    invited_by UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(email, academy_id)
);

-- Indexes
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_academy_memberships_user ON academy_memberships(user_id);
CREATE INDEX idx_academy_memberships_academy ON academy_memberships(academy_id);
CREATE INDEX idx_coach_assignments_player ON coach_assignments(player_id);
CREATE INDEX idx_coach_assignments_coach ON coach_assignments(coach_id);
CREATE INDEX idx_sessions_player_id ON sessions(player_id);
CREATE INDEX idx_sessions_academy_id ON sessions(academy_id);
CREATE INDEX idx_shots_session_id ON shots(session_id);
CREATE INDEX idx_coach_notes_session_id ON coach_notes(session_id);
