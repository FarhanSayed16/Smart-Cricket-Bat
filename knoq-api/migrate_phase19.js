require('dotenv').config();
const db = require('./db');

async function migrate() {
    console.log('Starting Phase 19 Database Migration...');
    
    try {
        // 1. Modify academies table for PDF exports (Phase 19.2)
        console.log('Adding logo_url to academies table...');
        await db.query(`
            ALTER TABLE academies 
            ADD COLUMN IF NOT EXISTS logo_url VARCHAR(255);
        `);

        // 2. Create coach_note_replies table (Phase 19.1)
        console.log('Creating coach_note_replies table...');
        await db.query(`
            CREATE TABLE IF NOT EXISTS coach_note_replies (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                note_id UUID REFERENCES coach_notes(id) ON DELETE CASCADE,
                sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
                reply_text TEXT NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // 3. Create drills table (Phase 19.3)
        console.log('Creating drills table...');
        await db.query(`
            CREATE TABLE IF NOT EXISTS drills (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
                coach_id UUID REFERENCES users(id) ON DELETE SET NULL,
                player_id UUID REFERENCES users(id) ON DELETE CASCADE,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                target_zone VARCHAR(50),
                min_power INTEGER,
                target_shot_count INTEGER NOT NULL,
                deadline TIMESTAMP WITH TIME ZONE,
                status VARCHAR(50) DEFAULT 'assigned' CHECK (status IN ('assigned', 'completed', 'expired')),
                completed_at TIMESTAMP WITH TIME ZONE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // 4. Update coach_notes table to ensure it has tags array if not already present
        // (It was in our earlier schema, but making sure)
        console.log('Ensuring coach_notes has tags array...');
        await db.query(`
            ALTER TABLE coach_notes
            ADD COLUMN IF NOT EXISTS tags VARCHAR(50)[];
        `);

        console.log('Phase 19 Migration completed successfully!');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

migrate();
