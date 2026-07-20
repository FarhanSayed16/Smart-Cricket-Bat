require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const admin = require('firebase-admin');

try {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin initialized successfully.');
} catch (error) {
  console.error('Firebase Admin initialization error:', error);
}

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(helmet());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date() });
});

// Route integration placeholders
app.use('/auth', require('./routes/auth'));
app.use('/users', require('./routes/users'));
app.use('/sessions', require('./routes/sessions'));
app.use('/analytics', require('./routes/analytics'));
app.use('/academy', require('./routes/academy'));
app.use('/coach', require('./routes/coach'));
app.use('/dashboard', require('./routes/dashboard'));
app.use('/drills', require('./routes/drills'));
app.use('/exports', require('./routes/exports'));

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ status: 'error', message: 'Internal Server Error' });
});

if (require.main === module) {
  const { initCronJobs } = require('./cron/scheduler');
  initCronJobs();
  
  app.listen(PORT, () => {
      console.log(`Server listening on port ${PORT}`);
  });
}

module.exports = app;
