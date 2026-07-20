const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function runMigration() {
    console.log('Starting Phase 20 Database Migration...');
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // 1. Add video_settings to academies
        console.log('Adding video_settings to academies...');
        await client.query(`
            ALTER TABLE academies 
            ADD COLUMN IF NOT EXISTS video_settings JSONB DEFAULT '{"resolution": "1080p", "clip_padding_ms": 4000}'::jsonb;
        `);

        // 2. Add video_url to sessions
        console.log('Adding video_url to sessions...');
        await client.query(`
            ALTER TABLE sessions 
            ADD COLUMN IF NOT EXISTS video_url TEXT;
        `);

        // 3. Add clip_url and video_offset_ms to shots
        console.log('Adding clip_url and video_offset_ms to shots...');
        await client.query(`
            ALTER TABLE shots 
            ADD COLUMN IF NOT EXISTS clip_url TEXT,
            ADD COLUMN IF NOT EXISTS video_offset_ms INT;
        `);

        // 4. Create shot_analysis table
        console.log('Creating shot_analysis table...');
        await client.query(`
            CREATE TABLE IF NOT EXISTS shot_analysis (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
                shot_number INT NOT NULL,
                clip_url TEXT,
                delivery_type VARCHAR(50),
                shot_type VARCHAR(50),
                scores JSONB,
                pose_landmarks JSONB,
                feedback TEXT,
                quality_rating INT DEFAULT 0,
                tagging_metadata JSONB DEFAULT '{"tagged": false}'::jsonb,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_shot_analysis_session ON shot_analysis(session_id);
            CREATE INDEX IF NOT EXISTS idx_shot_analysis_session_shot ON shot_analysis(session_id, shot_number);
        `);

        // 5. Create ai_models table
        console.log('Creating ai_models table...');
        await client.query(`
            CREATE TABLE IF NOT EXISTS ai_models (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                model_name VARCHAR(100) NOT NULL,
                version VARCHAR(50) NOT NULL,
                accuracy DECIMAL(5,2),
                tflite_url TEXT,
                is_deployed BOOLEAN DEFAULT false,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);

        await client.query('COMMIT');
        console.log('Migration completed successfully!');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Migration failed:', error);
    } finally {
        client.release();
        pool.end();
    }
}

runMigration();
