require('dotenv').config();
const { Pool } = require('pg');
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function seed() {
    const coachEmail = 'coach@knoq.com';
    const coachPassword = 'Password123!';
    const coachName = 'Head Coach Elite';

    try {
        console.log('1. Checking Firebase...');
        let userRecord;
        try {
            userRecord = await admin.auth().getUserByEmail(coachEmail);
            console.log('User already exists in Firebase, updating password...');
            await admin.auth().updateUser(userRecord.uid, { password: coachPassword });
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                console.log('Creating new user in Firebase...');
                userRecord = await admin.auth().createUser({
                    email: coachEmail,
                    password: coachPassword,
                    displayName: coachName,
                });
            } else {
                throw error;
            }
        }

        const uid = userRecord.uid;
        console.log(`Firebase UID: ${uid}`);

        console.log('2. Upserting Coach into PostgreSQL...');
        const userQuery = `
            INSERT INTO users (firebase_uid, email, name, role)
            VALUES ($1, $2, $3, 'coach')
            ON CONFLICT (email) DO UPDATE SET role = 'coach', name = EXCLUDED.name, firebase_uid = EXCLUDED.firebase_uid
            RETURNING id;
        `;
        const userResult = await pool.query(userQuery, [uid, coachEmail, coachName]);
        const dbUserId = userResult.rows[0].id;

        console.log('3. Upserting Academy...');
        // We will just create a new academy if one doesn't exist for this owner
        const academyQuery = `
            INSERT INTO academies (name, owner_uid, city, state, join_code)
            VALUES ('Elite KnoQ Academy', $1, 'Mumbai', 'MH', 'ELITE2026')
            ON CONFLICT (join_code) DO UPDATE SET name = EXCLUDED.name
            RETURNING id;
        `;
        const academyResult = await pool.query(academyQuery, [uid]);
        const academyId = academyResult.rows[0].id;

        console.log('4. Linking Coach to Academy...');
        await pool.query(`
            INSERT INTO academy_memberships (user_id, academy_id, role)
            VALUES ($1, $2, 'coach')
            ON CONFLICT (user_id, academy_id) DO UPDATE SET status = 'active'
        `, [dbUserId, academyId]);

        console.log('\n✅ SEEDING COMPLETE!');
        console.log('--------------------------------------------------');
        console.log('You can now log into the app using these credentials:');
        console.log(`Email:    ${coachEmail}`);
        console.log(`Password: ${coachPassword}`);
        console.log(`Academy Join Code: ELITE2026`);
        console.log('--------------------------------------------------');

    } catch (err) {
        console.error('Seeding error:', err);
    } finally {
        await pool.end();
        process.exit(0);
    }
}

seed();
