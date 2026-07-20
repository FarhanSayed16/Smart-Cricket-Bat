require('dotenv').config();
const db = require('./db');

async function fix() {
  try {
    await db.query(`
      ALTER TABLE devices 
      ADD COLUMN IF NOT EXISTS academy_id UUID REFERENCES academies(id) ON DELETE CASCADE,
      ADD COLUMN IF NOT EXISTS battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
      ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'charging', 'error'));
    `);
    console.log('Altered table successfully');
    process.exit(0);
  } catch(e) {
    console.log(e);
    process.exit(1);
  }
}
fix();
