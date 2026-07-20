const admin = require('firebase-admin');

const verifyToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ status: 'error', message: 'Unauthorized: No token provided' });
        }

        const token = authHeader.split('Bearer ')[1];
        const decodedToken = await admin.auth().verifyIdToken(token);
        
        // Attach decoded token (including uid, email) to the request
        req.user = decodedToken;
        
        // Visitor Mode Restriction
        if (req.user.email === 'visitor@knoq.in' && req.method !== 'GET') {
            return res.status(403).json({ 
                status: 'error', 
                message: 'Visitor mode is active. Modifications are not allowed in this portfolio showcase.' 
            });
        }

        next();
    } catch (error) {
        console.error('Error verifying Firebase token:', error);
        return res.status(401).json({ status: 'error', message: 'Unauthorized: Invalid token' });
    }
};

module.exports = { verifyToken };
