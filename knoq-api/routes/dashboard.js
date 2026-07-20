const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');
// Middleware to ensure user is an academy owner or super admin and has an academy context
async function requireAcademyAdmin(req, res, next) {
    try {
        const { uid } = req.user;
        const query = `
            SELECT u.id, u.role, am.academy_id 
            FROM users u
            LEFT JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE u.firebase_uid = $1
            LIMIT 1
        `;
        const result = await db.query(query, [uid]);
        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'User not found' });
        }
        const user = result.rows[0];
        
        if (user.role !== 'admin' && user.role !== 'super') {
            return res.status(403).json({ status: 'error', message: 'Access denied. Must be academy admin or super admin.' });
        }

        if (!user.academy_id) {
            return res.status(400).json({ status: 'error', message: 'User is not associated with any academy.' });
        }

        req.academyId = user.academy_id;
        next();
    } catch (error) {
        console.error('Auth error:', error);
        res.status(500).json({ status: 'error', message: 'Internal server error' });
    }
}

// Apply token verification to all routes
router.use(verifyToken);
router.use(requireAcademyAdmin);

// 1. GET /dashboard/overview
router.get('/overview', async (req, res) => {
    try {
        const academyId = req.academyId;

        // Get basic stats
        const playersCount = await db.query(`
            SELECT COUNT(*) FROM users u 
            JOIN academy_memberships am ON u.id = am.user_id 
            WHERE am.academy_id = $1 AND u.role = 'player' AND am.status = 'active'
        `, [academyId]);

        const coachesCount = await db.query(`
            SELECT COUNT(*) FROM users u 
            JOIN academy_memberships am ON u.id = am.user_id 
            WHERE am.academy_id = $1 AND u.role = 'coach' AND am.status = 'active'
        `, [academyId]);

        const devicesCount = await db.query(`
            SELECT COUNT(*) FROM devices WHERE academy_id = $1 AND status != 'error'
        `, [academyId]);

        // Mock chart data and complex stats for now (to replace mock data on frontend with backend-controlled data)
        const stats = {
            totalPlayers: parseInt(playersCount.rows[0].count),
            totalCoaches: parseInt(coachesCount.rows[0].count),
            activeDevices: parseInt(devicesCount.rows[0].count),
            totalSessionsThisMonth: 124,
            totalHitsThisMonth: 8540,
            avgSweetSpotPct: 68
        };

        const chartData = [
            { day: 'Mon', sessions: 12, hits: 850 },
            { day: 'Tue', sessions: 15, hits: 1120 },
            { day: 'Wed', sessions: 8, hits: 600 },
            { day: 'Thu', sessions: 22, hits: 1800 },
            { day: 'Fri', sessions: 18, hits: 1450 },
            { day: 'Sat', sessions: 35, hits: 2800 },
            { day: 'Sun', sessions: 28, hits: 2100 },
        ];

        res.status(200).json({ status: 'success', data: { stats, chartData } });
    } catch (error) {
        console.error('Overview error:', error);
        res.status(500).json({ status: 'error', message: 'Failed to load overview' });
    }
});

// 2. GET /dashboard/players
router.get('/players', async (req, res) => {
    try {
        const academyId = req.academyId;
        const query = `
            SELECT u.id, u.name, u.email, u.batting_hand, u.profile_image_url as avatar_url,
                   ca.coach_id,
                   (SELECT start_time FROM sessions s WHERE s.player_id = u.id ORDER BY start_time DESC LIMIT 1) as last_session_date
            FROM users u
            JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            LEFT JOIN coach_assignments ca ON u.id = ca.player_id AND ca.academy_id = am.academy_id
            WHERE am.academy_id = $1 AND u.role = 'player'
            ORDER BY u.name ASC
        `;
        const result = await db.query(query, [academyId]);
        
        // Map to frontend expected shape
        const players = result.rows.map(p => ({
            id: p.id,
            name: p.name,
            email: p.email,
            status: p.last_session_date ? 'active' : 'inactive',
            assigned_coach_id: p.coach_id,
            last_session_date: p.last_session_date,
            avatar_url: p.avatar_url,
            // Mock stats for the table
            sessions_count: Math.floor(Math.random() * 50),
            avg_sweet_spot: Math.floor(Math.random() * 40) + 40,
        }));

        res.status(200).json({ status: 'success', data: players });
    } catch (error) {
        console.error('Players error:', error);
        res.status(500).json({ status: 'error', message: 'Failed to load players' });
    }
});

// 3. GET /dashboard/coaches
router.get('/coaches', async (req, res) => {
    try {
        const academyId = req.academyId;
        const query = `
            SELECT u.id, u.name, u.email, u.profile_image_url as avatar_url, am.joined_at,
                   (SELECT COUNT(*) FROM coach_assignments ca WHERE ca.coach_id = u.id) as assigned_players
            FROM users u
            JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
            WHERE am.academy_id = $1 AND u.role = 'coach'
            ORDER BY u.name ASC
        `;
        const result = await db.query(query, [academyId]);
        
        const coaches = result.rows.map(c => ({
            id: c.id,
            name: c.name,
            email: c.email,
            status: 'active',
            assigned_players: parseInt(c.assigned_players),
            avatar_url: c.avatar_url,
            last_active: c.joined_at // Using joined_at as fallback
        }));

        res.status(200).json({ status: 'success', data: coaches });
    } catch (error) {
        console.error('Coaches error:', error);
        res.status(500).json({ status: 'error', message: 'Failed to load coaches' });
    }
});

// 4. GET /dashboard/devices
router.get('/devices', async (req, res) => {
    try {
        const academyId = req.academyId;
        const query = `
            SELECT d.id, d.name, d.mac_address, d.firmware_version, d.battery_level, d.status, d.last_seen,
                   u.name as assigned_to_name, u.id as assigned_to_id
            FROM devices d
            LEFT JOIN users u ON d.assigned_to = u.id
            WHERE d.academy_id = $1
            ORDER BY d.name ASC
        `;
        const result = await db.query(query, [academyId]);
        
        res.status(200).json({ status: 'success', data: result.rows });
    } catch (error) {
        console.error('Devices error:', error);
        res.status(500).json({ status: 'error', message: 'Failed to load devices' });
    }
});

module.exports = router;
