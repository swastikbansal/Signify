// Signify ISL Translator - Content Script with Supabase Integration

let isSignifyActive = false;
let transcriptData = [];
let translationActive = false;
let lastSyncedWord = '';
let currentWordIndex = 0;
let wordTimeout = null;
let currentAnimation = null;
let userManuallyClosed = false;
let supabase = null;
const animationCache = new Map();

// Supabase Configuration
const SUPABASE_URL = 'https://qqyqwtoxjhgashwxyidg.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxeXF3dG94amhnYXNod3h5aWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2MjE5NjIsImV4cCI6MjA2OTE5Nzk2Mn0.IOB5ocrqZPKU6luezwhmLGXUkKgks9w0AM7X2-onI-c';

// --- SUPABASE INITIALIZATION ---
async function initializeSupabase() {
    try {
        // Load Supabase client from local file
        const supabaseScript = document.createElement('script');
        supabaseScript.src = chrome.runtime.getURL('supabase.js');
        supabaseScript.onload = () => {
            if (window.supabase) {
                supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
                console.log('Signify: Supabase initialized successfully');
            } else {
                console.error('Signify: Supabase library not found after loading');
            }
        };
        supabaseScript.onerror = () => {
            console.error('Signify: Failed to load Supabase library');
        };
        document.head.appendChild(supabaseScript);
    } catch (error) {
        console.error('Signify: Failed to initialize Supabase:', error);
    }
}

// --- UTILITY FUNCTIONS ---
function waitForElement(selector, timeout = 10000) {
    return new Promise((resolve, reject) => {
        const interval = setInterval(() => {
            const element = document.querySelector(selector);
            if (element) {
                clearInterval(interval);
                resolve(element);
            }
        }, 200);

        setTimeout(() => {
            clearInterval(interval);
            reject(new Error(`Element "${selector}" not found after ${timeout / 1000} seconds.`));
        }, timeout);
    });
}

// --- INITIALIZATION ---
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeSignify);
} else {
    initializeSignify();
}

async function initializeSignify() {
    console.log("Signify ISL Translator initializing...");
    
    // Initialize Supabase first
    await initializeSupabase();
    
    // Try to create button immediately if elements are ready
    createSignifyButton();
    
    // Also retry multiple times to ensure it gets created
    setTimeout(() => {
        createSignifyButton();
        observeVideoChanges();
        setupVideoPlayListener();
    }, 1000);
    
    // Additional retries for slow-loading pages
    setTimeout(() => createSignifyButton(), 3000);
    setTimeout(() => createSignifyButton(), 5000);
    
    console.log("Signify: Initialization scheduled with multiple retries");
}

// --- VIDEO EVENT LISTENERS ---
function setupVideoPlayListener() {
    waitForElement('video').then(video => {
        if (!video) {
            console.log("Signify: Video element not found. Retrying...");
            setTimeout(setupVideoPlayListener, 2000);
            return;
        }
        console.log("Signify: Video element found. Attaching listeners.");
        video.addEventListener('play', handleVideoPlay);
        video.addEventListener('pause', handleVideoPause);
        video.addEventListener('ended', handleVideoEnd);

        if (!video.paused && !video.ended) {
            handleVideoPlay();
        }
    });
}

function handleVideoPause() {
    if (translationActive) {
        pauseTranslation();
        console.log("Signify: Video paused, translation paused");
    }
    
    if (window.signifyAvatar && window.signifyAvatar.setIdlePose) {
        window.signifyAvatar.setIdlePose();
        console.log("Signify: Video paused, returning to default animation");
    }
}

function handleVideoPlay() {
    setTimeout(() => {
        chrome.storage.sync.get(['signifyEnabled', 'autoStart'], (settings) => {
            if (settings.signifyEnabled === false) {
                return;
            }

            const isAvatarVisible = !!document.getElementById('signify-avatar-container');

            if (isAvatarVisible) {
                if (transcriptData.length > 0 && !translationActive) {
                    console.log("Signify: Video resumed, restarting translation...");
                    resumeTranslation();
                } else if (transcriptData.length === 0 && !translationActive) {
                    console.log("Signify: Resuming and extracting transcript...");
                    extractTranscriptAndStart();
                }
            } 
            else if (settings.autoStart === true) {
                console.log("Signify: Auto-starting translation...");
                showAvatarInterface();
                extractTranscriptAndStart();
            } 
            else {
                console.log("Signify: Auto-start is disabled. Waiting for user action.");
            }
        });
    }, 500);
}

function handleVideoEnd() {
    if (translationActive) resetTranslation();
}

// --- TRANSCRIPT EXTRACTION ---
async function extractTranscriptAndStart() {
    if (transcriptData.length > 0) {
        console.log("Signify: Transcript already loaded. Starting translation.");
        startTranslation();
        return;
    }
    
    console.log("Signify: Starting transcript extraction process...");
    
    const hasTranscriptButton = document.querySelector('button[aria-label*="transcript"], button[aria-label*="Transcript"]');
    if (!hasTranscriptButton) {
        console.log("Signify: No transcript button found. Video may not have captions.");
        generateBasicTranscription();
        startTranslation();
        return;
    }
    
    await extractTranscript();
    startTranslation();
}

