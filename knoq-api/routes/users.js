const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

// Get current user profile
router.get('/me', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        console.log('Fetching /me for UID:', uid);

        const query = `
            SELECT u.*, 
                   am.academy_id,
                   ca.coach_id as assigned_coach_id,
                   CASE 
                       WHEN a.owner_uid = u.firebase_uid THEN true 
                       ELSE false 
                   END as is_academy_owner
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            LEFT JOIN academies a ON am.academy_id = a.id
            LEFT JOIN coach_assignments ca ON u.id = ca.player_id
            WHERE u.firebase_uid = $1
            -- If user has multiple academies, this returns the first one. 
            -- For MVP we keep 1 academy per user on the frontend.
            LIMIT 1
        `;
        const result = await db.query(query, [uid]);

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'User profile not found' });
        }

        res.status(200).json({
            status: 'success',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch user profile' });
    }
});

// Get player's assigned coaches
router.get('/me/coaches', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;

        // Get the player's internal ID
        const userQuery = 'SELECT id FROM users WHERE firebase_uid = $1';
        const userResult = await db.query(userQuery, [uid]);
        if (userResult.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'User profile not found' });
        }
        const playerId = userResult.rows[0].id;

        const query = `
            SELECT c.id, c.name, c.email, c.profile_image_url
            FROM coach_assignments ca
            JOIN users c ON ca.coach_id = c.id
            WHERE ca.player_id = $1
            ORDER BY c.name ASC
        `;
        const result = await db.query(query, [playerId]);

        res.status(200).json({
            status: 'success',
            data: result.rows
        });
    } catch (error) {
        console.error('Error fetching assigned coaches:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch assigned coaches' });
    }
});


// Update current user profile
router.patch('/me', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const updates = req.body;

        // Whitelist allowed fields to update
        const allowedFields = [
            'name', 'batting_hand', 'age', 'onboarding_complete', 
            'fcm_token', 'profile_image_url', 'app_version', 'last_login_at'
        ];

        const setClauses = [];
        const values = [];
        let paramIndex = 1;

        for (const [key, value] of Object.entries(updates)) {
            if (allowedFields.includes(key)) {
                setClauses.push(`${key} = $${paramIndex}`);
                values.push(value);
                paramIndex++;
            }
        }

        if (setClauses.length === 0) {
            return res.status(400).json({ status: 'error', message: 'No valid fields provided for update' });
        }

        // Add the uid for the WHERE clause
        values.push(uid);
        
        const query = `
            UPDATE users 
            SET ${setClauses.join(', ')} 
            WHERE firebase_uid = $${paramIndex} 
            RETURNING *
        `;

        const result = await db.query(query, values);

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'User profile not found' });
        }

        res.status(200).json({
            status: 'success',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ status: 'error', message: 'Failed to update user profile' });
    }
});

module.exports = router;
