const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

// Join academy using code
router.post('/join', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { join_code } = req.body;

        if (!join_code) {
            return res.status(400).json({ status: 'error', message: 'Join code is required' });
        }

        // Find academy by join_code
        const academyQuery = 'SELECT id, name FROM academies WHERE join_code = $1';
        const academyResult = await db.query(academyQuery, [join_code.toUpperCase()]);

        if (academyResult.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Invalid academy join code' });
        }

        const academyId = academyResult.rows[0].id;
        const academyName = academyResult.rows[0].name;

        // Get user details
        const userQuery = 'SELECT id, role FROM users WHERE firebase_uid = $1';
        const userResult = await db.query(userQuery, [uid]);

        if (userResult.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'User profile not found' });
        }

        const user = userResult.rows[0];

        // Insert into academy_memberships
        const membershipQuery = `
            INSERT INTO academy_memberships (user_id, academy_id, role)
            VALUES ($1, $2, $3)
            ON CONFLICT (user_id, academy_id) DO UPDATE SET status = 'active'
            RETURNING *
        `;
        await db.query(membershipQuery, [user.id, academyId, user.role]);

        // Fetch updated user to return (with the academy_id via JOIN like in /me)
        const updatedUserQuery = `
            SELECT u.*, 
                   am.academy_id
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE u.firebase_uid = $1
            LIMIT 1
        `;
        const updatedUserResult = await db.query(updatedUserQuery, [uid]);

        res.status(200).json({
            status: 'success',
            message: `Successfully joined ${academyName}`,
            data: updatedUserResult.rows[0]
        });
    } catch (error) {
        console.error('Error joining academy:', error);
        res.status(500).json({ status: 'error', message: 'Failed to join academy' });
    }
});

// Leave academy
router.post('/leave', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { academy_id } = req.body;

        // Get user id
        const userQuery = 'SELECT id FROM users WHERE firebase_uid = $1';
        const userResult = await db.query(userQuery, [uid]);
        const userId = userResult.rows[0].id;

        let query, params;
        if (academy_id) {
            query = `UPDATE academy_memberships SET status = 'left' WHERE user_id = $1 AND academy_id = $2`;
            params = [userId, academy_id];
        } else {
            // If no academy_id provided, leave all active academies
            query = `UPDATE academy_memberships SET status = 'left' WHERE user_id = $1`;
            params = [userId];
        }
        await db.query(query, params);

        // Fetch updated user
        const updatedUserQuery = `
            SELECT u.*, 
                   am.academy_id
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE u.firebase_uid = $1
            LIMIT 1
        `;
        const updatedUserResult = await db.query(updatedUserQuery, [uid]);

        res.status(200).json({
            status: 'success',
            message: 'Successfully left academy',
            data: updatedUserResult.rows[0]
        });
    } catch (error) {
        console.error('Error leaving academy:', error);
        res.status(500).json({ status: 'error', message: 'Failed to leave academy' });
    }
});

// Create a new academy
router.post('/', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { name, city, state } = req.body;

        if (!name) {
            return res.status(400).json({ status: 'error', message: 'Academy name is required' });
        }

        // Generate a random 6-character join code
        const joinCode = Math.random().toString(36).substring(2, 8).toUpperCase();

        const insertQuery = `
            INSERT INTO academies (name, owner_uid, city, state, join_code)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
        `;
        const result = await db.query(insertQuery, [name, uid, city, state, joinCode]);

        res.status(201).json({
            status: 'success',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating academy:', error);
        res.status(500).json({ status: 'error', message: 'Failed to create academy' });
    }
});

// Get members of an academy
router.get('/:academyId/members', verifyToken, async (req, res) => {
    try {
        const { academyId } = req.params;
        const limit = parseInt(req.query.limit) || 20;
        const page = parseInt(req.query.page) || 1;
        const offset = (page - 1) * limit;

        const query = `
            SELECT u.id, u.name, u.email, am.role, am.status, am.joined_at
            FROM users u
            JOIN academy_memberships am ON u.id = am.user_id
            WHERE am.academy_id = $1 AND am.status = 'active'
            ORDER BY am.role ASC, u.name ASC
            LIMIT $2 OFFSET $3
        `;
        const result = await db.query(query, [academyId, limit, offset]);

        res.status(200).json({
            status: 'success',
            data: result.rows
        });
    } catch (error) {
        console.error('Error fetching members:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch members' });
    }
});

