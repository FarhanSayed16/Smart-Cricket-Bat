# Firestore Index Configuration

## Required Indexes for Coach's Eye AI

To enable proper data storage and retrieval, you need to create the following Firestore indexes in your Firebase Console.

### 1. Sessions Collection Index
**Collection Group**: `sessions`
**Fields**:
- `playerId` (Ascending)
- `date` (Descending)
- `__name__` (Descending)

**Index URL**: https://console.firebase.google.com/v1/r/project/coaches-eye-ai/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9jb2FjaGVzLWV5ZS1haS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvc2Vzc2lvbnMvaW5kZXhlcy9fEAEaDAoIcGxheWVySWQQARoICgRkYXRlEAIaDAoIX19uYW1lX18QAg

### 2. Videos Collection Index
**Collection Group**: `videos`
**Fields**:
- `playerId` (Ascending)
- `recordedAt` (Descending)
- `__name__` (Descending)

**Index URL**: https://console.firebase.google.com/v1/r/project/coaches-eye-ai/firestore/indexes?create_composite=Ck1wcm9qZWN0cy9jb2FjaGVzLWV5ZS1haS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvdmlkZW9zL2luZGV4ZXMvXxABGgwKCHBsYXllcklkEAEaDgoKcmVjb3JkZWRBdBACGgwKCF9fbmFtZV9fEAI

### 3. Shots Collection Index
**Collection Group**: `shots`
**Fields**:
- `sessionId` (Ascending)
- `timestamp` (Ascending)
- `__name__` (Ascending)

## How to Create Indexes

1. **Go to Firebase Console**: https://console.firebase.google.com/project/coaches-eye-ai/firestore/indexes
2. **Click "Create Index"**
3. **Select Collection Group**: Choose the appropriate collection (`sessions`, `videos`, or `shots`)
4. **Add Fields**: Add the fields in the order specified above
5. **Set Order**: Set ascending/descending as specified
6. **Click "Create"**

## Alternative: Use the Direct Links

You can click on the URLs provided above to directly create the indexes in Firebase Console.

## After Creating Indexes

Once the indexes are created (this may take a few minutes), the app will be able to:
- ✅ Save and retrieve session data
- ✅ Save and retrieve video metadata
- ✅ Save and retrieve shot data
- ✅ Display analytics and summaries
- ✅ Show user performance data

## Testing Data Storage

After creating the indexes:
1. **Start a new session** from the dashboard
2. **Record some shots** in the live session
3. **Check Analytics** to see comprehensive data
4. **View Media Gallery** to see saved sessions and videos

The app will now properly store and display all user data, analytics, and video recordings!