async function extractTranscript() {
    console.log("Signify: Starting transcript extraction...");
    transcriptData = [];

    try {
        const transcriptButton = await waitForElement('button[aria-label="Show transcript"]');
        transcriptButton.click();

        console.log("Signify: Reading transcript...");
        await waitForElement('ytd-transcript-segment-renderer');
        
        const segments = document.querySelectorAll('ytd-transcript-segment-renderer');
        console.log(`Signify: Found ${segments.length} transcript segments`);
        
        if (segments.length === 0) {
            throw new Error("No transcript segments found");
        }

        transcriptData = [];
        segments.forEach((segment, index) => {
            const timeEl = segment.querySelector('.segment-timestamp');
            const textEl = segment.querySelector('.segment-text');
            
            if (timeEl && textEl) {
                const timeText = timeEl.textContent.trim();
                const segmentText = textEl.textContent.trim();
                const startTime = parseTimeToSeconds(timeText);
                
                if (segmentText && segmentText.length > 0) {
                    let nextStartTime = startTime + 5.0;
                    if (index < segments.length - 1) {
                        const nextTimeEl = segments[index + 1].querySelector('.segment-timestamp');
                        if (nextTimeEl) {
                            nextStartTime = parseTimeToSeconds(nextTimeEl.textContent.trim());
                        }
                    }
                    
                    const segmentDuration = nextStartTime - startTime;
                    const words = segmentText.split(/\s+/).filter(Boolean);
                    const wordDuration = Math.max(0.3, segmentDuration / words.length);
                    
                    words.forEach((word, wordIndex) => {
                        const cleanedWord = word.toLowerCase().replace(/[^\w\s'-]/g, '');
                        if (cleanedWord) {
                            const wordStartTime = startTime + (wordIndex * wordDuration);
                            const wordEndTime = Math.min(nextStartTime, startTime + ((wordIndex + 1) * wordDuration));
                            
                            transcriptData.push({
                                word: cleanedWord,
                                startTime: wordStartTime,
                                endTime: wordEndTime,
                                originalText: word,
                                segmentIndex: index
                            });
                        }
                    });
                }
            }
        });
        
        if (transcriptData.length === 0) {
            throw new Error("Could not extract meaningful text.");
        }

        console.log(`Signify: Successfully extracted ${transcriptData.length} words with real timestamps`);
        
        try {
            const closeButton = await waitForElement('button[aria-label="Close transcript"]', 2000);
            closeButton.click();
        } catch (error) {
            console.log("Signify: Could not find close transcript button, continuing...");
        }
        
        return true;
        
    } catch (error) {
        console.log(`Signify: Transcript extraction failed: ${error.message}`);
        console.log("Signify: Falling back to basic transcription from title.");
        generateBasicTranscription();
        
        if (transcriptData.length > 0) {
            return true;
        }
        
        console.error("Signify: Could not find any transcript or video details.");
        return false;
    }
}

function parseTimeToSeconds(timeStr) {
    if (!timeStr) return 0;
    const parts = timeStr.split(':').map(Number);
    if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
    if (parts.length === 2) return parts[0] * 60 + parts[1];
    return parts[0] || 0;
}

function generateBasicTranscription() {
    const videoTitle = document.querySelector('h1.ytd-video-primary-info-renderer yt-formatted-string');
    if (videoTitle && videoTitle.textContent) {
        const words = videoTitle.textContent.split(/\s+/).filter(Boolean);
        transcriptData = words.map((word, index) => ({
            word: word.toLowerCase().replace(/[^\w]/g, ''),
            startTime: index * 2,
            endTime: (index + 1) * 2,
        }));
    }
}

// --- TRANSLATION LOGIC ---
function startTranslation() {
    const video = document.querySelector('video');
    if (!video || transcriptData.length === 0) {
        console.log("Signify: No video or transcript available");
        return;
    }
    
    translationActive = true;
    console.log("Signify: Starting translation sync.");
    
    console.log(`Signify: Video current time: ${video.currentTime.toFixed(2)}s`);
    if (transcriptData.length > 0) {
        const sampleWords = transcriptData.slice(0, 10);
        console.log("Signify: Sample transcript timing:");
        sampleWords.forEach((word, i) => {
            console.log(`  ${i+1}. "${word.originalText}" at ${word.startTime.toFixed(2)}-${word.endTime.toFixed(2)}s`);
        });
    }
    
    syncWithVideo(video);
}

function pauseTranslation() {
    translationActive = false;
    console.log(`Signify: Translation paused at word index ${currentWordIndex}`);
    
    if (window.signifyAvatar && window.signifyAvatar.setIdlePose) {
        window.signifyAvatar.setIdlePose();
    }
}

function resumeTranslation() {
    if (transcriptData.length > 0) {
        const video = document.querySelector('video');
        if (video && !video.paused) {
            translationActive = true;
            console.log(`Signify: Resuming translation sync at ${video.currentTime.toFixed(2)}s`);
            
            lastSyncedWord = ''; 
            
            const currentTime = video.currentTime;
            let resumeIndex = 0;
            for (let i = 0; i < transcriptData.length; i++) {
                if (currentTime >= transcriptData[i].startTime) {
                    resumeIndex = i;
                } else {
                    break; 
                }
            }
            currentWordIndex = resumeIndex;
            console.log(`Signify: Resuming from index ${currentWordIndex}`);

            // Clear any existing timeout and restart sync
            if (wordTimeout) {
                clearTimeout(wordTimeout);
                wordTimeout = null;
            }
            
            syncWithVideo(video);
        } else {
            console.log('Signify: Video is paused, not resuming translation');
        }
    } else {
        console.log('Signify: No transcript data available for resume');
    }
}

function resetTranslation() {
    translationActive = false;
    currentWordIndex = 0;
    
    if (window.syncInterval) {
        clearInterval(window.syncInterval);
        window.syncInterval = null;
    }
    if (wordTimeout) {
        clearTimeout(wordTimeout);
        wordTimeout = null;
    }
    
    updateCurrentWord('Ready');
    if (window.signifyAvatar && window.signifyAvatar.setIdlePose) {
        window.signifyAvatar.setIdlePose();
        console.log("Signify: Reset to default.glb animation");
    }
    
    if (currentAnimation) {
        currentAnimation.stop();
        currentAnimation = null;
    }
    
    console.log("Signify: Translation reset and cleaned up");
}

function syncWithVideo(video) {
    if (window.syncInterval) clearInterval(window.syncInterval);

    console.log(`Signify: Starting sync with ${transcriptData.length} words`);
    
    if (transcriptData.length > 0) {
        const firstWords = transcriptData.slice(0, 5).map(w => `"${w.originalText}"(${w.startTime.toFixed(1)}s)`).join(', ');
        console.log(`Signify: First words: ${firstWords}`);
        console.log(`Signify: Starting sync from currentWordIndex: ${currentWordIndex}`);
    }

    window.syncInterval = setInterval(() => {
        if (!translationActive || video.paused) {
            return;
        }

        const currentTime = video.currentTime;
        
        let foundWord = null;
        let closestIndex = -1;
        let minTimeDiff = Infinity;
        
        for (let i = 0; i < transcriptData.length; i++) {
            const word = transcriptData[i];
            if (currentTime >= word.startTime && currentTime <= word.endTime) {
                foundWord = word;
                closestIndex = i;
                break;
            }
        }
        
        if (!foundWord) {
            for (let i = 0; i < transcriptData.length; i++) {
                const word = transcriptData[i];
                const timeDiff = Math.abs(currentTime - word.startTime);
                if (timeDiff < minTimeDiff && currentTime <= word.endTime + 0.5) {
                    minTimeDiff = timeDiff;
                    foundWord = word;
                    closestIndex = i;
                }
            }
        }

        if (foundWord && foundWord.word !== lastSyncedWord) {
            lastSyncedWord = foundWord.word;
            currentWordIndex = closestIndex;
            
            const displayWord = foundWord.originalText || foundWord.word;
            updateCurrentWord(displayWord);
            playWordAnimation(foundWord.word);
            
            console.log(`Signify: [${currentTime.toFixed(2)}s] Word "${displayWord}" (expected: ${foundWord.startTime.toFixed(2)}-${foundWord.endTime.toFixed(2)}s, diff: ${Math.abs(currentTime - foundWord.startTime).toFixed(2)}s)`);
            
        } else if (!foundWord && lastSyncedWord !== '') {
            const lastWord = transcriptData[transcriptData.length - 1];
            if (currentTime > lastWord.endTime + 1.0) {
                lastSyncedWord = '';
                updateCurrentWord('...');
                if (window.signifyAvatar && window.signifyAvatar.setIdlePose) {
                    window.signifyAvatar.setIdlePose();
                }
                console.log(`Signify: [${currentTime.toFixed(2)}s] Past all transcript words`);
            }
        }
    }, 100);
}

// --- MAIN AVATAR INTERFACE ---
function showAvatarInterface() {
    if (document.getElementById('signify-avatar-container')) return;
    
    // Add styles first
    if (!document.getElementById('signify-styles')) {
        const style = document.createElement('style');
        style.id = 'signify-styles';
        style.textContent = `
            #signify-avatar-container {
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                width: 50vw !important;
                height: 100vh !important;
                background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #16213e 100%) !important;
                z-index: 2147483646 !important;
                display: flex !important;
                flex-direction: column !important;
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif !important;
                color: #fff !important;
                border-right: 3px solid #FFD700 !important;
                box-shadow: 0 0 50px rgba(255, 215, 0, 0.2) !important;
                backdrop-filter: blur(15px) !important;
                transition: all 0.3s ease !important;
            }
            
            .signify-header {
                background: linear-gradient(90deg, #FFD700, #FFA500) !important;
                color: #000 !important;
                padding: 15px 20px !important;
                display: flex !important;
                justify-content: space-between !important;
                align-items: center !important;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3) !important;
            }
            
            .signify-title {
                font-size: 24px !important;
                font-weight: bold !important;
                display: flex !important;
                align-items: center !important;
                gap: 12px !important;
            }
            
            .signify-controls {
                display: flex !important;
                gap: 10px !important;
            }
            
            .signify-btn {
                background: rgba(0,0,0,0.2) !important;
                border: none !important;
                color: #000 !important;
                padding: 8px 12px !important;
                border-radius: 6px !important;
                cursor: pointer !important;
                font-weight: bold !important;
                transition: all 0.2s ease !important;
            }
            
            .signify-btn:hover {
                background: rgba(0,0,0,0.4) !important;
                transform: scale(1.05) !important;
            }
            
            .avatar-display {
                flex: 1 !important;
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
                background: radial-gradient(circle at center, rgba(255,215,0,0.1) 0%, transparent 70%) !important;
                position: relative !important;
                overflow: hidden !important;
                padding: 20px !important;
            }
            
            .avatar-canvas {
                width: 100% !important;
                height: 100% !important;
                max-width: 400px !important;
                max-height: 600px !important;
                border-radius: 15px !important;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5) !important;
            }
            
            .current-word-display {
                background: linear-gradient(90deg, #4CAF50, #45a049) !important;
                color: #fff !important;
                padding: 20px !important;
                text-align: center !important;
                font-size: 28px !important;
                font-weight: bold !important;
                border-top: 2px solid rgba(255, 215, 0, 0.3) !important;
                min-height: 80px !important;
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
                box-shadow: 0 -5px 20px rgba(0, 0, 0, 0.3) !important;
            }
            
            .avatar-loading {
                color: #FFD700 !important;
                font-size: 20px !important;
                text-align: center !important;
                animation: avatarPulse 2s infinite !important;
            }
            
            @keyframes avatarPulse {
                0%, 100% { opacity: 1; transform: scale(1); }
                50% { opacity: 0.7; transform: scale(1.05); }
            }
            
            @keyframes wordChange {
                0% { transform: scale(1); }
                50% { transform: scale(1.1); }
                100% { transform: scale(1); }
            }
            
            .word-animation {
                animation: wordChange 0.6s ease-out !important;
            }
            
            /* Responsive design */
            @media (max-width: 1200px) {
                #signify-avatar-container {
                    width: 60vw !important;
                }
            }
            
            @media (max-width: 768px) {
                #signify-avatar-container {
                    width: 100vw !important;
                    height: 50vh !important;
                    top: auto !important;
                    bottom: 0 !important;
                }
                
                .signify-title {
                    font-size: 20px !important;
                }
                
                .current-word-display {
                    font-size: 24px !important;
                    padding: 15px !important;
                    min-height: 60px !important;
                }
            }
            
            /* Toggle states */
            #signify-avatar-container.minimized .avatar-display,
            #signify-avatar-container.minimized .current-word-display {
                display: none !important;
            }
            
            #signify-avatar-container.minimized {
                height: 60px !important;
            }
        `;
        document.head.appendChild(style);
    }
    
    const avatarContainer = document.createElement('div');
    avatarContainer.id = 'signify-avatar-container';
    avatarContainer.innerHTML = `
        <div class="signify-header">
            <div class="signify-title">
                <span>🤟</span>
                <span>Signify ISL Translator</span>
            </div>
            <div class="signify-controls">
                <button id="signify-minimize" class="signify-btn" title="Minimize">−</button>
                <button id="signify-close" class="signify-btn" title="Close">✕</button>
            </div>
        </div>
        <div class="avatar-display" id="avatarDisplay">
            <div class="avatar-loading">Loading 3D Avatar...</div>
        </div>
        <div class="current-word-display" id="currentWordDisplay">Ready to translate</div>
    `;
    
    document.body.appendChild(avatarContainer);
    
    // Event listeners
    document.getElementById('signify-close').addEventListener('click', hideAvatarInterface);
    document.getElementById('signify-minimize').addEventListener('click', toggleAvatarInterface);
    
    // Initialize the avatar immediately with fallback
    console.log("Signify: About to initialize avatar...");
    createImmediateAvatar();
    isSignifyActive = true;
    
    console.log("Signify: Main avatar interface created");
}

function hideAvatarInterface() {
    const container = document.getElementById('signify-avatar-container');
    if (container) {
        container.remove();
    }
    isSignifyActive = false;
    userManuallyClosed = true;
    resetTranslation();
}

function toggleAvatarInterface() {
    const container = document.getElementById('signify-avatar-container');
    const minimizeBtn = document.getElementById('signify-minimize');
    
    if (container.classList.contains('minimized')) {
        container.classList.remove('minimized');
        minimizeBtn.textContent = '−';
    } else {
        container.classList.add('minimized');
        minimizeBtn.textContent = '□';
    }
}

function updateCurrentWord(word) {
    const display = document.getElementById('currentWordDisplay');
    if (display) {
        display.textContent = word || '...';
        if (word) {
            display.classList.add('word-animation');
            setTimeout(() => display.classList.remove('word-animation'), 600);
        }
    }
}

// --- IMMEDIATE AVATAR CREATION ---
function createImmediateAvatar() {
    const container = document.getElementById('avatarDisplay');
    if (!container) {
        console.error('Signify: Avatar container not found');
        return;
    }
    
    console.log('Signify: Creating immediate CSS avatar');
    
    // Create CSS-based avatar directly without external scripts
    container.innerHTML = `
        <div class="signify-css-avatar">
            <div class="avatar-figure">
                <div class="avatar-head">
                    <div class="face">🧏‍♀️</div>
                </div>
                <div class="avatar-body"></div>
                <div class="avatar-arm left-arm"></div>
                <div class="avatar-arm right-arm"></div>
            </div>
            <div class="avatar-status">
                <span class="status-text">ISL Translator Ready</span>
                <div class="status-indicator"></div>
            </div>
        </div>
    `;
    
    // Add inline styles to avoid external dependencies
    const avatarStyles = document.createElement('style');
    avatarStyles.id = 'signify-avatar-styles';
    avatarStyles.textContent = `
        .signify-css-avatar {
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            padding: 20px;
            box-sizing: border-box;
            position: relative;
            overflow: hidden;
        }
        
        .avatar-figure {
            position: relative;
            animation: avatarBreathe 3s ease-in-out infinite;
        }
        
        .avatar-head {
            width: 50px;
            height: 50px;
            background: #fdbcb4;
            border-radius: 50%;
            margin: 0 auto 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 3px solid #f1c27d;
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
            position: relative;
        }
        
        .face {
            font-size: 24px;
            animation: faceExpression 4s ease-in-out infinite;
        }
        
        .avatar-body {
            width: 60px;
            height: 80px;
            background: #4CAF50;
            border-radius: 15px;
            margin: 0 auto;
            position: relative;
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
        }
        
        .avatar-body::before {
            content: '';
            position: absolute;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            width: 30px;
            height: 20px;
            background: #45a049;
            border-radius: 10px;
        }
        
        .avatar-arm {
            position: absolute;
            width: 18px;
            height: 50px;
            background: #fdbcb4;
            border-radius: 12px;
            top: 60px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
            transform-origin: top center;
        }
        
        .left-arm {
            left: -5px;
            animation: leftArmSign 3s ease-in-out infinite;
        }
        
        .right-arm {
            right: -5px;
            animation: rightArmSign 3s ease-in-out infinite 1.5s;
        }
        
        .avatar-status {
            margin-top: 20px;
            text-align: center;
            color: white;
        }
        
        .status-text {
            font-size: 14px;
            font-weight: bold;
            text-shadow: 0 2px 4px rgba(0,0,0,0.5);
            display: block;
            margin-bottom: 8px;
        }
        
        .status-indicator {
            width: 12px;
            height: 12px;
            background: #4CAF50;
            border-radius: 50%;
            margin: 0 auto;
            animation: statusPulse 2s ease-in-out infinite;
            box-shadow: 0 0 10px rgba(76, 175, 80, 0.5);
        }
        
        @keyframes avatarBreathe {
            0%, 100% { transform: scale(1) translateY(0px); }
            50% { transform: scale(1.05) translateY(-5px); }
        }
        
        @keyframes faceExpression {
            0%, 80%, 100% { transform: scale(1); }
            10% { transform: scale(1.1); }
        }
        
        @keyframes leftArmSign {
            0%, 100% { transform: rotate(0deg); }
            25% { transform: rotate(-30deg); }
            75% { transform: rotate(15deg); }
        }
        
        @keyframes rightArmSign {
            0%, 100% { transform: rotate(0deg); }
            25% { transform: rotate(30deg); }
            75% { transform: rotate(-15deg); }
        }
        
        @keyframes statusPulse {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.7; transform: scale(1.2); }
        }
        
        .signify-css-avatar::before {
            content: '';
            position: absolute;
            top: -100%;
            left: -100%;
            width: 300%;
            height: 300%;
            background: linear-gradient(45deg, transparent 30%, rgba(255,255,255,0.1) 50%, transparent 70%);
            animation: shine 6s ease-in-out infinite;
            pointer-events: none;
        }
        
        @keyframes shine {
            0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
            100% { transform: translateX(100%) translateY(100%) rotate(45deg); }
        }
    `;
    
    // Remove any existing avatar styles and add new ones
    const existingStyles = document.getElementById('signify-avatar-styles');
    if (existingStyles) {
        existingStyles.remove();
    }
    document.head.appendChild(avatarStyles);
    
    console.log('Signify: Immediate CSS avatar created successfully');
    
    // Try to load THREE.js in the background for potential upgrade
    setTimeout(() => {
        tryUpgradeToThreeJS(container);
    }, 2000);
}

function tryUpgradeToThreeJS(container) {
    console.log('Signify: Attempting THREE.js upgrade in background');
    
    if (window.THREE) {
        console.log('Signify: THREE.js already available, upgrading avatar');
        upgradeToThreeJSAvatar(container);
        return;
    }
    
    const script = document.createElement('script');
    script.src = chrome.runtime.getURL('three.min.js');
    script.onload = () => {
        if (window.THREE) {
            console.log('Signify: THREE.js loaded, upgrading avatar');
            upgradeToThreeJSAvatar(container);
        }
    };
    script.onerror = () => {
        console.log('Signify: THREE.js upgrade failed, keeping CSS avatar');
    };
    document.head.appendChild(script);
}

function upgradeToThreeJSAvatar(container) {
    try {
        // Clear the CSS avatar
        container.innerHTML = '<div style="color: white; text-align: center; padding: 10px;">🔄 Upgrading to 3D...</div>';
        
        setTimeout(() => {
            // Create the THREE.js scene
            const scene = new THREE.Scene();
            scene.background = new THREE.Color(0x001122);
            
            const camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
            camera.position.set(0, 0, 3);
            
            const renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(container.clientWidth, container.clientHeight);
            container.innerHTML = '';
            container.appendChild(renderer.domElement);
            
            // Add lighting
            const ambientLight = new THREE.AmbientLight(0x404040, 0.8);
            scene.add(ambientLight);
            
            const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
            directionalLight.position.set(5, 5, 5);
            scene.add(directionalLight);
            
            // Create simple 3D avatar
            const head = new THREE.Mesh(
                new THREE.SphereGeometry(0.3, 16, 16),
                new THREE.MeshLambertMaterial({ color: 0xfdbcb4 })
            );
            head.position.y = 0.5;
            scene.add(head);
            
            const body = new THREE.Mesh(
                new THREE.CylinderGeometry(0.2, 0.3, 0.8, 8),
                new THREE.MeshLambertMaterial({ color: 0x4CAF50 })
            );
            scene.add(body);
            
            // Animation loop
            function animate() {
                requestAnimationFrame(animate);
                head.rotation.y += 0.005;
                body.rotation.y += 0.003;
                renderer.render(scene, camera);
            }
            animate();
            
            console.log('Signify: Successfully upgraded to THREE.js avatar');
        }, 1000);
        
    } catch (error) {
        console.error('Signify: THREE.js upgrade failed:', error);
        // Fall back to CSS avatar
        createImmediateAvatar();
    }
}

// --- DIRECT AVATAR INITIALIZATION (BACKUP) ---
function initializeAvatarDirect() {
    const container = document.getElementById('avatarDisplay');
    if (!container) {
        console.error('Signify: Avatar container not found');
        return;
    }
    
    console.log('Signify: Starting direct avatar initialization');
    container.innerHTML = '<div style="color: white; padding: 20px;">🔄 Loading 3D Avatar...</div>';
    
    // Load THREE.js synchronously using a more reliable method
    loadThreeJSReliable()
        .then(() => {
            console.log('Signify: THREE.js loaded, creating 3D scene');
            createSimpleAvatar(container);
        })
        .catch(error => {
            console.error('Signify: Failed to load THREE.js:', error);
            console.log('Signify: Falling back to CSS avatar');
            loadFallbackAvatar(container);
        });
}

function loadFallbackAvatar(container) {
    // Load the fallback avatar script
    const fallbackScript = document.createElement('script');
    fallbackScript.src = chrome.runtime.getURL('fallback-avatar.js');
    fallbackScript.onload = () => {
        if (window.createFallbackAvatar) {
            window.createFallbackAvatar(container);
        } else {
            container.innerHTML = '<div style="color: #ffa500; padding: 20px;">⚠️ Avatar system unavailable</div>';
        }
    };
    fallbackScript.onerror = () => {
        container.innerHTML = '<div style="color: #ff6b6b; padding: 20px;">❌ Could not load avatar system</div>';
    };
    document.head.appendChild(fallbackScript);
}

function loadThreeJSReliable() {
    return new Promise((resolve, reject) => {
        // Check if THREE.js is already loaded
        if (window.THREE) {
            console.log('Signify: THREE.js already loaded');
            resolve();
            return;
        }
        
        console.log('Signify: Loading THREE.js...');
        const script = document.createElement('script');
        script.src = chrome.runtime.getURL('three.min.js');
        script.async = false;
        script.defer = false;
        
        script.onload = () => {
            console.log('Signify: THREE.js script loaded');
            if (window.THREE) {
                console.log('Signify: window.THREE is available');
                resolve();
            } else {
                console.error('Signify: window.THREE is undefined after load');
                reject(new Error('THREE.js loaded but window.THREE is undefined'));
            }
        };
        
        script.onerror = (error) => {
            console.error('Signify: Script loading failed:', error);
            reject(new Error('Failed to load THREE.js script'));
        };
        
        document.head.appendChild(script);
    });
}

function createSimpleAvatar(container) {
    try {
        console.log('Signify: Creating 3D scene');
        container.innerHTML = '';
        
        // Create scene
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x001122);
        
        // Create camera
        const camera = new THREE.PerspectiveCamera(
            75, 
            container.clientWidth / container.clientHeight, 
            0.1, 
            1000
        );
        camera.position.set(0, 0, 5);
        
        // Create renderer
        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(container.clientWidth, container.clientHeight);
        renderer.shadowMap.enabled = true;
        container.appendChild(renderer.domElement);
        
        // Add lighting
        const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
        scene.add(ambientLight);
        
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(10, 10, 5);
        scene.add(directionalLight);
        
        // Create a simple avatar placeholder (colored cube)
        const geometry = new THREE.BoxGeometry(1, 1.5, 0.5);
        const material = new THREE.MeshLambertMaterial({ color: 0x4CAF50 });
        const avatar = new THREE.Mesh(geometry, material);
        avatar.position.y = 0.75;
        scene.add(avatar);
        
        // Add a simple animation
        function animate() {
            requestAnimationFrame(animate);
            avatar.rotation.y += 0.01;
            renderer.render(scene, camera);
        }
        animate();
        
        console.log('Signify: 3D avatar created successfully');
        
        // Store references for future use
        window.signifyScene = { scene, camera, renderer, avatar };
        
    } catch (error) {
        console.error('Signify: Error creating 3D scene:', error);
        container.innerHTML = '<div style="color: #ff6b6b; padding: 20px;">❌ 3D Error: ' + error.message + '</div>';
    }
}

// --- ORIGINAL AVATAR INITIALIZATION (BACKUP) ---
function initializeAvatar() {
    const container = document.getElementById('avatarDisplay');
    if (!container) {
        console.error('Signify: Avatar container not found');
        return;
    }
    
    console.log('Signify: Initializing avatar with container:', container);
    
    // Test if we can access extension files
    const testUrl = chrome.runtime.getURL('three.min.js');
    console.log('Signify: Testing access to THREE.js at:', testUrl);
    
    fetch(testUrl)
        .then(response => {
            console.log('Signify: File access test response:', response.status, response.statusText);
            if (response.ok) {
                console.log('Signify: File access SUCCESS - proceeding with loadThreeJS');
                return loadThreeJS();
            } else {
                console.error('Signify: File access FAILED - files not accessible');
                console.log('Signify: Trying alternative loading method...');
                
                // Alternative: Try to load via message passing to background script
                loadThreeJSAlternative()
                    .then(() => createAvatar(container))
                    .catch(() => {
                        container.innerHTML = '<div class="avatar-loading" style="color: #ff6b6b;">❌ Cannot access extension files</div>';
                    });
                return Promise.resolve();
            }
        })
        .then(() => createAvatar(container))
        .catch(error => {
            console.error('Signify: Error in avatar initialization:', error);
            container.innerHTML = '<div class="avatar-loading" style="color: #ff6b6b;">❌ Failed to load 3D libraries</div>';
        });
}

function createAvatar(container) {
    console.log('Signify: createAvatar called with container:', container);
    
    // Clear loading message immediately
    container.innerHTML = '<div class="avatar-loading">Initializing 3D Engine...</div>';
    
    console.log('Signify: Creating avatar in container with dimensions:', container.clientWidth, 'x', container.clientHeight);
    
    if (!window.THREE) {
        console.error('Signify: THREE.js not loaded');
        container.innerHTML = '<div class="avatar-loading" style="color: #ff6b6b;">❌ THREE.js not loaded</div>';
        return;
    }
    
    if (!window.THREE.GLTFLoader) {
        console.error('Signify: GLTFLoader not available');
        container.innerHTML = '<div class="avatar-loading" style="color: #ff6b6b;">❌ GLTFLoader not available</div>';
        return;
    }
    
    console.log('Signify: THREE.js and GLTFLoader available, creating scene...');
    container.innerHTML = '<div class="avatar-loading">Creating 3D Scene...</div>';
    
    // Create Three.js scene
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0a0a0a);
    
    // Create camera
    const camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.set(0, 1.5, 4);
    
    // Create renderer
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.domElement.className = 'avatar-canvas';
    
    // Clear container and add renderer
    container.innerHTML = '';
    container.appendChild(renderer.domElement);
    
    console.log('Signify: Renderer created and added to container');
    
    // Add a simple test cube to verify Three.js is working
    const testGeometry = new THREE.BoxGeometry(1, 1, 1);
    const testMaterial = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
    const testCube = new THREE.Mesh(testGeometry, testMaterial);
    testCube.position.set(2, 0, 0); // Position it to the side
    scene.add(testCube);
    console.log('Signify: Test cube added to scene');
    
    // Add basic lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
    scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 1.0);
    directionalLight.position.set(5, 10, 7);
    directionalLight.castShadow = true;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    scene.add(directionalLight);
    
    // Add point lights for better illumination
    const pointLight1 = new THREE.PointLight(0xFFD700, 0.5, 100);
    pointLight1.position.set(-5, 5, 5);
    scene.add(pointLight1);
    
    const pointLight2 = new THREE.PointLight(0x4CAF50, 0.3, 100);
    pointLight2.position.set(5, -5, 5);
    scene.add(pointLight2);
    
    console.log('Signify: Lighting added to scene');
    
    // Animation variables
    let mixer = null;
    let model = null;
    let defaultAnimation = null;
    let currentAction = null;
    let isPlaying = false;
    const clock = new THREE.Clock();
    
    // Animation loop
    function animate() {
        requestAnimationFrame(animate);
        
        if (mixer) {
            mixer.update(clock.getDelta());
        }
        
        // Rotate model slowly for better viewing
        if (model) {
            model.rotation.y += 0.003;
        }
        
        // Rotate test cube to show it's working
        if (testCube) {
            testCube.rotation.x += 0.01;
            testCube.rotation.y += 0.01;
        }
        
        renderer.render(scene, camera);
    }
    animate();
    console.log('Signify: Animation loop started');
    
    // Load default animation from Supabase
    console.log('Signify: Loading default animation...');
    loadDefaultAnimation().then((animationData) => {
        console.log('Signify: Default animation data received:', animationData);
        if (animationData) {
            const loader = new THREE.GLTFLoader();
            console.log('Signify: GLTFLoader created, loading model from:', animationData);
            
            // Convert base64 or URL to blob URL for Three.js
            let modelUrl;
            if (typeof animationData === 'string' && animationData.startsWith('data:')) {
                modelUrl = animationData;
            } else if (typeof animationData === 'string') {
                modelUrl = animationData; // Direct URL
            } else {
                // Convert ArrayBuffer to blob URL
                const blob = new Blob([animationData], { type: 'model/gltf-binary' });
                modelUrl = URL.createObjectURL(blob);
            }
            
            loader.load(
                modelUrl,
                (gltf) => {
                    console.log("Signify: Default animation model loaded successfully", gltf);
                    
                    model = gltf.scene;
                    scene.add(model);
                    
                    console.log("Signify: Model added to scene, centering and scaling...");
                    
                    // Center and scale the model
                    const box = new THREE.Box3().setFromObject(model);
                    const center = box.getCenter(new THREE.Vector3());
                    model.position.sub(center);
                    
                    const size = box.getSize(new THREE.Vector3());
                    const maxSize = Math.max(size.x, size.y, size.z);
                    
                    console.log("Signify: Model size:", size, "Max size:", maxSize);
                    
                    if (maxSize > 3) {
                        const scale = 3 / maxSize;
                        model.scale.multiplyScalar(scale);
                        console.log("Signify: Model scaled by factor:", scale);
                    }
                    
                    // Setup animations
                    if (gltf.animations && gltf.animations.length > 0) {
                        console.log("Signify: Setting up animations, found:", gltf.animations.length, "animations");
                        mixer = new THREE.AnimationMixer(model);
                        defaultAnimation = gltf.animations[0];
                        
                        currentAction = mixer.clipAction(defaultAnimation);
                        currentAction.loop = THREE.LoopRepeat;
                        currentAction.play();
                        isPlaying = true;
                        
                        console.log("Signify: Default animation started successfully");
                    }
                    
                    setupAvatarControls();
                },
                (progress) => {
                    const percentage = (progress.loaded / progress.total) * 100;
                    console.log(`Signify: Loading progress: ${Math.round(percentage)}%`);
                },
                (error) => {
                    console.error('Signify: Error loading default animation:', error);
                    console.log('Signify: Creating fallback avatar...');
                    
                    // Create a fallback avatar using basic geometry
                    createFallbackAvatar(scene);
                    
                    setupAvatarControls();
                }
            );
        } else {
            console.error("Signify: No default animation data received");
            console.log('Signify: Creating fallback avatar...');
            
            // Create a fallback avatar using basic geometry
            createFallbackAvatar(scene);
            
            setupAvatarControls();
        }
    });
    
    // Function to create a simple fallback avatar
    function createFallbackAvatar(scene) {
        console.log('Signify: Creating fallback geometric avatar');
        
        // Create a simple humanoid shape
        const group = new THREE.Group();
        
        // Head
        const headGeometry = new THREE.SphereGeometry(0.3, 32, 32);
        const headMaterial = new THREE.MeshPhongMaterial({ color: 0xffdbac });
        const head = new THREE.Mesh(headGeometry, headMaterial);
        head.position.y = 1.5;
        group.add(head);
        
        // Body
        const bodyGeometry = new THREE.CylinderGeometry(0.3, 0.4, 1.2, 8);
        const bodyMaterial = new THREE.MeshPhongMaterial({ color: 0x4a90e2 });
        const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
        body.position.y = 0.3;
        group.add(body);
        
        // Arms
        const armGeometry = new THREE.CylinderGeometry(0.08, 0.08, 0.8, 8);
        const armMaterial = new THREE.MeshPhongMaterial({ color: 0xffdbac });
        
        const leftArm = new THREE.Mesh(armGeometry, armMaterial);
        leftArm.position.set(-0.5, 0.5, 0);
        leftArm.rotation.z = 0.3;
        group.add(leftArm);
        
        const rightArm = new THREE.Mesh(armGeometry, armMaterial);
        rightArm.position.set(0.5, 0.5, 0);
        rightArm.rotation.z = -0.3;
        group.add(rightArm);
        
        // Add to scene
        scene.add(group);
        model = group;
        
        console.log('Signify: Fallback avatar created successfully');
    }
    
    function setupAvatarControls() {
        // Global avatar interface
        window.signifyAvatar = {
            mixer: mixer,
            model: model,
            defaultAnimation: defaultAnimation,
            currentAction: currentAction,
            isPlaying: isPlaying,
            renderer: renderer,
            camera: camera,
            scene: scene,
            
            // Set to default/idle animation
            setIdlePose: () => {
                console.log("Signify: Setting idle pose - playing default animation");
                
                if (!mixer || !defaultAnimation) {
                    console.warn("Signify: No mixer or default animation available");
                    return;
                }
                
                try {
                    mixer.stopAllAction();
                    
                    currentAction = mixer.clipAction(defaultAnimation);
                    currentAction.reset();
                    currentAction.setLoop(THREE.LoopRepeat);
                    currentAction.setEffectiveWeight(1.0);
                    currentAction.play();
                    
                    isPlaying = true;
                    window.signifyAvatar.currentAction = currentAction;
                    window.signifyAvatar.isPlaying = isPlaying;
                    
                    console.log("Signify: Default animation playing");
                } catch (error) {
                    console.error("Signify: Error playing default animation:", error);
                }
            },
            
            // Play animation for a specific word
            playWordAnimation: async (word) => {
                const cleanWord = word.toLowerCase().replace(/[^\w]/g, '');
                if (!cleanWord) {
                    window.signifyAvatar.setIdlePose();
                    return;
                }
                
                console.log(`Signify: Attempting to play animation for word: "${cleanWord}"`);
                
                // Check cache first
                if (animationCache.has(cleanWord)) {
                    const cachedClip = animationCache.get(cleanWord);
                    if (cachedClip) {
                        console.log(`Signify: Playing cached animation for "${cleanWord}"`);
                        playAnimationClip(cachedClip);
                    } else {
                        console.log(`Signify: No animation cached for "${cleanWord}", using default`);
                        window.signifyAvatar.setIdlePose();
                    }
                    return;
                }
                
                // Try to load word-specific animation from Supabase
                try {
                    const wordAnimation = await loadWordAnimation(cleanWord);
                    if (wordAnimation) {
                        const loader = new THREE.GLTFLoader();
                        
                        // Convert animation data to usable format
                        let modelUrl;
                        if (typeof wordAnimation === 'string' && wordAnimation.startsWith('data:')) {
                            modelUrl = wordAnimation;
                        } else if (typeof wordAnimation === 'string') {
                            modelUrl = wordAnimation;
                        } else {
                            const blob = new Blob([wordAnimation], { type: 'model/gltf-binary' });
                            modelUrl = URL.createObjectURL(blob);
                        }
                        
                        const gltf = await loader.loadAsync(modelUrl);
                        
                        if (gltf.animations && gltf.animations.length > 0) {
                            const wordClip = gltf.animations[0];
                            animationCache.set(cleanWord, wordClip);
                            console.log(`Signify: Loaded and playing animation for "${cleanWord}"`);
                            playAnimationClip(wordClip);
                        } else {
                            console.log(`Signify: No animations in ${cleanWord}.glb, using default`);
                            animationCache.set(cleanWord, null);
                            window.signifyAvatar.setIdlePose();
                        }
                    } else {
                        console.log(`Signify: Could not load animation for "${cleanWord}", using default`);
                        animationCache.set(cleanWord, null);
                        window.signifyAvatar.setIdlePose();
                    }
                } catch (error) {
                    console.log(`Signify: Error loading animation for "${cleanWord}":`, error);
                    animationCache.set(cleanWord, null);
                    window.signifyAvatar.setIdlePose();
                }
            }
        };
        
        // Function to play a specific animation clip
        function playAnimationClip(clip) {
            if (!mixer || !clip) return;
            
            try {
                mixer.stopAllAction();
                
                const action = mixer.clipAction(clip);
                action.reset();
                action.setLoop(THREE.LoopOnce, 1);
                action.clampWhenFinished = true;
                action.play();
                
                currentAction = action;
                isPlaying = true;
                
                mixer.removeEventListener('finished', returnToDefault);
                mixer.addEventListener('finished', returnToDefault);
                
            } catch (error) {
                console.error("Signify: Error playing animation clip:", error);
                window.signifyAvatar.setIdlePose();
            }
        }
        
        // Return to default animation when word animation finishes
        function returnToDefault() {
            console.log("Signify: Word animation finished, returning to default");
            setTimeout(() => {
                if (window.signifyAvatar) {
                    window.signifyAvatar.setIdlePose();
                }
            }, 100);
        }
        
        console.log("Signify: Avatar controls setup completed");
        
        // Start with default animation
        setTimeout(() => {
            if (window.signifyAvatar) {
                window.signifyAvatar.setIdlePose();
            }
        }, 500);
    }
    
    // Handle window resize
    window.addEventListener('resize', () => {
        if (camera && renderer && container) {
            const width = container.clientWidth;
            const height = container.clientHeight;
            
            camera.aspect = width / height;
            camera.updateProjectionMatrix();
            renderer.setSize(width, height);
        }
    });
}

