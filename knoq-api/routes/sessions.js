const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');
const { queueSessionVideoExtraction } = require('../jobs/clipExtractor');

// Get paginated sessions for current user
router.get('/', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const limit = parseInt(req.query.limit) || 20;
        const page = parseInt(req.query.page) || 1;
        const offset = (page - 1) * limit;

        const query = `
            SELECT s.* FROM sessions s
            JOIN users u ON s.player_id = u.id
            WHERE u.firebase_uid = $1
            ORDER BY s.start_time DESC
            LIMIT $2 OFFSET $3
        `;
        
        const result = await db.query(query, [uid, limit, offset]);

        res.status(200).json({
            status: 'success',
            data: result.rows
        });
    } catch (error) {
        console.error('Error fetching sessions:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch sessions' });
    }
});

// Upload a new session
router.post('/', verifyToken, async (req, res) => {
    const client = await db.pool.connect();
    try {
        const { uid } = req.user;
        const { 
            device_id, start_time, end_time, total_hits, sweet_spot_pct, 
            avg_power, peak_power, avg_swing, peak_swing, zone_distribution, 
            consistency_score, insights, app_version, firmware_version, shots, video_url
        } = req.body;

        await client.query('BEGIN');

        // Get player id and academy
        const userQuery = `
            SELECT u.id, am.academy_id 
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE u.firebase_uid = $1 LIMIT 1
        `;
        const userResult = await client.query(userQuery, [uid]);
        if (userResult.rows.length === 0) throw new Error('User not found');
        const { id: playerId, academy_id: academyId } = userResult.rows[0];

        // Insert session
        const sessionQuery = `
            INSERT INTO sessions (
                player_id, academy_id, device_id, start_time, end_time, status,
                total_hits, sweet_spot_pct, avg_power, peak_power, avg_swing, peak_swing,
                zone_distribution, consistency_score, insights, app_version, firmware_version, video_url
            ) VALUES ($1, $2, $3, $4, $5, 'completed', $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
            RETURNING id
        `;
        const sessionValues = [
            playerId, academyId, device_id, start_time, end_time,
            total_hits, sweet_spot_pct, avg_power, peak_power, avg_swing, peak_swing,
            zone_distribution, consistency_score, insights, app_version, firmware_version, video_url
        ];
        const sessionResult = await client.query(sessionQuery, sessionValues);
        const sessionId = sessionResult.rows[0].id;

        // Insert shots
        if (shots && shots.length > 0) {
            for (let i = 0; i < shots.length; i++) {
                const shot = shots[i];
                await client.query(`
                    INSERT INTO shots (session_id, shot_number, zone, power, swing, timestamp, video_offset_ms)
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                `, [sessionId, i + 1, shot.zone, shot.power, shot.swing, shot.timestamp, shot.video_offset_ms]);
            }
        }

        // --- Phase 19.3: Evaluate active drills ---
        const activeDrillsQuery = `
            SELECT id, title, target_zone, min_power, target_shot_count
            FROM drills
            WHERE player_id = $1 AND status = 'assigned'
        `;
        const activeDrills = await client.query(activeDrillsQuery, [playerId]);

        const completedDrills = [];
        for (const drill of activeDrills.rows) {
            let validShotsCount = 0;
            if (shots && shots.length > 0) {
                validShotsCount = shots.filter(shot => {
                    const zoneMatch = !drill.target_zone || shot.zone === drill.target_zone;
                    const powerMatch = !drill.min_power || shot.power >= drill.min_power;
                    return zoneMatch && powerMatch;
                }).length;
            }

            if (validShotsCount >= drill.target_shot_count) {
                // Drill completed!
                await client.query(`UPDATE drills SET status = 'completed', completed_at = CURRENT_TIMESTAMP WHERE id = $1`, [drill.id]);
                completedDrills.push(drill.id);
            }
        }

        await client.query('COMMIT');

        // FCM Notification for completed drills to coach
        if (completedDrills.length > 0) {
            const { sendPushNotification } = require('../utils/fcm');
            const drillNames = activeDrills.rows.filter(d => completedDrills.includes(d.id)).map(d => d.title).join(', ');
            
            // Get coach id for the player
            const coachQuery = `SELECT coach_id FROM coach_assignments WHERE player_id = $1 LIMIT 1`;
            const coachResult = await db.query(coachQuery, [playerId]);
            if (coachResult.rows.length > 0) {
                const coachId = coachResult.rows[0].coach_id;
                await sendPushNotification(
                    coachId,
                    'Drill Completed!',
                    `Player has completed the drill: ${drillNames}`,
                    { type: 'drill_completed', player_id: playerId, session_id: sessionId }
                );
            }
        }

        // Trigger clip extraction if video exists
        if (video_url) {
            queueSessionVideoExtraction(sessionId, video_url, academyId);
        }

        res.status(201).json({ 
            status: 'success', 
            data: { session_id: sessionId, completed_drills: completedDrills }
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error uploading session:', error);
        res.status(500).json({ status: 'error', message: 'Failed to upload session' });
    } finally {
        client.release();
    }
});

// Get notes for a specific session
router.get('/:id/notes', verifyToken, async (req, res) => {
    try {
        const sessionId = req.params.id;
        const query = `
            SELECT cn.*, c.name as coach_name, c.profile_image_url as coach_avatar
            FROM coach_notes cn
            LEFT JOIN users c ON cn.coach_id = c.id
            WHERE cn.session_id = $1
            ORDER BY cn.created_at DESC
        `;
        const result = await db.query(query, [sessionId]);
        res.status(200).json({ status: 'success', data: result.rows });
    } catch (error) {
        console.error('Error fetching session notes:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch session notes' });
    }
});

// Get shots with clip URLs for a session (for verification UI)
router.get('/:id/clips', verifyToken, async (req, res) => {
    try {
        const sessionId = req.params.id;
        const query = `
            SELECT s.id, s.shot_number, s.zone, s.power, s.swing, s.video_offset_ms, s.clip_url,
                   sa.quality_rating, sa.delivery_type, sa.shot_type
            FROM shots s
            LEFT JOIN shot_analysis sa ON sa.session_id = s.session_id AND sa.shot_number = s.shot_number
            WHERE s.session_id = $1
            ORDER BY s.shot_number ASC
        `;
        const result = await db.query(query, [sessionId]);
        res.status(200).json({ status: 'success', data: result.rows });
    } catch (error) {
        console.error('Error fetching session clips:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch clips' });
    }
});

