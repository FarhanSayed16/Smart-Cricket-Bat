const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

// Get players assigned to the coach's academy
router.get('/players', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const limit = parseInt(req.query.limit) || 20;
        const page = parseInt(req.query.page) || 1;
        const offset = (page - 1) * limit;

        // First, find the coach's academy and if they are the owner
        const coachQuery = `
            SELECT u.id, u.role, am.academy_id, a.owner_uid, u.firebase_uid
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            LEFT JOIN academies a ON am.academy_id = a.id
            WHERE u.firebase_uid = $1
            LIMIT 1
        `;
        const coachResult = await db.query(coachQuery, [uid]);

        if (coachResult.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Coach profile not found' });
        }

        const coach = coachResult.rows[0];
        if (coach.role !== 'coach') {
            return res.status(403).json({ status: 'error', message: 'Only coaches can access this endpoint' });
        }

        if (!coach.academy_id) {
            return res.status(200).json({ status: 'success', data: [] });
        }

        const isOwner = coach.owner_uid === coach.firebase_uid;

        let playersQuery;
        let queryParams;

        if (isOwner) {
            // Academy Owner sees ALL players in the academy
            playersQuery = `
                SELECT u.id, u.firebase_uid, u.name, u.email, u.role, am.academy_id, u.batting_hand, u.age, 
                       ca.coach_id as assigned_coach_id, u.onboarding_complete, u.created_at, u.profile_image_url
                FROM users u
                JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
                LEFT JOIN coach_assignments ca ON u.id = ca.player_id
                WHERE am.academy_id = $1 AND u.role = 'player'
                ORDER BY u.name ASC
                LIMIT $2 OFFSET $3
            `;
            queryParams = [coach.academy_id, limit, offset];
        } else {
            // Regular Coach sees ONLY players explicitly assigned to them
            playersQuery = `
                SELECT u.id, u.firebase_uid, u.name, u.email, u.role, am.academy_id, u.batting_hand, u.age, 
                       ca.coach_id as assigned_coach_id, u.onboarding_complete, u.created_at, u.profile_image_url
                FROM users u
                JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
                JOIN coach_assignments ca ON u.id = ca.player_id AND ca.coach_id = $2
                WHERE am.academy_id = $1 AND u.role = 'player'
                ORDER BY u.name ASC
                LIMIT $3 OFFSET $4
            `;
            queryParams = [coach.academy_id, coach.id, limit, offset];
        }

        const playersResult = await db.query(playersQuery, queryParams);

        res.status(200).json({
            status: 'success',
            data: playersResult.rows
        });
    } catch (error) {
        console.error('Error fetching players:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch players' });
    }
});

// Get a specific player's sessions
router.get('/players/:playerId/sessions', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { playerId } = req.params;

        // Verify coach role and get academy
        const coachQuery = `
            SELECT u.id, u.role, am.academy_id
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE u.firebase_uid = $1
            LIMIT 1
        `;
        const coachResult = await db.query(coachQuery, [uid]);
        const coach = coachResult.rows[0];

        if (!coach || coach.role !== 'coach') {
            return res.status(403).json({ status: 'error', message: 'Only coaches can access this endpoint' });
        }

        // Verify player belongs to same academy
        const playerQuery = `
            SELECT u.id, am.academy_id 
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE u.id = $1
            LIMIT 1
        `;
        const playerResult = await db.query(playerQuery, [playerId]);
        
        if (playerResult.rows.length === 0 || playerResult.rows[0].academy_id !== coach.academy_id) {
            return res.status(403).json({ status: 'error', message: 'Player not in your academy' });
        }

        const sessionsQuery = `
            SELECT * FROM sessions 
            WHERE player_id = $1 
            ORDER BY start_time DESC 
            LIMIT 50
        `;
        const sessionsResult = await db.query(sessionsQuery, [playerId]);

        res.status(200).json({
            status: 'success',
            data: sessionsResult.rows
        });
    } catch (error) {
        console.error('Error fetching player sessions:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch player sessions' });
    }
});

// Get a specific player's coach notes
router.get('/players/:playerId/notes', verifyToken, async (req, res) => {
    try {
        const { playerId } = req.params;
        
        const notesQuery = `
            SELECT cn.*, s.start_time as session_date
            FROM coach_notes cn
            JOIN sessions s ON cn.session_id = s.id
            WHERE cn.player_id = $1
            ORDER BY cn.created_at DESC
        `;
        const notesResult = await db.query(notesQuery, [playerId]);
        
        res.status(200).json({
            status: 'success',
            data: notesResult.rows
        });
    } catch (error) {
        console.error('Error fetching player notes:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch player notes' });
    }
});