// --- SUPABASE DATA LOADING FUNCTIONS ---
async function loadDefaultAnimation() {
    try {
        if (!supabase) {
            console.warn("Signify: Supabase not initialized, loading local default animation");
            // Return local default.glb file URL
            return chrome.runtime.getURL('animation/default.glb');
        }
        
        // Query for default animation
        const { data, error } = await supabase
            .from('animations')
            .select('animation_file, file_url')
            .eq('word', 'default')
            .single();
        
        if (error) {
            console.error("Signify: Error loading default animation from Supabase:", error);
            console.log("Signify: Falling back to local default animation");
            return chrome.runtime.getURL('animation/default.glb');
        }
        
        if (data && data.file_url) {
            console.log("Signify: Default animation URL loaded from Supabase");
            return data.file_url;
        } else if (data && data.animation_file) {
            console.log("Signify: Default animation binary data loaded from Supabase");
            return data.animation_file;
        }
        
        // Fallback to local file if no data found in Supabase
        console.log("Signify: No default animation found in Supabase, using local file");
        return chrome.runtime.getURL('animation/default.glb');
    } catch (error) {
        console.error("Signify: Error in loadDefaultAnimation:", error);
        console.log("Signify: Falling back to local default animation");
        return chrome.runtime.getURL('animation/default.glb');
    }
}

