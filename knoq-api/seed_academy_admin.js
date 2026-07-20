require('dotenv').config();
const admin = require('firebase-admin');
const db = require('./db');

async function seedAcademyAdmin() {
    console.log('Starting seed process for Academy Admin...');

    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        }
        console.log('Firebase Admin initialized.');
    } catch (error) {
        console.error('Firebase initialization error:', error);
        process.exit(1);
    }

    try {
        // Find the "KnoQ HQ" Academy to associate this admin with
        const academyQuery = await db.query(`SELECT id FROM academies WHERE name = 'KnoQ HQ' LIMIT 1`);
        if (academyQuery.rows.length === 0) {
            throw new Error("KnoQ HQ academy not found. Please run seed_super_admin.js first.");
        }
        const academyId = academyQuery.rows[0].id;

        // Create Firebase User
        const email = 'academy_admin@knoq.com';
        const password = 'Admin@123';
        const name = 'KnoQ HQ Admin';
        let firebaseUid;

        try {
            console.log(`Creating Firebase user: ${email}...`);
            const userRecord = await admin.auth().createUser({
                email,
                password,
                displayName: name,
            });
            firebaseUid = userRecord.uid;
            console.log('Successfully created new Firebase user:', firebaseUid);
        } catch (error) {
            if (error.code === 'auth/email-already-exists') {
                console.log('User already exists in Firebase, fetching UID...');
                const userRecord = await admin.auth().getUserByEmail(email);
                firebaseUid = userRecord.uid;
                
                await admin.auth().updateUser(firebaseUid, { password });
                console.log('Updated existing user password.');
            } else {
                throw error;
            }
        }

        // Create User in Postgres
        console.log('Upserting user into Postgres with admin role...');
        const userQuery = `
            INSERT INTO users (firebase_uid, email, name, role, onboarding_complete)
            VALUES ($1, $2, $3, 'admin', true)
            ON CONFLICT (email) DO UPDATE SET 
                firebase_uid = EXCLUDED.firebase_uid, 
                name = EXCLUDED.name,
                role = 'admin',
                onboarding_complete = true
            RETURNING id;
        `;
        const userResult = await db.query(userQuery, [firebaseUid, email, name]);
        const userId = userResult.rows[0].id;

        // Link user to academy as admin
        await db.query(`
            INSERT INTO academy_memberships (user_id, academy_id, role, status)
            VALUES ($1, $2, 'admin', 'active')
            ON CONFLICT (user_id, academy_id) DO UPDATE SET status = 'active', role = 'admin'
        `, [userId, academyId]);

        console.log('Academy Admin Seed completed successfully!');
        process.exit(0);

    } catch (error) {
        console.error('Seed failed:', error);
        process.exit(1);
    }
}

seedAcademyAdmin();
