# 🔧 **CRITICAL: Complete Google Sign-In Setup**

## **Current Status**: ✅ SHA1 Hash Found
**Your SHA1 Hash**: `35:E4:40:D1:3D:63:14:E0:93:C2:29:A1:44:91:AF:55:4E:76:1B:5F`

## **Next Steps**: Get Real OAuth Client IDs

### **Step 1: Add SHA1 to Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **coaches-eye-ai**
3. Go to **Project Settings** (gear icon)
4. Scroll to **Your apps**
5. Click on **com.example.smart_bat_app**
6. Click **Add fingerprint**
7. Paste: `35:E4:40:D1:3D:63:14:E0:93:C2:29:A1:44:91:AF:55:4E:76:1B:5F`
8. Click **Save**

### **Step 2: Download Updated google-services.json**
1. In the same page, click **Download google-services.json**
2. Replace: `smart_bat_app/android/app/google-services.json`

### **Step 3: Verify OAuth Clients**
The downloaded file should have real OAuth client IDs like:
```json
"oauth_client": [
  {
    "client_id": "419313572643-REAL_CLIENT_ID.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.smart_bat_app",
      "certificate_hash": "35:E4:40:D1:3D:63:14:E0:93:C2:29:A1:44:91:AF:55:4E:76:1B:5F"
    }
  },
  {
    "client_id": "419313572643-REAL_WEB_CLIENT_ID.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

## **Temporary Fix Applied**
I've added placeholder OAuth clients with your correct SHA1 hash. This might work for testing, but you should get the real ones from Firebase Console for production.

## **Test Google Sign-In**
After updating the file, test Google Sign-In in your app to see if it works.

---

**Would you like me to continue with the next Phase 1 fixes while you update the Firebase Console?**