async function loadWordAnimation(word) {
    try {
        if (!supabase) {
            console.warn("Signify: Supabase not initialized");
            return null;
        }
        
        // Query for specific word animation
        const { data, error } = await supabase
            .from('animations')
            .select('animation_file, file_url')
            .eq('word', word.toLowerCase())
            .single();
        
        if (error) {
            console.log(`Signify: No animation found for word "${word}":`, error.message);
            return null;
        }
        
        if (data && data.file_url) {
            console.log(`Signify: Animation URL loaded for word "${word}"`);
            return data.file_url;
        } else if (data && data.animation_file) {
            console.log(`Signify: Animation binary data loaded for word "${word}"`);
            return data.animation_file;
        }
        
        return null;
    } catch (error) {
        console.error(`Signify: Error loading animation for word "${word}":`, error);
        return null;
    }
}

// --- UTILITY FUNCTIONS ---
function playWordAnimation(word) {
    if (window.signifyAvatar && window.signifyAvatar.playWordAnimation) {
        window.signifyAvatar.playWordAnimation(word);
    } else {
        console.log(`Signify: Avatar not ready for animation: ${word}`);
    }
}

function loadThreeJS() {
    return new Promise((resolve) => {
        console.log('Signify: loadThreeJS called');
        
        if (window.THREE && window.THREE.GLTFLoader) {
            console.log('Signify: THREE.js and GLTFLoader already loaded');
            resolve();
            return;
        }
        
        // Try to load THREE.js using a different method
        console.log('Signify: Loading THREE.js using script injection...');
        
        // First, let's test if we can access the file at all
        const threeUrl = chrome.runtime.getURL('three.min.js');
        console.log('Signify: THREE.js URL:', threeUrl);
        
        // Create script element
        const script = document.createElement('script');
        script.type = 'text/javascript';
        script.async = false;
        script.src = threeUrl;
        
        script.onload = function() {
            console.log('Signify: THREE.js script onload fired');
            console.log('Signify: window.THREE after load:', typeof window.THREE);
            
            if (window.THREE) {
                console.log('Signify: THREE.js loaded successfully');
                // Now load GLTFLoader
                loadGLTFLoader().then(resolve);
            } else {
                console.error('Signify: THREE.js script loaded but window.THREE is undefined');
                resolve(); // Continue anyway to show error
            }
        };
        
        script.onerror = function(event) {
            console.error('Signify: Failed to load THREE.js script:', event);
            console.error('Signify: Script src was:', script.src);
            resolve(); // Continue anyway to show error
        };
        
        // Try to inject into head
        try {
            document.head.appendChild(script);
            console.log('Signify: THREE.js script injected into head');
        } catch (error) {
            console.error('Signify: Failed to inject script:', error);
            resolve();
        }
    });
}