// Post a coach note on a session
router.post('/notes', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { session_id, note, tags } = req.body;

        // Get coach's DB id
        const coachQuery = 'SELECT id FROM users WHERE firebase_uid = $1 AND role IN ($2, $3)';
        const coachResult = await db.query(coachQuery, [uid, 'coach', 'admin']);

        if (coachResult.rows.length === 0) {
            return res.status(403).json({ status: 'error', message: 'Only coaches or admins can post notes' });
        }

        const coachId = coachResult.rows[0].id;

        // Get the player_id from the session
        const sessionQuery = 'SELECT player_id FROM sessions WHERE id = $1';
        const sessionResult = await db.query(sessionQuery, [session_id]);

        if (sessionResult.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Session not found' });
        }

        const playerId = sessionResult.rows[0].player_id;

        const insertQuery = `
            INSERT INTO coach_notes (coach_id, player_id, session_id, note, tags)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
        `;
        const result = await db.query(insertQuery, [coachId, playerId, session_id, note, tags || []]);

        // Trigger FCM to player
        const { sendPushNotification } = require('../utils/fcm');
        await sendPushNotification(
            playerId, 
            'New Coach Note', 
            'Your coach has added a note to your session.', 
            { type: 'coach_note', session_id }
        );

        res.status(201).json({
            status: 'success',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error posting coach note:', error);
        res.status(500).json({ status: 'error', message: 'Failed to post coach note' });
    }
});

// Get all replies for a specific note
router.get('/notes/:id/replies', verifyToken, async (req, res) => {
    try {
        const noteId = req.params.id;
        const query = `
            SELECT r.*, u.name as sender_name, u.role as sender_role, u.profile_image_url as sender_avatar
            FROM coach_note_replies r
            JOIN users u ON r.sender_id = u.id
            WHERE r.note_id = $1
            ORDER BY r.created_at ASC
        `;
        const result = await db.query(query, [noteId]);
        res.status(200).json({ status: 'success', data: result.rows });
    } catch (error) {
        console.error('Error fetching replies:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch replies' });
    }
});

// Reply to a note
router.post('/notes/:id/reply', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const noteId = req.params.id;
        const { reply_text } = req.body;

        const userQuery = 'SELECT id FROM users WHERE firebase_uid = $1';
        const userResult = await db.query(userQuery, [uid]);
        if (userResult.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'User not found' });
        }
        const senderId = userResult.rows[0].id;

        const insertQuery = `
            INSERT INTO coach_note_replies (note_id, sender_id, reply_text)
            VALUES ($1, $2, $3)
            RETURNING *
        `;
        const result = await db.query(insertQuery, [noteId, senderId, reply_text]);

        res.status(201).json({ status: 'success', data: result.rows[0] });
    } catch (error) {
        console.error('Error posting reply:', error);
        res.status(500).json({ status: 'error', message: 'Failed to post reply' });
    }
});

// Assign a coach to a player
router.post('/assign', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { playerId, academyId } = req.body;

        if (!playerId || !academyId) {
            return res.status(400).json({ status: 'error', message: 'playerId and academyId are required' });
        }

        // Verify caller is the Academy Owner
        const ownerQuery = `
            SELECT id FROM academies 
            WHERE id = $1 AND owner_uid = $2
        `;
        const ownerResult = await db.query(ownerQuery, [academyId, uid]);

        if (ownerResult.rows.length === 0) {
            return res.status(403).json({ status: 'error', message: 'Only the Academy Owner can assign players' });
        }

        // Get the target coach ID (either from body or self-assign)
        let targetCoachId = req.body.coachId;
        if (!targetCoachId) {
            const selfQuery = 'SELECT id FROM users WHERE firebase_uid = $1';
            const selfResult = await db.query(selfQuery, [uid]);
            targetCoachId = selfResult.rows[0].id;
        }

        const insertQuery = `
            INSERT INTO coach_assignments (coach_id, player_id, academy_id)
            VALUES ($1, $2, $3)
            ON CONFLICT (coach_id, player_id, academy_id) DO NOTHING
            RETURNING *
        `;
        const result = await db.query(insertQuery, [targetCoachId, playerId, academyId]);

        res.status(201).json({
            status: 'success',
            message: 'Coach assigned successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error assigning coach:', error);
        res.status(500).json({ status: 'error', message: 'Failed to assign coach' });
    }
});

module.exports = router;
