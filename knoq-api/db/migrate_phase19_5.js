const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function migrate() {
    console.log('Starting Phase 19.5-19.7 Migration...');
    try {
        await pool.query(`
            ALTER TABLE academies 
            ADD COLUMN IF NOT EXISTS weekly_report_opt_out BOOLEAN DEFAULT false;
        `);
        console.log('Added weekly_report_opt_out to academies.');

        console.log('Migration Phase 19.5-19.7 completed successfully.');
    } catch (error) {
        console.error('Migration failed:', error);
    } finally {
        await pool.end();
    }
}

migrate();