// Update a shot's video_offset_ms (manual alignment adjustment)
router.put('/:sessionId/shots/:shotNumber/offset', verifyToken, async (req, res) => {
    try {
        const { sessionId, shotNumber } = req.params;
        const { video_offset_ms } = req.body;

        if (video_offset_ms == null || typeof video_offset_ms !== 'number') {
            return res.status(400).json({ status: 'error', message: 'video_offset_ms must be a number' });
        }

        await db.query(
            'UPDATE shots SET video_offset_ms = $1 WHERE session_id = $2 AND shot_number = $3',
            [video_offset_ms, sessionId, parseInt(shotNumber)]
        );

        res.status(200).json({ status: 'success', message: 'Offset updated' });
    } catch (error) {
        console.error('Error updating shot offset:', error);
        res.status(500).json({ status: 'error', message: 'Failed to update offset' });
    }
});

// Get a specific session by ID with its shots
router.get('/:id', verifyToken, async (req, res) => {
    try {
        const sessionId = req.params.id;
        
        const sessionQuery = `SELECT * FROM sessions WHERE id = $1`;
        const sessionResult = await db.query(sessionQuery, [sessionId]);
        
        if (sessionResult.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Session not found' });
        }

        const shotsQuery = `SELECT * FROM shots WHERE session_id = $1 ORDER BY shot_number ASC`;
        const shotsResult = await db.query(shotsQuery, [sessionId]);

        res.status(200).json({ 
            status: 'success', 
            data: {
                session: sessionResult.rows[0],
                shots: shotsResult.rows
            }
        });
    } catch (error) {
        console.error('Error fetching session by ID:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch session' });
    }
});

// Delete a session by ID
router.delete('/:id', verifyToken, async (req, res) => {
    try {
        const sessionId = req.params.id;
        
        const result = await db.query('DELETE FROM sessions WHERE id = $1 AND player_id = (SELECT id FROM users WHERE firebase_uid = $2)', [sessionId, req.user.uid]);
        
        if (result.rowCount === 0) {
            return res.status(404).json({ status: 'error', message: 'Session not found or unauthorized' });
        }

        res.status(200).json({ status: 'success', message: 'Session deleted successfully' });
    } catch (error) {
        console.error('Error deleting session:', error);
        res.status(500).json({ status: 'error', message: 'Failed to delete session' });
    }
});

module.exports = router;
