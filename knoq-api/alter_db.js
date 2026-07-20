require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false } // Required for Supabase
});

async function run() {
    try {
        const query = `
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS profile_image_url VARCHAR(500),
            ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255),
            ADD COLUMN IF NOT EXISTS app_version VARCHAR(50),
            ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE,
            ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMP WITH TIME ZONE;
        `;
        await pool.query(query);
        console.log("Successfully added missing columns to users table.");
    } catch (err) {
        console.error("Error altering table:", err);
    } finally {
        await pool.end();
    }
}

run();
