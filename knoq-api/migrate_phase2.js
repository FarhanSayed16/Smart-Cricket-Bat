require('dotenv').config();
const db = require('./db');

async function migrate() {
    console.log('Starting Phase 2 Database Migration...');
    
    try {
        // 1. Create junction tables
        console.log('Creating academy_memberships table...');
        await db.query(`
            CREATE TABLE IF NOT EXISTS academy_memberships (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
                role VARCHAR(50) NOT NULL CHECK (role IN ('player', 'coach', 'admin')),
                status VARCHAR(50) DEFAULT 'active',
                joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, academy_id)
            );
        `);

        console.log('Creating coach_assignments table...');
        await db.query(`
            CREATE TABLE IF NOT EXISTS coach_assignments (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                coach_id UUID REFERENCES users(id) ON DELETE CASCADE,
                player_id UUID REFERENCES users(id) ON DELETE CASCADE,
                academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
                assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(coach_id, player_id, academy_id)
            );
        `);

        // 2. Migrate existing data (if any)
        console.log('Migrating existing 1:1 academy and coach assignments to junction tables...');
        
        // Migrate academy_id to academy_memberships
        await db.query(`
            INSERT INTO academy_memberships (user_id, academy_id, role)
            SELECT id, academy_id, role 
            FROM users 
            WHERE academy_id IS NOT NULL
            ON CONFLICT (user_id, academy_id) DO NOTHING;
        `);

        // Migrate assigned_coach_id to coach_assignments
        await db.query(`
            INSERT INTO coach_assignments (coach_id, player_id, academy_id)
            SELECT assigned_coach_id, id, academy_id
            FROM users
            WHERE assigned_coach_id IS NOT NULL AND academy_id IS NOT NULL
            ON CONFLICT (coach_id, player_id, academy_id) DO NOTHING;
        `);

        // 3. Drop old columns from users table
        console.log('Dropping legacy columns from users table...');
        await db.query(`
            ALTER TABLE users 
            DROP COLUMN IF EXISTS assigned_coach_id,
            DROP COLUMN IF EXISTS academy_id;
        `);

        console.log('Migration completed successfully!');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

migrate();
