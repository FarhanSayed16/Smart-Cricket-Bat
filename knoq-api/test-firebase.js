require('dotenv').config();
const admin = require('firebase-admin');

async function testFirebase() {
  try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    
    console.log("Firebase Admin initialized successfully.");
    
    // Try to list a single user to test permissions
    const listUsersResult = await admin.auth().listUsers(1);
    console.log(`Successfully fetched users. Total users found (limit 1): ${listUsersResult.users.length}`);
    
    console.log("Firebase Test Passed!");
  } catch (error) {
    console.error("Firebase Test Failed:", error);
  }
}

testFirebase();