function loadGLTFLoader() {
    return new Promise((resolve) => {
        const loaderUrl = chrome.runtime.getURL('GLTFLoader.js');
        console.log('Signify: GLTFLoader URL:', loaderUrl);
        
        const script = document.createElement('script');
        script.type = 'text/javascript';
        script.async = false;
        script.src = loaderUrl;
        
        script.onload = function() {
            console.log('Signify: GLTFLoader script loaded');
            console.log('Signify: THREE.GLTFLoader available:', typeof window.THREE?.GLTFLoader);
            resolve();
        };
        
        script.onerror = function(event) {
            console.error('Signify: Failed to load GLTFLoader:', event);
            resolve(); // Continue anyway
        };
        
        document.head.appendChild(script);
    });
}

// Alternative method to load THREE.js if direct file access fails
function loadThreeJSAlternative() {
    return new Promise((resolve, reject) => {
        console.log('Signify: Trying alternative THREE.js loading...');
        
        // Try loading from CDN as backup
        console.log('Signify: Trying CDN fallback...');
        loadThreeJSFromCDN().then(resolve).catch(reject);
    });
}

// Last resort: Load from CDN (will only work if CSP allows it)
function loadThreeJSFromCDN() {
    return new Promise((resolve, reject) => {
        console.log('Signify: Loading THREE.js from CDN as last resort...');
        
        const script = document.createElement('script');
        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
        script.onload = () => {
            if (window.THREE) {
                console.log('Signify: THREE.js loaded from CDN');
                resolve();
            } else {
                reject(new Error('THREE.js not available after CDN loading'));
            }
        };
        script.onerror = () => reject(new Error('Failed to load THREE.js from CDN'));
        document.head.appendChild(script);
    });
}

