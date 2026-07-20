const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

router.post('/register', verifyToken, async (req, res) => {
    try {
        // req.user is populated by verifyToken middleware (Firebase user)
        const { uid, email } = req.user;
        const { name } = req.body;

        if (!name) {
            return res.status(400).json({ status: 'error', message: 'Name is required' });
        }

        // Check if there's a pending invite for this email (coach or specific role)
        let assignedRole = 'player';
        let assignedAcademyId = null;

        const inviteQuery = `
            SELECT * FROM pending_invites 
            WHERE email = $1 AND status = 'pending' 
            ORDER BY created_at DESC 
            LIMIT 1
        `;
        const inviteResult = await db.query(inviteQuery, [email]);

        if (inviteResult.rows.length > 0) {
            const invite = inviteResult.rows[0];
            assignedRole = invite.role; // 'coach' or 'player'
            assignedAcademyId = invite.academy_id;

            // Mark invite as accepted
            await db.query(
                "UPDATE pending_invites SET status = 'accepted' WHERE id = $1",
                [invite.id]
            );
        }

        // Insert user into PostgreSQL
        // ON CONFLICT: If the email already exists (e.g. user deleted Firebase account
        // and re-registered), update firebase_uid, name, role, and RESET onboarding
        // so they go through the fresh flow again.
        const insertQuery = `
            INSERT INTO users (firebase_uid, email, name, role, onboarding_complete)
            VALUES ($1, $2, $3, $4, false)
            ON CONFLICT (email) DO UPDATE SET 
                firebase_uid = EXCLUDED.firebase_uid, 
                name = EXCLUDED.name,
                role = EXCLUDED.role,
                onboarding_complete = false
            RETURNING *;
        `;
        
        const result = await db.query(insertQuery, [uid, email, name, assignedRole]);
        const user = result.rows[0];

        // Insert academy membership if an invite was found
        if (assignedAcademyId) {
            const membershipQuery = `
                INSERT INTO academy_memberships (user_id, academy_id, role)
                VALUES ($1, $2, $3)
                ON CONFLICT (user_id, academy_id) DO NOTHING;
            `;
            await db.query(membershipQuery, [user.id, assignedAcademyId, assignedRole]);
        }
        
        res.status(201).json({
            status: 'success',
            data: user
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ status: 'error', message: 'Failed to create user profile in database' });
    }
});

module.exports = router;
