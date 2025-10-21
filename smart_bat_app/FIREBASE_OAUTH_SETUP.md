# 🔧 **FIREBASE OAUTH CLIENT SETUP GUIDE**

## **CRITICAL: Google Sign-In Configuration**

Your `google-services.json` file is missing the OAuth client configuration. Follow these steps to fix it:

### **Step 1: Get SHA1 Certificate Hash**

Run this command in your terminal:
```bash
cd smart_bat_app
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **SHA1** fingerprint and copy it.

### **Step 2: Add SHA1 to Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **coaches-eye-ai**
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps**
5. Click on your Android app: **com.example.smart_bat_app**
6. Click **Add fingerprint**
7. Paste your SHA1 hash
8. Click **Save**

### **Step 3: Download Updated google-services.json**

1. In the same Firebase Console page
2. Click **Download google-services.json**
3. Replace the file in: `smart_bat_app/android/app/google-services.json`

### **Step 4: Verify OAuth Client Configuration**

The downloaded file should now have:
```json
"oauth_client": [
  {
    "client_id": "419313572643-XXXXXXXXXX.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.smart_bat_app",
      "certificate_hash": "YOUR_ACTUAL_SHA1_HASH"
    }
  },
  {
    "client_id": "419313572643-XXXXXXXXXX.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

### **Step 5: Test Google Sign-In**

After updating the file, test Google Sign-In in your app.

---

## **Alternative: Quick Fix (Temporary)**

If you want to test immediately, I can create a temporary configuration that might work for development:

1. Use the debug keystore SHA1
2. Create placeholder OAuth clients
3. Test the authentication flow

**Would you like me to proceed with the temporary fix, or would you prefer to follow the Firebase Console steps above?**
