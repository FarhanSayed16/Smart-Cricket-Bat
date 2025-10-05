# Firestore Indexes Configuration

## Required Indexes for Coach's Eye AI

### Sessions Collection Indexes
1. **playerId + date (descending)**
   - Collection: sessions
   - Fields: playerId (Ascending), date (Descending)
   - Used for: Getting sessions for a player ordered by date

2. **playerId + date (ascending)**
   - Collection: sessions  
   - Fields: playerId (Ascending), date (Ascending)
   - Used for: Getting sessions for a player in chronological order

### Shots Collection Indexes
1. **sessionId + timestamp (ascending)**
   - Collection: shots
   - Fields: sessionId (Ascending), timestamp (Ascending)
   - Used for: Getting shots for a session in chronological order

2. **sessionId + timestamp (descending)**
   - Collection: shots
   - Fields: sessionId (Ascending), timestamp (Descending)
   - Used for: Getting shots for a session in reverse chronological order

### Player Profiles Collection Indexes
1. **coachId (ascending)**
   - Collection: playerProfiles
   - Fields: coachId (Ascending)
   - Used for: Getting players linked to a coach

### Coach Profiles Collection Indexes
1. **uid (ascending)**
   - Collection: coachProfiles
   - Fields: uid (Ascending)
   - Used for: Getting coach profile by UID

### Coach Invite Codes Collection Indexes
1. **code (ascending)**
   - Collection: coachInviteCodes
   - Fields: code (Ascending)
   - Used for: Looking up invite codes

## How to Create These Indexes

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `coaches-eye-ai`
3. Go to Firestore Database → Indexes
4. Click "Create Index"
5. For each index above:
   - Select the collection
   - Add the fields in the specified order
   - Set the sort order (Ascending/Descending)
   - Click "Create"

## Alternative: Use Firebase CLI

You can also create these indexes using the Firebase CLI:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firestore indexes
firebase init firestore

# Deploy indexes
firebase deploy --only firestore:indexes
```

## Index Creation URLs

The error message provides direct links to create the required indexes:

1. **Sessions Index**: https://console.firebase.google.com/v1/r/project/coaches-eye-ai/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9jb2FjaGVzLWV5ZS1haS9kYXRhYmFzZXMvKGRIZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvc2Vzc2lvbnMvaW5kZXhlcy9fEAEaDAolcGxheWVySWQQAROICgRkYXRIEAIaDAoIX19uYW11X18QAg

Click this link to automatically create the sessions index.

## Security Rules

Make sure your Firestore security rules allow the required queries:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Sessions are accessible by the player who created them
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null && 
        resource.data.playerId == request.auth.uid;
    }
    
    // Shots are accessible by the player who created them
    match /shots/{shotId} {
      allow read, write: if request.auth != null && 
        resource.data.sessionId in get(/databases/$(database)/documents/sessions/$(resource.data.sessionId)).data.playerId == request.auth.uid;
    }
    
    // Player profiles
    match /playerProfiles/{playerId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == playerId || 
         resource.data.coachId == request.auth.uid);
    }
    
    // Coach profiles
    match /coachProfiles/{coachId} {
      allow read, write: if request.auth != null && request.auth.uid == coachId;
    }
    
    // Coach invite codes
    match /coachInviteCodes/{code} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```
