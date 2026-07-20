const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

// Get generic analytics for current user
router.get('/', verifyToken, async (req, res) => {
    try {
        // Return empty mock data for now
        res.status(200).json({
            status: 'success',
            data: {
                totalSessions: 0,
                totalHits: 0,
                avgSweetSpotPct: 0,
                recentProgress: []
            }
        });
    } catch (error) {
        console.error('Error fetching analytics:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch analytics' });
    }
});
// Get analytics for a specific player (used by coaches)
router.get('/player/:playerId', verifyToken, async (req, res) => {
    try {
        const { playerId } = req.params;
        // In a real implementation, verify the coach has access to this player
        // For now, return empty mock data to prevent 404s
        res.status(200).json({
            status: 'success',
            data: {
                totalSessions: 0,
                totalHits: 0,
                overallSweetPct: 0,
                overallAvgPower: 0,
                overallPeakPower: 0,
                overallAvgSwing: null,
                zoneTotals: { 'Sweet': 0, 'Top': 0, 'Bottom': 0, 'Left': 0, 'Right': 0 },
                powerTrend: {},
                swingTrend: {},
                sweetTrend: {},
                consistencyTrend: {},
                strongestZone: null,
                weakestZone: null
            }
        });
    } catch (error) {
        console.error('Error fetching player analytics:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch player analytics' });
    }
});

// Get advanced analytics (Phase 19.4)
router.get('/player/:playerId/advanced', verifyToken, async (req, res) => {
    try {
        const { playerId } = req.params;
        
        // 1. Fatigue Curve (Average Power by Shot Number over the last 10 sessions)
        const fatigueQuery = `
            SELECT shot_number, AVG(power) as avg_power
            FROM shots s
            JOIN sessions sess ON s.session_id = sess.id
            WHERE sess.player_id = $1
            GROUP BY shot_number
            ORDER BY shot_number ASC
            LIMIT 100
        `;
        const fatigueResult = await db.query(fatigueQuery, [playerId]);
        const fatigueCurve = fatigueResult.rows.map(r => ({
            shot_number: r.shot_number,
            avg_power: Math.round(r.avg_power)
        }));

        // 2. Consistency & Improvements (Week over Week)
        const weeklyQuery = `
            SELECT 
                DATE_TRUNC('week', start_time) as week,
                AVG(sweet_spot_pct) as avg_sweet,
                AVG(avg_power) as avg_power,
                STDDEV(consistency_score) as consistency_variance
            FROM sessions
            WHERE player_id = $1
            GROUP BY week
            ORDER BY week DESC
            LIMIT 4
        `;
        const weeklyResult = await db.query(weeklyQuery, [playerId]);
        const weeklyStats = weeklyResult.rows;

        let improvement = null;
        if (weeklyStats.length >= 2) {
            const thisWeek = weeklyStats[0];
            const lastWeek = weeklyStats[1];
            improvement = {
                sweet_spot_change: Math.round(thisWeek.avg_sweet - lastWeek.avg_sweet),
                power_change: Math.round(thisWeek.avg_power - lastWeek.avg_power)
            };
        }

        // 3. Bat Heatmap (Zone frequency)
        const heatmapQuery = `
            SELECT zone, COUNT(*) as hit_count
            FROM shots s
            JOIN sessions sess ON s.session_id = sess.id
            WHERE sess.player_id = $1
            GROUP BY zone
        `;
        const heatmapResult = await db.query(heatmapQuery, [playerId]);
        const heatmap = heatmapResult.rows;

        // 4. Personal Bests
        const pbQuery = `
            SELECT MAX(peak_power) as max_power, MAX(sweet_spot_pct) as max_sweet, MAX(total_hits) as max_hits
            FROM sessions
            WHERE player_id = $1
        `;
        const pbResult = await db.query(pbQuery, [playerId]);

        // 5. Optimal session length (find when power drops below 90% of their avg)
        let optimalLength = null;
        if (fatigueCurve.length > 10) {
            const overallAvg = fatigueCurve.reduce((sum, p) => sum + p.avg_power, 0) / fatigueCurve.length;
            const threshold = overallAvg * 0.9;
            const dropPoint = fatigueCurve.find(p => p.avg_power < threshold);
            if (dropPoint) {
                optimalLength = dropPoint.shot_number;
            }
        }

        // 6. Check if latest session set any new PBs
        const latestSessionQuery = `
            SELECT peak_power, sweet_spot_pct, total_hits
            FROM sessions
            WHERE player_id = $1
            ORDER BY start_time DESC
            LIMIT 1
        `;
        const latestResult = await db.query(latestSessionQuery, [playerId]);
        let newPBs = [];
        if (latestResult.rows.length > 0 && pbResult.rows.length > 0) {
            const latest = latestResult.rows[0];
            const pb = pbResult.rows[0];
            if (latest.peak_power >= pb.max_power && pb.max_power > 0) newPBs.push('peak_power');
            if (latest.sweet_spot_pct >= pb.max_sweet && pb.max_sweet > 0) newPBs.push('sweet_spot');
            if (latest.total_hits >= pb.max_hits && pb.max_hits > 0) newPBs.push('total_hits');
        }

        res.status(200).json({
            status: 'success',
            data: {
                fatigueCurve,
                weeklyStats,
                improvement,
                heatmap,
                personalBests: pbResult.rows[0],
                optimalSessionLength: optimalLength,
                newPersonalBests: newPBs
            }
        });
    } catch (error) {
        console.error('Error fetching advanced analytics:', error);
        res.status(500).json({ status: 'error', message: 'Failed to fetch advanced analytics' });
    }
});

module.exports = router;
