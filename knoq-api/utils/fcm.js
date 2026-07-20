const admin = require('firebase-admin');
const db = require('../db');

/**
 * Send a push notification to a specific user using their fcm_token
 */
async function sendPushNotification(userId, title, body, data = {}) {
    try {
        const query = 'SELECT fcm_token FROM users WHERE id = $1';
        const result = await db.query(query, [userId]);

        if (result.rows.length === 0 || !result.rows[0].fcm_token) {
            console.log(`No FCM token found for user ${userId}`);
            return false;
        }

        const token = result.rows[0].fcm_token;

        const message = {
            notification: {
                title,
                body
            },
            data,
            token
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message to user ${userId}:`, response);
        return true;
    } catch (error) {
        console.error('Error sending push notification:', error);
        return false;
    }
}

module.exports = {
    sendPushNotification
};
