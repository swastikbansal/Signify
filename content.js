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
    updateFloatingStatus("1/3: Initializing...");
    
    // First, let's check if transcript is even available
    const hasTranscriptButton = document.querySelector('button[aria-label*="transcript"], button[aria-label*="Transcript"]');
    if (!hasTranscriptButton) {
        console.log("Signify: No transcript button found. Video may not have captions.");
        updateFloatingStatus("No captions available");
        generateBasicTranscription();
        startTranslation();
        return;
    }
    
    await extractTranscript();
    startTranslation();
}

async function extractTranscript() {
    console.log("Signify: Starting transcript extraction...");
    updateFloatingStatus("2/3: Clicking 'Show transcript'...");
    transcriptData = [];

    try {
        // Step 1: Click "Show transcript" (using exact same approach as reference)
        const transcriptButton = await waitForElement('button[aria-label="Show transcript"]');
        transcriptButton.click();

        // Step 2: Wait for transcript segments and extract text (exact same as reference)
        console.log("Signify: 3/3: Reading transcript...");
        updateFloatingStatus("3/3: Reading transcript...");
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
            updateFloatingStatus(`Transcript loaded (${transcriptData.length} words)`);
            
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
            updateFloatingStatus("Limited Mode: Using video title.");
            return true;
        }
        
        console.error("Signify: Could not find any transcript or video details.");
        updateFloatingStatus("Error: No transcript available.");
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
        updateFloatingStatus("No transcript available.");
        return;
    }
    
    translationActive = true;
    updateFloatingStatus("Translating...");
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
    updateFloatingStatus('Paused - Click play to resume');
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
            updateFloatingStatus("Translating...");
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
    updateFloatingStatus('Ready');
    updateFloatingCurrentWord('');
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
                margin-bottom: 8px !important;
                min-height: 20px !important;
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
            }
            
            .avatar-status-bar {
                background: rgba(0, 0, 0, 0.3) !important;
                border-radius: 4px !important;
                padding: 4px 8px !important;
            }
            
            .floating-status {
                color: #ccc !important;
                font-size: 11px !important;
                text-align: center !important;
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
          <div class="avatar-status-bar"><div id="floating-status" class="floating-status">Initializing...</div></div>
        </div>
      </div>`;
    document.body.appendChild(floatingAvatar);
    
    document.getElementById('avatar-close').addEventListener('click', hideFloatingAvatar);
    document.getElementById('avatar-minimize').addEventListener('click', toggleFloatingAvatar);
    makeAvatarDraggable(floatingAvatar);
    initializeFloatingAvatar();
    isSignifyActive = true;
    
    console.log("Signify: Floating avatar window created and styled");

    
    floatingAvatar.id = 'signify-floating-avatar';
    floatingAvatar.innerHTML = `
      <div class="floating-avatar-header">
        <div class="avatar-title"><span>Signify ISL</span></div>
        <div class="avatar-controls">
            <button id="avatar-minimize" class="avatar-control-btn" title="Minimize">−</button>
            <button id="avatar-close" class="avatar-control-btn" title="Close">✕</button>
        </div>
      </div>
      <div class="floating-avatar-content" id="floatingAvatarContent">
        <div id="floating-avatar-container" class="floating-avatar-display">
            <div class="avatar-loading">Loading Avatar...</div>
        </div>
        <div class="avatar-info">
          <div id="floating-current-word" class="floating-current-word">Ready</div>
          <div class="avatar-status-bar">
            <div id="floating-status" class="floating-status">Initializing...</div>
          </div>
        </div>
      </div>
      <!-- ADD THIS NEW ELEMENT FOR RESIZING -->
      <div id="signify-resize-handle"></div>`;
      
    document.body.appendChild(floatingAvatar);
    
    document.getElementById('avatar-close').addEventListener('click', hideFloatingAvatar);
    document.getElementById('avatar-minimize').addEventListener('click', toggleFloatingAvatar);
    
    makeAvatarDraggable(floatingAvatar);
    makeAvatarResizable(floatingAvatar); // Call the new resize function
    
    initializeFloatingAvatar();
    isSignifyActive = true;
    
    console.log("Signify: Floating avatar created.");
}

function makeAvatarResizable(element) {
    const resizeHandle = element.querySelector('#signify-resize-handle');
    let isResizing = false;
    let originalWidth = 0, originalHeight = 0, originalMouseX = 0, originalMouseY = 0;

    resizeHandle.addEventListener('mousedown', (e) => {
        e.preventDefault();
        isResizing = true;

        const rect = element.getBoundingClientRect();
        originalWidth = rect.width;
        originalHeight = rect.height;
        originalMouseX = e.clientX;
        originalMouseY = e.clientY;

        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
    });

    function handleMouseMove(e) {
        if (!isResizing) return;
        const newWidth = originalWidth + (e.clientX - originalMouseX);
        const newHeight = originalHeight + (e.clientY - originalMouseY);

        // Set minimum dimensions
        if (newWidth > 200) {
            element.style.width = newWidth + 'px';
        }
        if (newHeight > 250) {
            element.style.height = newHeight + 'px';
        }
    }

    function handleMouseUp() {
        isResizing = false;
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
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
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(45, 200 / 150, 0.1, 1000);
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(200, 150);
    renderer.setClearColor(0x000000, 0);
    container.appendChild(renderer.domElement);
    const ambientLight = new THREE.AmbientLight(0xffffff, 1.2);
    scene.add(ambientLight);
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(0.5, 1, 1.5);
    scene.add(directionalLight);
    camera.position.set(0, 0.8, 2.5);
    camera.lookAt(0, 0.6, 0);
    
    const loader = new THREE.GLTFLoader();
    window.signifyGltfLoader = loader;
    let avatarMixer = null;
    let avatarAnimations = [];
    let defaultAnimation = null;
    
    // Animation loop
    const clock = new THREE.Clock();
    function animate() {
        requestAnimationFrame(animate);
        if (avatarMixer) {
            avatarMixer.update(clock.getDelta());
        }
        renderer.render(scene, camera);
    }
    animate();
    
    // Load the main avatar model first
    loader.load(chrome.runtime.getURL('models/avatar.glb'), (gltf) => {
        const avatar = gltf.scene;
        avatar.scale.set(1.1, 1.1, 1.1);
        avatar.position.y = -1.0;
        scene.add(avatar);
        
        avatarMixer = new THREE.AnimationMixer(avatar);
        avatarAnimations = gltf.animations;
        
        console.log(`Signify: Avatar loaded with ${avatarAnimations.length} animations`);
        
        // Try to load default animation, but don't block if it fails
        loader.load(chrome.runtime.getURL('animation/default.glb'), (defaultGltf) => {
            console.log(`Signify: Default.glb loaded with ${defaultGltf.animations.length} animations`);
            
            if (defaultGltf.animations && defaultGltf.animations.length > 0) {
                defaultAnimation = defaultGltf.animations[0];
                console.log("Signify: Default animation available with", defaultAnimation.tracks.length, "tracks");
            }
            
            setupAvatarControls();
            
        }, undefined, (error) => {
            console.warn('Signify: Could not load default.glb, using avatar animations:', error);
            setupAvatarControls();
        });
        
        function setupAvatarControls() {
            // Find a good idle animation from avatar or default
            let idleAnimation = null;
            let idleAction = null;
            
            // Prefer default animation if available
            if (defaultAnimation) {
                idleAnimation = defaultAnimation;
                try {
                    idleAction = avatarMixer.clipAction(idleAnimation);
                    idleAction.setLoop(THREE.LoopRepeat);
                    console.log("Signify: Using default.glb for idle animation");
                } catch (error) {
                    console.warn("Signify: Error setting up default animation:", error);
                    idleAnimation = null;
                    idleAction = null;
                }
            }
            
            // Fallback to avatar's animations if default failed
            if (!idleAction) {
                idleAnimation = avatarAnimations.find(a => 
                    a.name.toLowerCase().includes('idle') || 
                    a.name.toLowerCase().includes('default') ||
                    a.name.toLowerCase().includes('rest') ||
                    a.name.toLowerCase().includes('t-pose')
                ) || avatarAnimations[0];
                
                if (idleAnimation) {
                    try {
                        idleAction = avatarMixer.clipAction(idleAnimation);
                        idleAction.setLoop(THREE.LoopRepeat);
                        console.log("Signify: Using avatar animation for idle:", idleAnimation.name);
                    } catch (error) {
                        console.warn("Signify: Error setting up avatar animation:", error);
                    }
                }
            }
            
            window.signifyFloatingAvatar = {
                mixer: avatarMixer,
                idleAction: idleAction,
                avatar: avatar,
                isPlaying: false,
                currentAction: null,
                
                setIdlePose: () => {
                    console.log("Signify: Setting idle pose");
                    
                    try {
                        // Stop all current actions
                        avatarMixer.stopAllAction();
                        
                        if (idleAction) {
                            // Reset and configure the idle action
                            idleAction.reset();
                            idleAction.setLoop(THREE.LoopRepeat);
                            idleAction.setEffectiveWeight(1.0);
                            idleAction.setEffectiveTimeScale(1.0);
                            idleAction.enabled = true;
                            
                            // Start playing
                            idleAction.play();
                            
                            window.signifyFloatingAvatar.isPlaying = true;
                            window.signifyFloatingAvatar.currentAction = idleAction;
                            
                            console.log("Signify: Idle animation started successfully");
                            console.log("Signify: Animation duration:", idleAction.getClip().duration);
                            console.log("Signify: Animation playing:", idleAction.isRunning());
                            
                        } else {
                            console.warn("Signify: No idle animation available");
                            updateFloatingStatus('Avatar ready (no animation)');
                        }
                    } catch (error) {
                        console.error("Signify: Error starting idle animation:", error);
                        updateFloatingStatus('Avatar animation error');
                    }
                },
                
                playWordAnimation: async (word) => {
                    const cleanWord = word.toLowerCase().replace(/[^\w]/g, '');
                    if (!cleanWord) {
                        window.signifyFloatingAvatar.setIdlePose();
                        return;
                    }

                    const playClip = (clip) => {
                        try {
                            avatarMixer.stopAllAction();
                            const action = avatarMixer.clipAction(clip);
                            action.reset();
                            action.setLoop(THREE.LoopOnce, 1);
                            action.clampWhenFinished = true;
                            action.play();

                            avatarMixer.removeEventListener('finished', window.signifyFloatingAvatar.returnToIdle);
                            avatarMixer.addEventListener('finished', window.signifyFloatingAvatar.returnToIdle);

                        } catch (error) {
                            console.error(`Signify: Error playing animation for "${word}":`, error);
                            window.signifyFloatingAvatar.setIdlePose();
                        }
                    };

                    // Check cache first
                    if (animationCache.has(cleanWord)) {
                        const cachedClip = animationCache.get(cleanWord);
                        if (cachedClip) {
                            console.log(`Signify: Playing cached animation for "${cleanWord}"`);
                            playClip(cachedClip);
                        } else {
                            // Null in cache means we know it doesn't exist, so play idle
                            window.signifyFloatingAvatar.setIdlePose();
                        }
                        return;
                    }
                    
                    // Fetch animation URL from API
                    try {
                        console.log(`Signify: Requesting animation for "${cleanWord}" from API`);
                        const response = await fetch(`${API_BASE_URL}/animation/${encodeURIComponent(cleanWord)}`, {
                            method: 'GET',
                            headers: {
                                'Content-Type': 'application/json',
                            }
                        });

                        if (!response.ok) {
                            throw new Error(`API responded with status: ${response.status}`);
                        }

                        const data = await response.json();
                        
                        if (data.success && data.animationUrl) {
                            console.log(`Signify: API returned animation URL for "${cleanWord}": ${data.animationUrl}`);
                            
                            // Load the GLB file from the URL provided by API
                            const gltf = await loader.loadAsync(data.animationUrl);
                            if (gltf.animations && gltf.animations.length > 0) {
                                const clip = gltf.animations[0];
                                animationCache.set(cleanWord, clip);
                                console.log(`Signify: Successfully loaded and cached animation for "${cleanWord}"`);
                                playClip(clip);
                            } else {
                                throw new Error("No animations found in the loaded GLB.");
                            }
                        } else {
                            throw new Error(data.message || "Animation not found");
                        }
                    } catch (error) {
                        console.log(`Signify: No animation found for "${cleanWord}" via API. Playing idle.`, error.message);
                        animationCache.set(cleanWord, null); // Cache the failure to avoid re-fetching
                        window.signifyFloatingAvatar.setIdlePose();
                    }
                },

                returnToIdle: () => {
                    console.log("Signify: Animation finished, returning to idle.");
                    if (window.signifyFloatingAvatar) {
                        window.signifyFloatingAvatar.setIdlePose();
                    }
                }
            };
            
            // Start idle animation immediately with a delay to ensure everything is loaded
            console.log("Signify: Starting initial idle animation");
            setTimeout(() => {
                if (window.signifyFloatingAvatar) {
                    window.signifyFloatingAvatar.setIdlePose();
                }
            }, 500);
            updateFloatingStatus('Avatar ready');
        }
        
    }, undefined, (error) => {
        console.error('Signify: Avatar loading error:', error);
        updateFloatingStatus('Avatar load failed');
    });
}

function updateFloatingStatus(message) {
    const el = document.getElementById('floating-status');
    if (el) el.textContent = message;
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
        if (window.THREE) {
            if (!window.THREE.GLTFLoader) {
                 loadScript('GLTFLoader.js').then(resolve);
            } else {
                resolve();
            }
            return;
        }
        const script = document.createElement('script');
        script.src = chrome.runtime.getURL('three.min.js');
        script.onload = () => loadScript('GLTFLoader.js').then(resolve);
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