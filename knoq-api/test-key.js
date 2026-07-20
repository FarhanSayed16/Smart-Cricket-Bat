require('dotenv').config();
const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
console.log(JSON.stringify(parsed.private_key).substring(0, 50));
