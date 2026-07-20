require('dotenv').config();
const admin = require('firebase-admin');
const db = require('./db');

async function seed() {
    console.log('Starting seed process...');

    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized.');
    } catch (error) {
        console.error('Firebase initialization error:', error);
        process.exit(1);
    }

    try {
        // 1. Update the role constraint to allow 'super' if not already allowed
        console.log('Updating user roles constraint...');
        await db.query(`
            DO $$ 
            BEGIN
                ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
                ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('player', 'coach', 'admin', 'super'));
            EXCEPTION
                WHEN others THEN
                    RAISE NOTICE 'Error updating constraint: %', SQLERRM;
            END $$;
        `);

        // 2. Create the devices table
        console.log('Creating devices table...');
        await db.query(`
            CREATE TABLE IF NOT EXISTS devices (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
                name VARCHAR(255) NOT NULL,
                mac_address VARCHAR(255) UNIQUE NOT NULL,
                firmware_version VARCHAR(50),
                battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
                last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
                status VARCHAR(50) DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'charging', 'error')),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // 3. Create Firebase User
        const email = 'farhansayed54@gmail.com';
        const password = 'Farhan@123';
        const name = 'Farhan Super Admin';
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
                
                // Optionally update the password if it exists
                await admin.auth().updateUser(firebaseUid, { password });
                console.log('Updated existing user password.');
            } else {
                throw error;
            }
        }

        // 4. Create User in Postgres
        console.log('Upserting user into Postgres with super role...');
        const userQuery = `
            INSERT INTO users (firebase_uid, email, name, role, onboarding_complete)
            VALUES ($1, $2, $3, 'super', true)
            ON CONFLICT (email) DO UPDATE SET 
                firebase_uid = EXCLUDED.firebase_uid, 
                name = EXCLUDED.name,
                role = 'super',
                onboarding_complete = true
            RETURNING id;
        `;
        const userResult = await db.query(userQuery, [firebaseUid, email, name]);
        const userId = userResult.rows[0].id;
        console.log('Postgres User ID:', userId);

        // 5. Create "KnoQ HQ" Academy
        console.log('Creating KnoQ HQ Academy...');
        const academyQuery = `
            INSERT INTO academies (name, owner_uid, city, state, join_code)
            VALUES ('KnoQ HQ', $1, 'Mumbai', 'MH', 'KNOQ01')
            ON CONFLICT DO NOTHING
            RETURNING id;
        `;
        let academyId;
        const academyResult = await db.query(academyQuery, [firebaseUid]);
        
        if (academyResult.rows.length > 0) {
            academyId = academyResult.rows[0].id;
        } else {
            // Find it if it already existed
            const existingQuery = await db.query(`SELECT id FROM academies WHERE name = 'KnoQ HQ' LIMIT 1`);
            academyId = existingQuery.rows[0].id;
        }
        console.log('Academy ID:', academyId);

        // 6. Link user to academy as super/admin
        await db.query(`
            INSERT INTO academy_memberships (user_id, academy_id, role, status)
            VALUES ($1, $2, 'admin', 'active')
            ON CONFLICT (user_id, academy_id) DO UPDATE SET status = 'active', role = 'admin'
        `, [userId, academyId]);

        // 7. Seed Devices
        console.log('Seeding devices...');
        await db.query(`
            INSERT INTO devices (academy_id, name, mac_address, firmware_version, battery_level, status)
            VALUES 
                ($1, 'Bat 01 (Master)', '00:1B:44:11:3A:B7', 'v1.0.4', 85, 'online'),
                ($1, 'Bat 02 (Test)', '00:1B:44:11:3A:B8', 'v1.0.3', 20, 'charging'),
                ($1, 'Bat 03 (Demo)', '00:1B:44:11:3A:B9', 'v1.0.4', 100, 'offline')
            ON CONFLICT (mac_address) DO UPDATE SET 
                academy_id = EXCLUDED.academy_id;
        `, [academyId]);

        console.log('Seed completed successfully!');
        process.exit(0);

    } catch (error) {
        console.error('Migration/Seed failed:', error);
        process.exit(1);
    }
}

seed();
