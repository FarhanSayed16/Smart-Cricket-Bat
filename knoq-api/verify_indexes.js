require('dotenv').config();
const db = require('./db');

const requiredIndexes = [
    {
        name: 'idx_users_firebase_uid',
        table: 'users',
        columns: '(firebase_uid)'
    },
    {
        name: 'idx_sessions_player_id',
        table: 'sessions',
        columns: '(player_id)'
    },
    {
        name: 'idx_shots_session_id',
        table: 'shots',
        columns: '(session_id)'
    },
    {
        name: 'idx_academy_memberships_user_id',
        table: 'academy_memberships',
        columns: '(user_id)'
    },
    {
        name: 'idx_academy_memberships_academy_id',
        table: 'academy_memberships',
        columns: '(academy_id)'
    }
];

async function verifyIndexes() {
    console.log('Starting index verification...');
    try {
        for (const idx of requiredIndexes) {
            const query = `
                SELECT indexname 
                FROM pg_indexes 
                WHERE tablename = '${idx.table}' AND indexname = '${idx.name}'
            `;
            const res = await db.query(query);
            
            if (res.rows.length === 0) {
                console.log(`[Missing] ${idx.name} on ${idx.table}. Creating...`);
                const createQuery = `CREATE INDEX IF NOT EXISTS ${idx.name} ON ${idx.table} ${idx.columns}`;
                await db.query(createQuery);
                console.log(`[Created] ${idx.name} created successfully.`);
            } else {
                console.log(`[OK] Index ${idx.name} already exists on ${idx.table}.`);
            }
        }
        console.log('Index verification completed successfully.');
    } catch (error) {
        console.error('Error during index verification:', error);
    } finally {
        process.exit(0);
    }
}

if (require.main === module) {
    verifyIndexes();
}

module.exports = verifyIndexes;
