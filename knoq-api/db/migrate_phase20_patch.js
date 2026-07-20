const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function runPatch() {
    console.log('Patching Phase 20 — adding missing columns...');
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // Add missing columns to shot_analysis
        console.log('Adding quality_rating and tagging_metadata to shot_analysis...');
        await client.query(`
            ALTER TABLE shot_analysis 
            ADD COLUMN IF NOT EXISTS quality_rating INT DEFAULT 0,
            ADD COLUMN IF NOT EXISTS tagging_metadata JSONB DEFAULT '{"tagged": false}'::jsonb;
        `);

        // Add composite index
        console.log('Adding composite index on shot_analysis...');
        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_shot_analysis_session_shot ON shot_analysis(session_id, shot_number);
        `);

        // Enhance video_settings default to include fps
        console.log('Updating video_settings default to include fps...');
        await client.query(`
            UPDATE academies 
            SET video_settings = video_settings || '{"fps": 30}'::jsonb
            WHERE video_settings IS NOT NULL AND NOT video_settings ? 'fps';
        `);

        await client.query('COMMIT');
        console.log('Patch completed successfully!');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Patch failed:', error);
    } finally {
        client.release();
        pool.end();
    }
}

runPatch();