function loadScript(src) {
    return new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = src;
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });
}

function createSignifyButton() {
    const oldBtn = document.getElementById('signify-toggle-btn');
    if (oldBtn) {
        oldBtn.remove();
    }

    const controls = document.querySelector('.ytp-right-controls');
    if (!controls) {
        console.log("Signify: YouTube controls not found, will retry...");
        setTimeout(createSignifyButton, 1000);
        return;
    }

    console.log("Signify: Injecting button into YouTube player controls.");

    const signifyBtn = document.createElement('button');
    signifyBtn.id = 'signify-toggle-btn';
    signifyBtn.className = 'ytp-button';
    signifyBtn.title = 'Translate to ISL (Signify)';

    signifyBtn.innerHTML = `
        <svg height="100%" width="100%" viewBox="0 0 36 36" fill="currentColor">
            <text
                x="50%"
                y="50%"
                dominant-baseline="central"
                text-anchor="middle"
                font-size="12px"
                font-weight="bold"
                fill="currentColor">
                ISL
            </text>
        </svg>
    `;
    
    signifyBtn.addEventListener('click', () => {
        console.log("Signify button was clicked.");
        showAvatarInterface();
        extractTranscriptAndStart();
    });

    controls.prepend(signifyBtn);
    console.log("Signify button successfully added to the player.");
}