// Create a pending invite for an academy
router.post('/:academyId/invite', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { academyId } = req.params;
        const { email, role } = req.body;

        if (!email || !role) {
            return res.status(400).json({ status: 'error', message: 'Email and role are required' });
        }

        // Verify caller is the Academy Owner
        const ownerQuery = `
            SELECT owner_uid FROM academies 
            WHERE id = $1 AND owner_uid = $2
        `;
        const ownerResult = await db.query(ownerQuery, [academyId, uid]);

        if (ownerResult.rows.length === 0) {
            return res.status(403).json({ status: 'error', message: 'Only the Academy Owner can send invites' });
        }

        const inviterQuery = 'SELECT id FROM users WHERE firebase_uid = $1';
        const inviterResult = await db.query(inviterQuery, [uid]);
        const inviterId = inviterResult.rows[0]?.id;

        // Check if the invited email already belongs to a registered user
        const existingUserQuery = 'SELECT id, email, role FROM users WHERE email = $1 LIMIT 1';
        const existingUserResult = await db.query(existingUserQuery, [email]);

        if (existingUserResult.rows.length > 0) {
            const existingUser = existingUserResult.rows[0];

            // 1. Update their role
            await db.query('UPDATE users SET role = $1 WHERE id = $2', [role, existingUser.id]);

            // 2. Remove them from any other academy (set status to 'left')
            await db.query(
                `UPDATE academy_memberships SET status = 'left' 
                 WHERE user_id = $1 AND academy_id != $2 AND status = 'active'`,
                [existingUser.id, academyId]
            );

            // 3. Upsert them into this academy
            const membershipQuery = `
                INSERT INTO academy_memberships (user_id, academy_id, role, status)
                VALUES ($1, $2, $3, 'active')
                ON CONFLICT (user_id, academy_id) DO UPDATE SET 
                    status = 'active',
                    role = EXCLUDED.role
            `;
            await db.query(membershipQuery, [existingUser.id, academyId, role]);

            return res.status(200).json({
                status: 'success',
                message: `${email} was already registered. They have been instantly added to your academy as a ${role}.`,
                data: { id: existingUser.id, email: existingUser.email, role: role }
            });
        }

        // If user does not exist, create a pending invite
        const insertQuery = `
            INSERT INTO pending_invites (email, academy_id, role, invited_by)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (email, academy_id) DO UPDATE SET 
                role = EXCLUDED.role,
                status = 'pending',
                created_at = CURRENT_TIMESTAMP
            RETURNING *
        `;
        const result = await db.query(insertQuery, [email, academyId, role, inviterId]);

        res.status(201).json({
            status: 'success',
            message: `Invite sent to ${email}`,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating invite:', error);
        res.status(500).json({ status: 'error', message: 'Failed to create invite' });
    }
});

// Remove a member from an academy
router.delete('/:academyId/members/:userId', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { academyId, userId } = req.params;
        
        // Verify caller is the Academy Owner
        const ownerQuery = `
            SELECT owner_uid FROM academies 
            WHERE id = $1 AND owner_uid = $2
        `;
        const ownerResult = await db.query(ownerQuery, [academyId, uid]);

        if (ownerResult.rows.length === 0) {
            return res.status(403).json({ status: 'error', message: 'Only the Academy Owner can remove members' });
        }
        const query = `
            UPDATE academy_memberships 
            SET status = 'removed' 
            WHERE user_id = $1 AND academy_id = $2
        `;
        await db.query(query, [userId, academyId]);

        res.status(200).json({
            status: 'success',
            message: 'Member removed successfully'
        });
    } catch (error) {
        console.error('Error removing member:', error);
        res.status(500).json({ status: 'error', message: 'Failed to remove member' });
    }
});

// Get academy video settings
router.get('/:academyId/video-settings', verifyToken, async (req, res) => {
    try {
        const { academyId } = req.params;
        const result = await db.query('SELECT video_settings FROM academies WHERE id = $1', [academyId]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Academy not found' });
        }

        // Return defaults if not configured yet
        const settings = result.rows[0].video_settings || {
            resolution: '720p',
            fps: 30,
            clip_padding_ms: 4000,
            resolutions_available: [
                { label: '720p (Recommended)', value: '720p', fps: 30 },
                { label: '1080p (High Quality)', value: '1080p', fps: 24 },
            ]
        };

        res.status(200).json({ status: 'success', data: settings });
    } catch (error) {
        console.error('Error fetching video settings:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch video settings' });
    }
});

// Update academy video settings (coach/owner only)
router.put('/:academyId/video-settings', verifyToken, async (req, res) => {
    try {
        const { uid } = req.user;
        const { academyId } = req.params;
        const { resolution, fps, clip_padding_ms } = req.body;

        // Verify user is coach/owner of this academy
        const memberQuery = `
            SELECT am.role FROM academy_memberships am
            JOIN users u ON am.user_id = u.id
            WHERE u.firebase_uid = $1 AND am.academy_id = $2 AND am.role IN ('coach', 'owner')
        `;
        const memberResult = await db.query(memberQuery, [uid, academyId]);
        if (memberResult.rows.length === 0) {
            return res.status(403).json({ status: 'error', message: 'Only coaches or owners can update video settings' });
        }

        // Validate values
        const validResolutions = ['720p', '1080p'];
        if (resolution && !validResolutions.includes(resolution)) {
            return res.status(400).json({ status: 'error', message: 'Invalid resolution. Use 720p or 1080p' });
        }
        if (clip_padding_ms && (clip_padding_ms < 2000 || clip_padding_ms > 12000)) {
            return res.status(400).json({ status: 'error', message: 'Clip padding must be between 2000ms and 12000ms' });
        }
        if (fps && (fps < 15 || fps > 60)) {
            return res.status(400).json({ status: 'error', message: 'FPS must be between 15 and 60' });
        }

        // Build updated settings
        const currentRes = await db.query('SELECT video_settings FROM academies WHERE id = $1', [academyId]);
        const current = currentRes.rows[0]?.video_settings || {};
        const updated = {
            ...current,
            ...(resolution && { resolution }),
            ...(fps && { fps }),
            ...(clip_padding_ms && { clip_padding_ms }),
        };

        await db.query('UPDATE academies SET video_settings = $1 WHERE id = $2', [JSON.stringify(updated), academyId]);

        res.status(200).json({ status: 'success', data: updated });
    } catch (error) {
        console.error('Error updating video settings:', error);
        res.status(500).json({ status: 'error', message: 'Failed to update video settings' });
    }
});

module.exports = router;
