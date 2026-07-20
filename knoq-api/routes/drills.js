const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

// Apply token verification to all routes
router.use(verifyToken);

// Create a new drill assignment
router.post('/', async (req, res) => {
    try {
        const { uid } = req.user;
        const { player_id, title, description, target_zone, min_power, target_shot_count, deadline } = req.body;

        // Verify coach/admin role
        const coachQuery = `
            SELECT u.id, am.academy_id 
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE u.firebase_uid = $1 AND u.role IN ('coach', 'admin', 'super')
            LIMIT 1
        `;
        const coachResult = await db.query(coachQuery, [uid]);

        if (coachResult.rows.length === 0) {
            return res.status(403).json({ status: 'error', message: 'Unauthorized to create drills' });
        }

        const coach = coachResult.rows[0];

        const insertQuery = `
            INSERT INTO drills (
                academy_id, coach_id, player_id, title, description, 
                target_zone, min_power, target_shot_count, deadline
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
        `;
        
        const values = [
            coach.academy_id,
            coach.id,
            player_id,
            title,
            description,
            target_zone || null,
            min_power || null,
            target_shot_count,
            deadline || null
        ];

        const result = await db.query(insertQuery, values);

        // Trigger FCM notification to player
        const { sendPushNotification } = require('../utils/fcm');
        await sendPushNotification(
            player_id, 
            'New Drill Assigned', 
            `Your coach has assigned a new drill: ${title}`, 
            { type: 'drill_assigned', drill_id: result.rows[0].id }
        );

        res.status(201).json({ status: 'success', data: result.rows[0] });
    } catch (error) {
        console.error('Error creating drill:', error);
        res.status(500).json({ status: 'error', message: 'Failed to create drill' });
    }
});

// Get drills for a specific player
router.get('/player/:id', async (req, res) => {
    try {
        const playerId = req.params.id;
        // Optionally verify that the requester is the player themselves, or their coach/admin.
        
        const query = `
            SELECT d.*, c.name as coach_name, c.profile_image_url as coach_avatar
            FROM drills d
            LEFT JOIN users c ON d.coach_id = c.id
            WHERE d.player_id = $1
            ORDER BY d.created_at DESC
        `;
        const result = await db.query(query, [playerId]);
        
        res.status(200).json({ status: 'success', data: result.rows });
    } catch (error) {
        console.error('Error fetching drills:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch drills' });
    }
});

// Mark drill as completed (typically done automatically by backend session eval, but useful for manual override)
router.patch('/:id/complete', async (req, res) => {
    try {
        const drillId = req.params.id;
        
        const updateQuery = `
            UPDATE drills
            SET status = 'completed', completed_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING *
        `;
        const result = await db.query(updateQuery, [drillId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Drill not found' });
        }

        res.status(200).json({ status: 'success', data: result.rows[0] });
    } catch (error) {
        console.error('Error completing drill:', error);
        res.status(500).json({ status: 'error', message: 'Failed to complete drill' });
    }
});

module.exports = router;
