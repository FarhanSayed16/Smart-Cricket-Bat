require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function run() {
    try {
        await pool.query('DELETE FROM users');
        console.log("Successfully wiped all test users from the database.");
    } catch (err) {
        console.error("Error wiping users:", err);
    } finally {
        await pool.end();
    }
}

run();
