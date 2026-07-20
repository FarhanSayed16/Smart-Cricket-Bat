const cron = require('node-cron');
const db = require('../db');
const nodemailer = require('nodemailer');

function initCronJobs() {
    // Phase 19.2: Weekly Academy Summary (Runs every Sunday at 00:00)
    cron.schedule('0 0 * * 0', async () => {
        console.log('Running weekly academy summary job...');
        try {
            // Find all academies that have not opted out
            const academiesResult = await db.query('SELECT id, name FROM academies WHERE weekly_report_opt_out = false');
            
            for (const academy of academiesResult.rows) {
                // Find academy owner(s)/admins
                const adminsResult = await db.query(`
                    SELECT u.email 
                    FROM users u
                    JOIN academy_memberships am ON u.id = am.user_id AND am.status = 'active'
                    WHERE am.academy_id = $1 AND am.role IN ('admin', 'super')
                `, [academy.id]);

                if (adminsResult.rows.length === 0) continue;

                const emails = adminsResult.rows.map(r => r.email);

                // Fetch weekly stats
                const statsQuery = `
                    SELECT COUNT(DISTINCT s.player_id) as active_players, COUNT(s.id) as total_sessions,
                           AVG(s.sweet_spot_pct) as avg_sweet
                    FROM sessions s
                    WHERE s.academy_id = $1 AND s.start_time >= NOW() - INTERVAL '7 days'
                `;
                const statsResult = await db.query(statsQuery, [academy.id]);
                const stats = statsResult.rows[0];

                if (stats.total_sessions === '0') continue; // Skip if no activity

                // Fetch Top Performer (player with most hits this week)
                const topPerformerQuery = `
                    SELECT u.name, SUM(s.total_hits) as weekly_hits
                    FROM sessions s
                    JOIN users u ON s.player_id = u.id
                    WHERE s.academy_id = $1 AND s.start_time >= NOW() - INTERVAL '7 days'
                    GROUP BY u.name
                    ORDER BY weekly_hits DESC
                    LIMIT 1
                `;
                const topResult = await db.query(topPerformerQuery, [academy.id]);
                const topPerformer = topResult.rows.length > 0 ? topResult.rows[0].name : 'N/A';
                const topHits = topResult.rows.length > 0 ? topResult.rows[0].weekly_hits : 0;

                const coachTips = [
                    "Remind players to keep their head still upon impact.",
                    "Focus on transferring weight to the front foot.",
                    "Drill the bottom hand grip this week for more control.",
                    "Check the consistency of the backlift for power generation."
                ];
                const tip = coachTips[Math.floor(Math.random() * coachTips.length)];

                // Configure Nodemailer
                const transporter = nodemailer.createTransport({
                    host: process.env.SMTP_HOST || 'smtp.ethereal.email',
                    port: process.env.SMTP_PORT || 587,
                    auth: {
                        user: process.env.SMTP_USER || 'ethereal_user',
                        pass: process.env.SMTP_PASS || 'ethereal_pass'
                    }
                });

                const mailOptions = {
                    from: '"KnoQ System" <no-reply@knoq.in>',
                    to: emails.join(', '),
                    subject: `Weekly Summary - ${academy.name}`,
                    text: `Hello Admin, here is your weekly summary for ${academy.name}:\n\n` +
                          `Active Players: ${stats.active_players}\n` +
                          `Total Sessions: ${stats.total_sessions}\n` +
                          `Avg Sweet Spot: ${Math.round(stats.avg_sweet || 0)}%\n\n` +
                          `🌟 Top Performer: ${topPerformer} (${topHits} hits)\n\n` +
                          `💡 Coach Tip of the Week: ${tip}\n\n` +
                          `Keep up the great work!\n- The KnoQ Team`
                };

                await transporter.sendMail(mailOptions);
                console.log(`Sent weekly summary to ${academy.name}`);
            }
        } catch (error) {
            console.error('Error running weekly cron job:', error);
        }
    });

    console.log('Cron jobs initialized.');
}

module.exports = { initCronJobs };
