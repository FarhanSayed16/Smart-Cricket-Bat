require('dotenv').config();
const db = require('./db');

async function reset() {
    // Reset onboarding for all non-coach users so they get the fresh flow
    const result = await db.query(
        "UPDATE users SET onboarding_complete = false WHERE email != 'coach@knoq.com'"
    );
    console.log('Reset ' + result.rowCount + ' user(s) onboarding_complete to false');
    process.exit(0);
}

reset().catch(e => { console.error(e); process.exit(1); });
