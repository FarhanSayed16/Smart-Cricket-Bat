const ffmpeg = require('fluent-ffmpeg');
const ffmpegInstaller = require('@ffmpeg-installer/ffmpeg');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { Readable } = require('stream');
const { pipeline } = require('stream/promises');
const db = require('../db');

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

/**
 * Downloads a file from Firebase Storage to a local temporary path.
 */
async function downloadFile(url, destPath) {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Failed to download video: ${response.status} ${response.statusText}`);
    const fileStream = fs.createWriteStream(destPath);
    const readable = Readable.fromWeb(response.body);
    await pipeline(readable, fileStream);
}

/**
 * Uploads a local file to Firebase Storage and returns the public URL.
 */
async function uploadToFirebase(localPath, destinationPath) {
    const bucket = admin.storage().bucket();
    await bucket.upload(localPath, {
        destination: destinationPath,
        metadata: {
            contentType: 'video/mp4',
        }
    });
    const file = bucket.file(destinationPath);
    await file.makePublic();
    return `https://storage.googleapis.com/${bucket.name}/${destinationPath}`;
}

/**
 * Extracts a clip from a video using FFmpeg.
 */
function extractClip(inputPath, outputPath, startTimeSeconds, durationSeconds) {
    return new Promise((resolve, reject) => {
        ffmpeg(inputPath)
            .setStartTime(startTimeSeconds)
            .setDuration(durationSeconds)
            .output(outputPath)
            .on('end', resolve)
            .on('error', reject)
            .run();
    });
}

/**
 * Main job to process a session's video.
 */
async function processSessionVideo(sessionId, videoUrl, academyId) {
    console.log(`[ClipExtractor] Starting job for session ${sessionId}`);
    const tempDir = path.join(__dirname, '..', 'tmp', sessionId);
    if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });

    const localVideoPath = path.join(tempDir, 'full_video.mp4');

    try {
        // 1. Get clip padding setting from academy
        const academyRes = await db.query('SELECT video_settings FROM academies WHERE id = $1', [academyId]);
        let clipPaddingMs = 4000; // Default 4 seconds (2s before, 2s after)
        if (academyRes.rows.length > 0 && academyRes.rows[0].video_settings) {
            clipPaddingMs = academyRes.rows[0].video_settings.clip_padding_ms || 4000;
        }

        // 2. Fetch shots with video offsets
        const shotsRes = await db.query(`
            SELECT id, shot_number, video_offset_ms 
            FROM shots 
            WHERE session_id = $1 AND video_offset_ms IS NOT NULL
            ORDER BY shot_number ASC
        `, [sessionId]);
        
        if (shotsRes.rows.length === 0) {
            console.log(`[ClipExtractor] No shots with video offsets for session ${sessionId}. Skipping.`);
            return;
        }

        // 3. Download the full video
        console.log(`[ClipExtractor] Downloading full video to ${localVideoPath}...`);
        await downloadFile(videoUrl, localVideoPath);

        // 4. Process each shot
        for (const shot of shotsRes.rows) {
            const clipFilename = `shot_${shot.shot_number}.mp4`;
            const localClipPath = path.join(tempDir, clipFilename);
            const storagePath = `sessions/${sessionId}/clips/${clipFilename}`;

            // Calculate start time and duration
            // offset is the impact time. We want (padding / 2) before and (padding / 2) after.
            const impactMs = shot.video_offset_ms;
            let startMs = impactMs - (clipPaddingMs / 2);
            if (startMs < 0) startMs = 0; // Prevent negative start time
            
            const startSec = startMs / 1000.0;
            const durationSec = clipPaddingMs / 1000.0;

            console.log(`[ClipExtractor] Extracting clip for shot ${shot.shot_number} (Start: ${startSec}s, Duration: ${durationSec}s)...`);
            await extractClip(localVideoPath, localClipPath, startSec, durationSec);

            console.log(`[ClipExtractor] Uploading clip to Firebase: ${storagePath}...`);
            const clipUrl = await uploadToFirebase(localClipPath, storagePath);

            // Update database
            await db.query(`UPDATE shots SET clip_url = $1 WHERE id = $2`, [clipUrl, shot.id]);
            
            // Create a placeholder record in shot_analysis table for future ML processing
            await db.query(`
                INSERT INTO shot_analysis (session_id, shot_number, clip_url, quality_rating, tagging_metadata) 
                VALUES ($1, $2, $3, 0, '{"tagged": false}'::jsonb)
            `, [sessionId, shot.shot_number, clipUrl]);
        }

        console.log(`[ClipExtractor] Successfully processed session ${sessionId}`);

    } catch (error) {
        console.error(`[ClipExtractor] Error processing session ${sessionId}:`, error);
    } finally {
        // Cleanup temp directory
        fs.rmSync(tempDir, { recursive: true, force: true });
    }
}

// Simple background queue manager
const extractionQueue = [];
let isProcessing = false;

async function processQueue() {
    if (isProcessing || extractionQueue.length === 0) return;
    
    isProcessing = true;
    const task = extractionQueue.shift();
    
    await processSessionVideo(task.sessionId, task.videoUrl, task.academyId);
    
    isProcessing = false;
    processQueue(); // Process next in queue
}

function queueSessionVideoExtraction(sessionId, videoUrl, academyId) {
    extractionQueue.push({ sessionId, videoUrl, academyId });
    processQueue();
}

module.exports = {
    queueSessionVideoExtraction
};
