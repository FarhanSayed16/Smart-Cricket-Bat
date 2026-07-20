require('dotenv').config();
const admin = require('firebase-admin');
const db = require('./db');

async function seedVisitor() {
    console.log('Starting seed process for Visitor Mode...');

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
        // 1. Create Firebase User
        const email = 'visitor@knoq.in';
        const password = 'visitor123';
        const name = 'Portfolio Visitor';
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
                console.log('Visitor user already exists in Firebase, fetching UID...');
                const userRecord = await admin.auth().getUserByEmail(email);
                firebaseUid = userRecord.uid;
                
                await admin.auth().updateUser(firebaseUid, { password });
                console.log('Updated existing visitor password.');
            } else {
                throw error;
            }
        }

        // 2. Create User in Postgres
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
        const visitorId = userResult.rows[0].id;
        console.log('Postgres Visitor ID:', visitorId);

        // 3. Create "KnoQ Demo Academy"
        console.log('Creating KnoQ Demo Academy...');
        const academyQuery = `
            INSERT INTO academies (name, owner_uid, city, state, join_code)
            VALUES ('KnoQ Demo Academy', $1, 'Virtual', 'WWW', 'DEMO01')
            ON CONFLICT DO NOTHING
            RETURNING id;
        `;
        let academyId;
        const academyResult = await db.query(academyQuery, [firebaseUid]);
        
        if (academyResult.rows.length > 0) {
            academyId = academyResult.rows[0].id;
        } else {
            const existingQuery = await db.query(`SELECT id FROM academies WHERE name = 'KnoQ Demo Academy' LIMIT 1`);
            if(existingQuery.rows.length > 0) {
                academyId = existingQuery.rows[0].id;
            } else {
                // If it conflicted on join code for some reason
                const existingCodeQuery = await db.query(`SELECT id FROM academies WHERE join_code = 'DEMO01' LIMIT 1`);
                academyId = existingCodeQuery.rows[0].id;
            }
        }
        console.log('Academy ID:', academyId);

        // 4. Link user to academy as admin
        await db.query(`
            INSERT INTO academy_memberships (user_id, academy_id, role, status)
            VALUES ($1, $2, 'admin', 'active')
            ON CONFLICT (user_id, academy_id) DO UPDATE SET status = 'active', role = 'admin'
        `, [visitorId, academyId]);

        // 5. Seed some dummy players for this academy
        console.log('Seeding dummy players...');
        const dummyPlayers = [
            { email: 'player1_demo@knoq.in', name: 'Rahul Deshmukh', role: 'player' },
            { email: 'player2_demo@knoq.in', name: 'Karan Singh', role: 'player' },
            { email: 'player3_demo@knoq.in', name: 'Arjun Patel', role: 'player' }
        ];

        for (const dp of dummyPlayers) {
            let pUid = 'demo_uid_' + Math.random().toString(36).substring(7);
            const pq = `
                INSERT INTO users (firebase_uid, email, name, role, onboarding_complete)
                VALUES ($1, $2, $3, $4, true)
                ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
                RETURNING id;
            `;
            const pr = await db.query(pq, [pUid, dp.email, dp.name, dp.role]);
            const pId = pr.rows[0].id;

            await db.query(`
                INSERT INTO academy_memberships (user_id, academy_id, role, status)
                VALUES ($1, $2, 'player', 'active')
                ON CONFLICT (user_id, academy_id) DO UPDATE SET status = 'active'
            `, [pId, academyId]);
        }

        // 5.5 Seed Dummy Coaches
        console.log('Seeding dummy coaches...');
        const dummyCoaches = [
            { email: 'coach1_demo@knoq.in', name: 'Ravi Shastri', role: 'coach' },
            { email: 'coach2_demo@knoq.in', name: 'Gary Kirsten', role: 'coach' }
        ];

        for (const dc of dummyCoaches) {
            let cUid = 'demo_coach_' + Math.random().toString(36).substring(7);
            const cq = `
                INSERT INTO users (firebase_uid, email, name, role, onboarding_complete)
                VALUES ($1, $2, $3, $4, true)
                ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
                RETURNING id;
            `;
            const cr = await db.query(cq, [cUid, dc.email, dc.name, dc.role]);
            const cId = cr.rows[0].id;

            await db.query(`
                INSERT INTO academy_memberships (user_id, academy_id, role, status)
                VALUES ($1, $2, 'coach', 'active')
                ON CONFLICT (user_id, academy_id) DO UPDATE SET status = 'active'
            `, [cId, academyId]);
        }

        // 6. Seed Devices
        console.log('Seeding dummy devices...');
        await db.query(`
            INSERT INTO devices (academy_id, name, mac_address, firmware_version, battery_level, status)
            VALUES 
                ($1, 'Demo Bat (Main)', 'AA:BB:CC:11:22:33', 'v1.1.0', 95, 'online'),
                ($1, 'Demo Bat (Backup)', 'AA:BB:CC:11:22:44', 'v1.1.0', 50, 'offline')
            ON CONFLICT (mac_address) DO UPDATE SET 
                academy_id = EXCLUDED.academy_id;
        `, [academyId]);

        // 7. Seed Sessions (30 days historical data)
        console.log('Seeding historical sessions...');
        const deviceQuery = await db.query(`SELECT id FROM devices WHERE academy_id = $1 LIMIT 1`, [academyId]);
        const devId = deviceQuery.rows[0].id;

        const playerQuery = await db.query(`
            SELECT u.id FROM users u 
            JOIN academy_memberships am ON u.id = am.user_id
            WHERE am.academy_id = $1 AND am.role = 'player'
        `, [academyId]);
        const pIds = playerQuery.rows.map(r => r.id);

        const now = new Date();
        for (let i = 0; i < 30; i++) {
            const date = new Date(now);
            date.setDate(date.getDate() - (29 - i));
            
            // Random number of sessions for this day (1 to 5)
            const numSessions = Math.floor(Math.random() * 5) + 1;
            
            for (let j = 0; j < numSessions; j++) {
                const pId = pIds[Math.floor(Math.random() * pIds.length)];
                
                // Randomize time within the day
                const start = new Date(date);
                start.setHours(Math.floor(Math.random() * 10) + 8); // 8 AM to 6 PM
                const end = new Date(start);
                end.setMinutes(start.getMinutes() + Math.floor(Math.random() * 60) + 30); // 30-90 min session

                const totalHits = Math.floor(Math.random() * 150) + 50;
                
                await db.query(`
                    INSERT INTO sessions (
                        player_id, academy_id, device_id, start_time, end_time, status,
                        total_hits, sweet_spot_pct, avg_power, peak_power, avg_swing, peak_swing,
                        consistency_score
                    ) VALUES ($1, $2, $3, $4, $5, 'completed', $6, $7, $8, $9, $10, $11, $12)
                `, [
                    pId, academyId, devId, start, end,
                    totalHits, // total_hits
                    Math.floor(Math.random() * 30) + 50, // sweet_spot
                    Math.floor(Math.random() * 40) + 40, // avg_power
                    Math.floor(Math.random() * 20) + 80, // peak_power
                    Math.floor(Math.random() * 30) + 60, // avg_swing
                    Math.floor(Math.random() * 20) + 90, // peak_swing
                    Math.floor(Math.random() * 20) + 75  // consistency
                ]);
            }
        }

        console.log('Visitor Seed completed successfully!');
        process.exit(0);

    } catch (error) {
        console.error('Visitor Seed failed:', error);
        process.exit(1);
    }
}

seedVisitor();