function observeVideoChanges() {
    let lastHref = location.href;
    new MutationObserver(() => {
        if (location.href !== lastHref) {
            lastHref = location.href;
            console.log(`Signify: URL changed to ${lastHref}. Resetting everything.`);

            const avatarContainer = document.getElementById('signify-avatar-container');
            if (avatarContainer) avatarContainer.remove();
            
            resetTranslation();
            transcriptData = [];
            animationCache.clear();
            userManuallyClosed = false;
            
            setTimeout(() => {
                initializeSignify();
            }, 2000);
        }
    }).observe(document.body, { childList: true, subtree: true });
}

// Listen for storage changes
chrome.storage.onChanged.addListener((changes, namespace) => {
    if (changes.signifyEnabled && changes.signifyEnabled.newValue === false) {
        console.log("Signify: Extension disabled, cleaning up...");
        resetTranslation();
        
        const container = document.getElementById('signify-avatar-container');
        if (container) {
            container.style.display = 'none';
        }
        
        isSignifyActive = false;
    } else if (changes.signifyEnabled && changes.signifyEnabled.newValue === true) {
        console.log("Signify: Extension enabled");
        isSignifyActive = true;
    }
});

// Listen for messages from background script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    switch (request.action) {
        case 'toggleSignify':
            if (isSignifyActive) {
                hideAvatarInterface();
            } else {
                showAvatarInterface();
                extractTranscriptAndStart();
            }
            break;
            
        case 'translateText':
            if (request.text) {
                updateCurrentWord(request.text);
                playWordAnimation(request.text);
            }
            break;
    }
});