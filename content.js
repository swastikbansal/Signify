// Signify ISL Translator - Content Script (Final Version with Updated Selectors)

let isSignifyActive = false;
let transcriptData = [];
let translationActive = false;
let lastSyncedWord = '';
let currentWordIndex = 0;
let wordTimeout = null;
let currentAnimation = null;
let userManuallyClosed = false;
const API_BASE_URL = "https://your-api-domain.com/api"; // Replace with your actual API URL
const animationCache = new Map();

// --- UTILITY FUNCTIONS ---

/**
 * Waits for a specific element to appear in the DOM.
 * @param {string} selector - The CSS selector of the element to wait for.
 * @param {number} timeout - The maximum time to wait in milliseconds.
 * @returns {Promise<Element>} A promise that resolves with the element or rejects if timed out.
 */
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

function initializeSignify() {
    console.log("Signify ISL Translator initializing...");
    
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


// --- VIDEO AND UI EVENT LISTENERS ---

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
    
    // Return to default animation when video is paused
    if (window.signifyFloatingAvatar && window.signifyFloatingAvatar.setIdlePose) {
        window.signifyFloatingAvatar.setIdlePose();
        console.log("Signify: Video paused, returning to default animation");
    }
}

function handleVideoPlay() {
    setTimeout(() => {
        chrome.storage.sync.get(['signifyEnabled', 'autoStart'], (settings) => {
            if (settings.signifyEnabled === false) {
                return;
            }

            const isAvatarVisible = !!document.getElementById('signify-floating-avatar');

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
                showFloatingAvatar();
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


// --- CORE TRANSCRIPT EXTRACTION LOGIC (REVISED) ---

async function extractTranscriptAndStart() {
    if (transcriptData.length > 0) {
        console.log("Signify: Transcript already loaded. Starting translation.");
        startTranslation();
        return;
    }
    
    console.log("Signify: Starting transcript extraction process...");
    
    // First, let's check if transcript is even available
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
        // Step 1: Click "Show transcript" (using exact same approach as reference)
        const transcriptButton = await waitForElement('button[aria-label="Show transcript"]');
        transcriptButton.click();

        // Step 2: Wait for transcript segments and extract text (exact same as reference)
        console.log("Signify: Reading transcript...");
        await waitForElement('ytd-transcript-segment-renderer');
        
        // Extract segments with REAL timestamps for proper sync
        const segments = document.querySelectorAll('ytd-transcript-segment-renderer');
        console.log(`Signify: Found ${segments.length} transcript segments`);
        
        if (segments.length === 0) {
            throw new Error("No transcript segments found");
        }

        // Parse segments with actual timestamps
        transcriptData = [];
        segments.forEach((segment, index) => {
            const timeEl = segment.querySelector('.segment-timestamp');
            const textEl = segment.querySelector('.segment-text');
            
            if (timeEl && textEl) {
                const timeText = timeEl.textContent.trim();
                const segmentText = textEl.textContent.trim();
                const startTime = parseTimeToSeconds(timeText);
                
                if (segmentText && segmentText.length > 0) {
                    // Get the next segment's start time for better duration calculation
                    let nextStartTime = startTime + 5.0; // Default 5 seconds if no next segment
                    if (index < segments.length - 1) {
                        const nextTimeEl = segments[index + 1].querySelector('.segment-timestamp');
                        if (nextTimeEl) {
                            nextStartTime = parseTimeToSeconds(nextTimeEl.textContent.trim());
                        }
                    }
                    
                    const segmentDuration = nextStartTime - startTime;
                    const words = segmentText.split(/\s+/).filter(Boolean);
                    const wordDuration = Math.max(0.3, segmentDuration / words.length); // Minimum 0.3 seconds per word
                    
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
        
        // Debug: Show timing distribution
        if (transcriptData.length > 0) {
            const totalDuration = transcriptData[transcriptData.length - 1].endTime;
            const avgWordDuration = totalDuration / transcriptData.length;
            console.log(`Signify: Timing info - Total: ${totalDuration.toFixed(1)}s, Avg per word: ${avgWordDuration.toFixed(2)}s`);
            
            // Show first 10 words with timing
            console.log("Signify: First 10 words timing:");
            transcriptData.slice(0, 10).forEach((word, i) => {
                console.log(`  ${i+1}. "${word.originalText}" -> ${word.startTime.toFixed(2)}-${word.endTime.toFixed(2)}s`);
            });
        }
        
        if (transcriptData.length > 0) {
            console.log(`Signify: Successfully converted to ${transcriptData.length} words.`);
            
            // Step 3: Close transcript panel (cleanup)
            try {
                const closeButton = await waitForElement('button[aria-label="Close transcript"]', 2000);
                closeButton.click();
            } catch (error) {
                console.log("Signify: Could not find close transcript button, continuing...");
            }
            
            return true;
        } else {
            throw new Error("Could not convert transcript to timed words");
        }
        
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

function convertFullTranscriptToTimedWords(fullTranscript) {
    if (!fullTranscript || fullTranscript.trim() === '') return;
    
    const words = fullTranscript.split(/\s+/).filter(Boolean);
    const avgWordDuration = 0.8; // Duration per word for better sync
    
    transcriptData = [];
    words.forEach((word, index) => {
        const cleanedWord = word.toLowerCase().replace(/[^\w\s'-]/g, '');
        if (cleanedWord) {
            const wordStartTime = index * avgWordDuration;
            const wordEndTime = (index + 1) * avgWordDuration;
            
            transcriptData.push({
                word: cleanedWord,
                startTime: wordStartTime,
                endTime: wordEndTime,
                originalText: word // Keep original for display purposes
            });
        }
    });
    
    console.log(`Signify: Converted ${words.length} words from transcript into ${transcriptData.length} timed entries`);
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


// --- TRANSLATION AND SYNC LOGIC ---

function startTranslation() {
    const video = document.querySelector('video');
    if (!video || transcriptData.length === 0) {
        console.log("Signify: No video or transcript available");
        return;
    }
    
    translationActive = true;
    console.log("Signify: Starting translation sync.");
    
    // Debug: Show current video time and some transcript samples
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
    // Don't clear the interval immediately - let it handle the pause state
    console.log(`Signify: Translation paused at word index ${currentWordIndex}`);
    
    // Return to default animation when paused
    if (window.signifyFloatingAvatar && window.signifyFloatingAvatar.setIdlePose) {
        window.signifyFloatingAvatar.setIdlePose();
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

            syncWithVideo(video);
        }
    }
}

function resetTranslation() {
    translationActive = false;
    currentWordIndex = 0;
    
    // Clear all intervals and timeouts
    if (window.syncInterval) {
        clearInterval(window.syncInterval);
        window.syncInterval = null;
    }
    if (wordTimeout) {
        clearTimeout(wordTimeout);
        wordTimeout = null;
    }
    
    // Reset avatar to default idle animation
    updateFloatingCurrentWord('Ready');
    if (window.signifyFloatingAvatar && window.signifyFloatingAvatar.setIdlePose) {
        window.signifyFloatingAvatar.setIdlePose();
        console.log("Signify: Reset to default.glb animation");
    }
    
    // Stop any current animations
    if (currentAnimation) {
        currentAnimation.stop();
        currentAnimation = null;
    }
    
    console.log("Signify: Translation reset and cleaned up");
}

function syncWithVideo(video) {
    if (window.syncInterval) clearInterval(window.syncInterval);

    console.log(`Signify: Starting sync with ${transcriptData.length} words`);
    
    // Show the first few words for debugging
    if (transcriptData.length > 0) {
        const firstWords = transcriptData.slice(0, 5).map(w => `"${w.originalText}"(${w.startTime.toFixed(1)}s)`).join(', ');
        console.log(`Signify: First words: ${firstWords}`);
        console.log(`Signify: Starting sync from currentWordIndex: ${currentWordIndex}`);
    }

    window.syncInterval = setInterval(() => {
        if (!translationActive || video.paused) {
            // Don't clear the interval when paused, just skip processing
            return;
        }

        const currentTime = video.currentTime;
        
        // Find the current word based on video time - more accurate approach
        let foundWord = null;
        let closestIndex = -1;
        let minTimeDiff = Infinity;
        
        // Look for exact time match first
        for (let i = 0; i < transcriptData.length; i++) {
            const word = transcriptData[i];
            if (currentTime >= word.startTime && currentTime <= word.endTime) {
                foundWord = word;
                closestIndex = i;
                break;
            }
        }
        
        // If no exact match, find the closest word (either current or upcoming)
        if (!foundWord) {
            for (let i = 0; i < transcriptData.length; i++) {
                const word = transcriptData[i];
                const timeDiff = Math.abs(currentTime - word.startTime);
                if (timeDiff < minTimeDiff && currentTime <= word.endTime + 0.5) { // Allow 0.5s buffer
                    minTimeDiff = timeDiff;
                    foundWord = word;
                    closestIndex = i;
                }
            }
        }

        if (foundWord && foundWord.word !== lastSyncedWord) {
            lastSyncedWord = foundWord.word;
            currentWordIndex = closestIndex;
            
            // Display original text for better readability
            const displayWord = foundWord.originalText || foundWord.word;
            updateFloatingCurrentWord(displayWord);
            playWordAnimation(foundWord.word);
            
            console.log(`Signify: [${currentTime.toFixed(2)}s] Word "${displayWord}" (expected: ${foundWord.startTime.toFixed(2)}-${foundWord.endTime.toFixed(2)}s, diff: ${Math.abs(currentTime - foundWord.startTime).toFixed(2)}s)`);
            
        } else if (!foundWord && lastSyncedWord !== '') {
            // Only clear display if we're significantly past all words
            const lastWord = transcriptData[transcriptData.length - 1];
            if (currentTime > lastWord.endTime + 1.0) { // 1 second buffer after last word
                lastSyncedWord = '';
                updateFloatingCurrentWord('...');
                // Return to default animation when no words are found
                if (window.signifyFloatingAvatar && window.signifyFloatingAvatar.setIdlePose) {
                    window.signifyFloatingAvatar.setIdlePose();
                }
                console.log(`Signify: [${currentTime.toFixed(2)}s] Past all transcript words`);
            }
        }
    }, 100); // Sync every 100ms for better accuracy
}


// --- FLOATING AVATAR AND UI FUNCTIONS ---
// (These functions are unchanged, place your existing avatar and UI code here)

function showFloatingAvatar() {
    if (document.getElementById('signify-floating-avatar')) return;
    
    // Add CSS styles first
    if (!document.getElementById('signify-styles')) {
        const style = document.createElement('style');
        style.id = 'signify-styles';
        style.textContent = `
            #signify-floating-avatar {
                position: fixed !important;
                top: 80px !important;
                right: 20px !important;
                width: 220px !important;
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%) !important;
                border: 2px solid #FFD700 !important;
                border-radius: 12px !important;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 215, 0, 0.2) !important;
                z-index: 2147483647 !important;
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif !important;
                backdrop-filter: blur(10px) !important;
                transition: all 0.3s ease !important;
                box-sizing: border-box;
            }
            
            #signify-floating-avatar * {
                box-sizing: border-box;
            }
            
            .floating-avatar-header {
                background: linear-gradient(90deg, #FFD700, #FFA500) !important;
                color: #000 !important;
                padding: 8px 12px !important;
                border-radius: 10px 10px 0 0 !important;
                display: flex !important;
                justify-content: space-between !important;
                align-items: center !important;
                cursor: move !important;
                font-weight: bold !important;
                font-size: 12px !important;
            }
            
            .avatar-title span {
                font-size: 13px !important;
                font-weight: bold !important;
                text-shadow: 1px 1px 2px rgba(0,0,0,0.3) !important;
            }
            
            .avatar-controls {
                display: flex !important;
                gap: 4px !important;
            }
            
            .avatar-control-btn {
                background: rgba(0,0,0,0.2) !important;
                border: none !important;
                color: #000 !important;
                width: 20px !important;
                height: 20px !important;
                border-radius: 3px !important;
                cursor: pointer !important;
                font-size: 12px !important;
                font-weight: bold !important;
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
                transition: all 0.2s ease !important;
            }
            
            .avatar-control-btn:hover {
                background: rgba(0,0,0,0.4) !important;
                transform: scale(1.1) !important;
            }
            
            .floating-avatar-content {
                padding: 12px !important;
                background: rgba(255, 255, 255, 0.05) !important;
                border-radius: 0 0 10px 10px !important;
            }
            
            .floating-avatar-display {
                width: 200px !important;
                height: 150px !important;
                background: radial-gradient(circle, rgba(255,215,0,0.1) 0%, rgba(0,0,0,0.3) 100%) !important;
                border: 1px solid rgba(255, 215, 0, 0.3) !important;
                border-radius: 8px !important;
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
                margin-bottom: 10px !important;
                overflow: hidden !important;
                position: relative !important;
            }
            
            .floating-avatar-canvas {
                width: 100% !important;
                height: 100% !important;
                border-radius: 8px !important;
            }
            
            /* Resize handle styles */
            .signify-resize-handle {
                position: absolute !important;
                bottom: 0 !important;
                right: 0 !important;
                width: 20px !important;
                height: 20px !important;
                background: linear-gradient(135deg, transparent 0%, transparent 30%, #FFD700 30%, #FFD700 70%, transparent 70%) !important;
                cursor: nw-resize !important;
                z-index: 1000 !important;
                border-radius: 0 0 10px 0 !important;
            }
            
            .signify-resize-handle::after {
                content: '⋰' !important;
                position: absolute !important;
                bottom: 2px !important;
                right: 2px !important;
                color: #FFD700 !important;
                font-size: 12px !important;
                line-height: 1 !important;
            }
            
            .avatar-loading {
                color: #FFD700 !important;
                font-size: 12px !important;
                text-align: center !important;
                animation: pulse 2s infinite !important;
            }
            
            .avatar-info {
                color: #fff !important;
            }
            
            .floating-current-word {
                background: rgba(255, 215, 0, 0.1) !important;
                border: 1px solid rgba(255, 215, 0, 0.3) !important;
                border-radius: 6px !important;
                padding: 6px 10px !important;
                text-align: center !important;
                font-size: 14px !important;
                font-weight: bold !important;
                color: #FFD700 !important;
                margin-bottom: 0px !important;
                min-height: 20px !important;
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
            }
            
            @keyframes pulse {
                0%, 100% { opacity: 1; }
                50% { opacity: 0.5; }
            }
            
            @keyframes wordPulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.05); }
                100% { transform: scale(1); }
            }
        `;
        document.head.appendChild(style);
    }
    
    const floatingAvatar = document.createElement('div');
    floatingAvatar.id = 'signify-floating-avatar';
    floatingAvatar.innerHTML = `
      <div class="floating-avatar-header">
        <div class="avatar-title"><span>Signify ISL</span></div>
        <div class="avatar-controls"><button id="avatar-minimize" class="avatar-control-btn" title="Minimize">−</button><button id="avatar-close" class="avatar-control-btn" title="Close">✕</button></div>
      </div>
      <div class="floating-avatar-content" id="floatingAvatarContent">
        <div id="floating-avatar-container" class="floating-avatar-display"><div class="avatar-loading">Loading Avatar...</div></div>
        <div class="avatar-info">
          <div id="floating-current-word" class="floating-current-word">Ready</div>
        </div>
      </div>
      <div class="signify-resize-handle" id="signifyResizeHandle"></div>`;
    document.body.appendChild(floatingAvatar);
    
    document.getElementById('avatar-close').addEventListener('click', hideFloatingAvatar);
    document.getElementById('avatar-minimize').addEventListener('click', toggleFloatingAvatar);
    makeAvatarDraggable(floatingAvatar);
    makeAvatarResizable(floatingAvatar);
    initializeFloatingAvatar();
    isSignifyActive = true;
    
    console.log("Signify: Floating avatar window created and styled");
}

function makeAvatarResizable(element) {
    const resizeHandle = element.querySelector('#signifyResizeHandle');
    let isResizing = false;
    let originalWidth = 0, originalHeight = 0, originalMouseX = 0, originalMouseY = 0;

    resizeHandle.addEventListener('mousedown', (e) => {
        e.preventDefault();
        e.stopPropagation(); // Prevent dragging when resizing
        isResizing = true;

        const rect = element.getBoundingClientRect();
        originalWidth = rect.width;
        originalHeight = rect.height;
        originalMouseX = e.clientX;
        originalMouseY = e.clientY;

        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
        
        // Add visual feedback
        element.style.userSelect = 'none';
        document.body.style.cursor = 'nw-resize';
    });

    function handleMouseMove(e) {
        if (!isResizing) return;
        
        const deltaX = e.clientX - originalMouseX;
        const deltaY = e.clientY - originalMouseY;
        
        const newWidth = Math.max(250, originalWidth + deltaX); // Minimum 250px width
        const newHeight = Math.max(200, originalHeight + deltaY); // Minimum 200px height

        element.style.width = newWidth + 'px';
        element.style.height = newHeight + 'px';
        
        // Update the avatar display size proportionally
        const avatarDisplay = element.querySelector('.floating-avatar-display');
        if (avatarDisplay) {
            const contentPadding = 24; // 12px padding on each side
            const headerHeight = 40; // Approximate header height
            const wordDisplayHeight = 40; // Height of current word display
            const availableWidth = newWidth - contentPadding;
            const availableHeight = newHeight - headerHeight - wordDisplayHeight - contentPadding;
            
            avatarDisplay.style.width = Math.max(180, availableWidth) + 'px';
            avatarDisplay.style.height = Math.max(120, availableHeight) + 'px';
        }
        
        // Update Three.js renderer if it exists
        if (window.signifyFloatingAvatar && window.signifyFloatingAvatar.renderer) {
            const newDisplayWidth = parseInt(avatarDisplay.style.width);
            const newDisplayHeight = parseInt(avatarDisplay.style.height);
            
            window.signifyFloatingAvatar.renderer.setSize(newDisplayWidth, newDisplayHeight);
            if (window.signifyFloatingAvatar.camera) {
                window.signifyFloatingAvatar.camera.aspect = newDisplayWidth / newDisplayHeight;
                window.signifyFloatingAvatar.camera.updateProjectionMatrix();
            }
        }
    }

    function handleMouseUp() {
        isResizing = false;
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
        
        // Remove visual feedback
        element.style.userSelect = '';
        document.body.style.cursor = '';
    }
}

function hideFloatingAvatar() {
    const floatingAvatar = document.getElementById('signify-floating-avatar');
    if (floatingAvatar) {
        floatingAvatar.remove();
    }
    isSignifyActive = false;
    userManuallyClosed = true; // User has explicitly closed the window
    resetTranslation(); // Fully reset the translation state
}

function toggleFloatingAvatar() {
    const content = document.getElementById('floatingAvatarContent');
    const minimizeBtn = document.getElementById('avatar-minimize');
    if (content.style.display === 'none') {
        content.style.display = 'block';
        minimizeBtn.textContent = '−';
    } else {
        content.style.display = 'none';
        minimizeBtn.textContent = '□';
    }
}

function makeAvatarDraggable(element) {
    let isDragging = false, startX, startY, initialX, initialY;
    const header = element.querySelector('.floating-avatar-header');
    header.addEventListener('mousedown', (e) => {
        if (e.target.classList.contains('avatar-control-btn')) return;
        isDragging = true;
        startX = e.clientX;
        startY = e.clientY;
        const rect = element.getBoundingClientRect();
        initialX = rect.left;
        initialY = rect.top;
        element.style.cursor = 'grabbing';
    });
    document.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        e.preventDefault();
        element.style.left = (initialX + e.clientX - startX) + 'px';
        element.style.top = (initialY + e.clientY - startY) + 'px';
    });
    document.addEventListener('mouseup', () => {
        isDragging = false;
        element.style.cursor = 'default';
    });
}

function createSignifyButton() {
    // First, remove any old button to prevent duplicates on redraw
    const oldBtn = document.getElementById('signify-toggle-btn');
    if (oldBtn) {
        oldBtn.remove();
    }

    // This is the correct container for the right-side player controls
    const controls = document.querySelector('.ytp-right-controls');
    if (!controls) {
        console.log("Signify: YouTube controls not found, will retry...");
        setTimeout(createSignifyButton, 1000); // Retry if controls aren't loaded yet
        return;
    }

    console.log("Signify: Injecting button into YouTube player controls.");

    const signifyBtn = document.createElement('button');
    signifyBtn.id = 'signify-toggle-btn';

    // *** KEY CHANGE ***
    // We add YouTube's own "ytp-button" class.
    // This makes our button inherit all the basic styling, alignment, and behavior
    // of the native YouTube buttons, ensuring it doesn't break the layout.
    signifyBtn.className = 'ytp-button';
    signifyBtn.title = 'Translate to ISL (Signify)';

    // A cleaner, self-contained SVG icon designed to fit perfectly.
    // It uses "currentColor" to match YouTube's light/dark theme automatically.
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
    
    // Add the click functionality
    signifyBtn.addEventListener('click', () => {
        console.log("Signify button was clicked.");
        showFloatingAvatar();
        extractTranscriptAndStart();
    });

    // *** KEY CHANGE ***
    // Use .prepend() to add our button as the very first item
    // in the right-side controls, without removing anything else.
    controls.prepend(signifyBtn);

    console.log("Signify button successfully added to the player.");
}

function initializeFloatingAvatar() {
    const container = document.getElementById('floating-avatar-container');
    if (!container) return;
    loadThreeJS().then(() => createFloatingAvatar(container));
}

function createFloatingAvatar(container) {
    container.innerHTML = '';
    
    // Create Three.js scene
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x1a1a2e);
    
    // Create camera
    const camera = new THREE.PerspectiveCamera(75, 200 / 150, 0.1, 1000);
    camera.position.set(0, 1, 3);
    
    // Create renderer
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(200, 150);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.domElement.className = 'floating-avatar-canvas';
    container.appendChild(renderer.domElement);
    
    // Add lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(5, 10, 5);
    directionalLight.castShadow = true;
    scene.add(directionalLight);
    
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
            model.rotation.y += 0.005;
        }
        
        renderer.render(scene, camera);
    }
    animate();
    
    // Load the default animation model
    const loader = new THREE.GLTFLoader();
    const defaultModelPath = chrome.runtime.getURL('animation/default.glb');
    
    console.log("Signify: Loading default animation from:", defaultModelPath);
    console.log("Signify: THREE.js version:", THREE.REVISION);
    console.log("Signify: GLTFLoader available:", !!THREE.GLTFLoader);
    
    loader.load(
        defaultModelPath,
        (gltf) => {
            console.log("Signify: Default animation model loaded successfully");
            console.log("Signify: GLTF object:", gltf);
            console.log("Signify: Animations found:", gltf.animations?.length || 0);
            
            model = gltf.scene;
            scene.add(model);
            
            // Center and scale the model
            const box = new THREE.Box3().setFromObject(model);
            const center = box.getCenter(new THREE.Vector3());
            model.position.sub(center);
            
            const size = box.getSize(new THREE.Vector3());
            const maxSize = Math.max(size.x, size.y, size.z);
            console.log("Signify: Model size:", size, "Max:", maxSize);
            
            if (maxSize > 2) {
                const scale = 2 / maxSize;
                model.scale.multiplyScalar(scale);
                console.log("Signify: Model scaled by:", scale);
            }
            
            // Setup animations
            if (gltf.animations && gltf.animations.length > 0) {
                mixer = new THREE.AnimationMixer(model);
                defaultAnimation = gltf.animations[0];
                
                console.log(`Signify: Found ${gltf.animations.length} animations in default.glb`);
                console.log("Signify: Default animation duration:", defaultAnimation.duration);
                console.log("Signify: Default animation tracks:", defaultAnimation.tracks.length);
                
                // Create default action
                currentAction = mixer.clipAction(defaultAnimation);
                currentAction.loop = THREE.LoopRepeat;
                currentAction.play();
                isPlaying = true;
                
                console.log("Signify: Default animation started successfully");
            } else {
                console.warn("Signify: No animations found in default.glb");
            }
            
            // Setup avatar control interface
            setupAvatarControls();
        },
        (progress) => {
            const percentage = (progress.loaded / progress.total) * 100;
            console.log(`Signify: Loading progress: ${Math.round(percentage)}%`);
        },
        (error) => {
            console.error('Signify: Error loading default animation:', error);
            console.error('Signify: Error details:', {
                message: error.message,
                stack: error.stack,
                modelPath: defaultModelPath
            });
            container.innerHTML = '<div class="avatar-loading" style="color: #ff6b6b;">❌ Animation failed to load<br><small>Check browser console for details</small></div>';
        }
    );
    
    function setupAvatarControls() {
        // Global avatar interface
        window.signifyFloatingAvatar = {
            mixer: mixer,
            model: model,
            defaultAnimation: defaultAnimation,
            currentAction: currentAction,
            isPlaying: isPlaying,
            renderer: renderer,  // Add renderer reference
            camera: camera,      // Add camera reference
            scene: scene,        // Add scene reference
            
            // Set to default/idle animation
            setIdlePose: () => {
                console.log("Signify: Setting idle pose - playing default animation");
                
                if (!mixer || !defaultAnimation) {
                    console.warn("Signify: No mixer or default animation available");
                    return;
                }
                
                try {
                    // Stop all current actions
                    mixer.stopAllAction();
                    
                    // Reset and play default animation
                    currentAction = mixer.clipAction(defaultAnimation);
                    currentAction.reset();
                    currentAction.setLoop(THREE.LoopRepeat);
                    currentAction.setEffectiveWeight(1.0);
                    currentAction.play();
                    
                    isPlaying = true;
                    window.signifyFloatingAvatar.currentAction = currentAction;
                    window.signifyFloatingAvatar.isPlaying = isPlaying;
                    
                    console.log("Signify: Default animation playing");
                } catch (error) {
                    console.error("Signify: Error playing default animation:", error);
                }
            },
            
            // Play animation for a specific word
            playWordAnimation: async (word) => {
                const cleanWord = word.toLowerCase().replace(/[^\w]/g, '');
                if (!cleanWord) {
                    window.signifyFloatingAvatar.setIdlePose();
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
                        window.signifyFloatingAvatar.setIdlePose();
                    }
                    return;
                }
                
                // Try to load word-specific animation
                try {
                    const wordModelPath = chrome.runtime.getURL(`animation/${cleanWord}.glb`);
                    const gltf = await loader.loadAsync(wordModelPath);
                    
                    if (gltf.animations && gltf.animations.length > 0) {
                        const wordClip = gltf.animations[0];
                        animationCache.set(cleanWord, wordClip);
                        console.log(`Signify: Loaded and playing animation for "${cleanWord}"`);
                        playAnimationClip(wordClip);
                    } else {
                        console.log(`Signify: No animations in ${cleanWord}.glb, using default`);
                        animationCache.set(cleanWord, null);
                        window.signifyFloatingAvatar.setIdlePose();
                    }
                } catch (error) {
                    console.log(`Signify: Could not load animation for "${cleanWord}", using default`);
                    animationCache.set(cleanWord, null);
                    window.signifyFloatingAvatar.setIdlePose();
                }
            }
        };
        
        // Function to play a specific animation clip
        function playAnimationClip(clip) {
            if (!mixer || !clip) return;
            
            try {
                // Stop current actions
                mixer.stopAllAction();
                
                // Play the word animation
                const action = mixer.clipAction(clip);
                action.reset();
                action.setLoop(THREE.LoopOnce, 1);
                action.clampWhenFinished = true;
                action.play();
                
                currentAction = action;
                isPlaying = true;
                
                // Return to default animation when finished
                mixer.removeEventListener('finished', returnToDefault);
                mixer.addEventListener('finished', returnToDefault);
                
            } catch (error) {
                console.error("Signify: Error playing animation clip:", error);
                window.signifyFloatingAvatar.setIdlePose();
            }
        }
        
        // Return to default animation when word animation finishes
        function returnToDefault() {
            console.log("Signify: Word animation finished, returning to default");
            setTimeout(() => {
                if (window.signifyFloatingAvatar) {
                    window.signifyFloatingAvatar.setIdlePose();
                }
            }, 100);
        }
        
        console.log("Signify: Avatar controls setup completed");
        
        // Start with default animation
        setTimeout(() => {
            if (window.signifyFloatingAvatar) {
                window.signifyFloatingAvatar.setIdlePose();
            }
        }, 500);
    }
    
    // Handle window resize
    window.addEventListener('resize', () => {
        if (camera && renderer) {
            camera.aspect = 200 / 150;
            camera.updateProjectionMatrix();
            renderer.setSize(200, 150);
        }
    });
}

function playWordAnimation(word) {
    if (window.signifyFloatingAvatar && window.signifyFloatingAvatar.playWordAnimation) {
        window.signifyFloatingAvatar.playWordAnimation(word);
    } else {
        console.log(`Signify: Avatar not ready for animation: ${word}`);
    }
}

function updateFloatingCurrentWord(word) {
    const el = document.getElementById('floating-current-word');
    if (el) {
        el.textContent = word || '...';
        if (word) {
            el.style.animation = 'none';
            setTimeout(() => { el.style.animation = 'wordPulse 0.5s ease-out'; }, 10);
        }
    }
}

function loadThreeJS() {
    return new Promise((resolve) => {
        if (window.THREE && window.THREE.GLTFLoader) {
            resolve();
            return;
        }
        
        if (window.THREE) {
            // THREE.js is loaded, now load GLTFLoader
            loadScript('GLTFLoader.js').then(() => {
                // Ensure GLTFLoader is properly attached to THREE
                if (!window.THREE.GLTFLoader && window.GLTFLoader) {
                    window.THREE.GLTFLoader = window.GLTFLoader;
                }
                resolve();
            });
            return;
        }
        
        // Load THREE.js first
        const script = document.createElement('script');
        script.src = chrome.runtime.getURL('three.min.js');
        script.onload = () => {
            // Then load GLTFLoader
            loadScript('GLTFLoader.js').then(() => {
                // Ensure GLTFLoader is properly attached to THREE
                if (!window.THREE.GLTFLoader && window.GLTFLoader) {
                    window.THREE.GLTFLoader = window.GLTFLoader;
                }
                resolve();
            });
        };
        script.onerror = () => {
            console.error('Signify: Failed to load THREE.js');
            resolve(); // Resolve anyway to prevent hanging
        };
        document.head.appendChild(script);
    });
}

function loadScript(src) {
    return new Promise((resolve) => {
        const script = document.createElement('script');
        script.src = chrome.runtime.getURL(src);
        script.onload = resolve;
        document.head.appendChild(script);
    });
}

function observeVideoChanges() {
    let lastHref = location.href;
    new MutationObserver(() => {
        if (location.href !== lastHref) {
            lastHref = location.href;
            console.log(`Signify: URL changed to ${lastHref}. Resetting everything.`);

            // Hide the avatar if it exists
            const floatingAvatar = document.getElementById('signify-floating-avatar');
            if (floatingAvatar) floatingAvatar.remove();
            
            // Fully reset state for the new page
            resetTranslation();
            transcriptData = [];
            animationCache.clear();
            userManuallyClosed = false; // Reset the manual close flag for the new video
            
            // Re-initialize for the new video page
            setTimeout(() => {
                initializeSignify();
            }, 2000); // Wait a bit for the new page to load
        }
    }).observe(document.body, { childList: true, subtree: true });
}

// Listen for storage changes to handle extension being disabled
chrome.storage.onChanged.addListener((changes, namespace) => {
    if (changes.signifyEnabled && changes.signifyEnabled.newValue === false) {
        console.log("Signify: Extension disabled, cleaning up...");
        resetTranslation();
        
        // Hide floating avatar
        const floating = document.getElementById('signify-floating-avatar');
        if (floating) {
            floating.style.display = 'none';
        }
        
        // Clean up global variables
        isSignifyActive = false;
    } else if (changes.signifyEnabled && changes.signifyEnabled.newValue === true) {
        console.log("Signify: Extension enabled");
        isSignifyActive = true;
    }
});