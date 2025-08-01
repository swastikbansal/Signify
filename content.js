class ISLExtensionViewer {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.controls = null;
        this.clock = null;
        this.mixer = null;
        this.currentModel = null;
        this.isPlayingSequence = false;
        this.container = null;
        this.canvas = null;
        this.isInitialized = false;

        // Available models - these paths will be resolved relative to the extension
        this.availableModels = [
            { name: 'default.glb', path: 'animation/default.glb' },
            { name: 'baby.glb', path: 'animation/baby.glb' },
            { name: 'book.glb', path: 'animation/book.glb' },
            { name: 'boy.glb', path: 'animation/boy.glb' },
            { name: 'cold.glb', path: 'animation/cold.glb' },
            { name: 'drink.glb', path: 'animation/drink.glb' },
            { name: 'happy.glb', path: 'animation/happy.glb' },
            { name: 'teacher.glb', path: 'animation/teacher.glb' },
            { name: 'work.glb', path: 'animation/work.glb' }
        ];
    }

    async createViewer() {
        if (this.container) return;

        // Create container
        this.container = document.createElement('div');
        this.container.id = 'isl-viewer-container';
        
        // Create header
        const header = document.createElement('div');
        header.id = 'isl-viewer-header';
        header.innerHTML = `
            <span>ISL Animation Viewer</span>
            <button id="isl-viewer-close">×</button>
        `;
        
        // Create canvas
        this.canvas = document.createElement('canvas');
        this.canvas.id = 'isl-viewer-canvas';
        
        // Create status
        const status = document.createElement('div');
        status.id = 'isl-viewer-status';
        status.textContent = 'Ready';
        
        // Create loading indicator
        const loading = document.createElement('div');
        loading.id = 'isl-viewer-loading';
        loading.textContent = 'Loading Animation...';
        
        // Assemble container
        this.container.appendChild(header);
        this.container.appendChild(this.canvas);
        this.container.appendChild(status);
        this.container.appendChild(loading);
        
        // Add to page
        document.body.appendChild(this.container);
        
        // Setup close button
        document.getElementById('isl-viewer-close').addEventListener('click', () => {
            this.hideViewer();
        });

        // Load Three.js if not already loaded
        await this.loadThreeJS();
        
        // Initialize Three.js scene
        await this.initThreeJS();
        
        this.isInitialized = true;
    }

    async loadThreeJS() {
        // Since THREE.js files are now loaded via manifest.json, just verify they're available
        console.log('Checking Three.js availability...');
        
        // Wait a bit for all scripts to load
        let attempts = 0;
        const maxAttempts = 50;
        
        while (attempts < maxAttempts) {
            if (window.THREE && window.THREE.GLTFLoader && window.THREE.OrbitControls) {
                console.log('Three.js libraries are available');
                return;
            }
            
            await new Promise(resolve => setTimeout(resolve, 100));
            attempts++;
        }
        
        // Final check with detailed logging
        console.log('Three.js availability check:', {
            THREE: !!window.THREE,
            GLTFLoader: !!window.THREE?.GLTFLoader,
            OrbitControls: !!window.THREE?.OrbitControls
        });
        
        if (!window.THREE || !window.THREE.GLTFLoader || !window.THREE.OrbitControls) {
            throw new Error('Three.js components are not available. Make sure all scripts are loaded via manifest.json');
        }
        
        console.log('Three.js libraries loaded successfully');
    }

    async initThreeJS() {
        if (!window.THREE) {
            console.error("Attempted to initialize Three.js scene, but THREE is not defined.");
            return;
        }
        
        console.log('Initializing Three.js scene...');
        
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x2a2a2a);
        
        // Closer framing from knee to head with tighter field of view
        this.camera = new THREE.PerspectiveCamera(45, 320 / 350, 0.1, 1000);
        this.camera.position.set(0, 1.3, 1.8);
        
        this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas, antialias: true });
        this.renderer.setSize(320, 350);
        this.renderer.shadowMap.enabled = true;
        this.renderer.outputEncoding = THREE.sRGBEncoding;

        this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.target.set(0, 1.1, 0);
        this.controls.enableZoom = true;
        this.controls.zoomSpeed = 0.5;
        this.controls.enablePan = false; // Disable panning to keep avatar centered

        this.clock = new THREE.Clock();
        
        this.setupLighting();
        
        console.log('Three.js scene initialized, loading initial model...');
        
        try {
            await this.loadInitialModel();
            console.log('Initial model loaded successfully');
        } catch (error) {
            console.error('Failed to load initial model:', error);
            const statusElem = document.getElementById('isl-viewer-status');
            if (statusElem) {
                statusElem.textContent = 'Ready (default model failed to load)';
            }
        }
        
        this.animate();
        
        // Handle container resize
        window.addEventListener('resize', () => this.onWindowResize());
        
        console.log('Three.js initialization complete');
    }

    setupLighting() {
        this.scene.add(new THREE.AmbientLight(0xffffff, 0.7));
        const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
        dirLight.position.set(5, 10, 7.5);
        dirLight.castShadow = true;
        dirLight.shadow.mapSize.width = 2048;
        dirLight.shadow.mapSize.height = 2048;
        this.scene.add(dirLight);
    }

    async loadInitialModel() {
        const defaultModel = this.availableModels.find(m => m.name === 'default.glb');
        if (defaultModel) {
            await this.loadAndPlayAnimation(defaultModel.path, { loop: true });
        }
    }

    async processSentence(sentence) {
        if (this.isPlayingSequence) return;
        this.isPlayingSequence = true;

        try {
            const words = sentence.toLowerCase().split(/\s+/).filter(Boolean);
            const animationsToPlay = [];
            const skippedWords = [];

            for (const word of words) {
                const model = this.availableModels.find(m => m.name.toLowerCase() === `${word}.glb`);
                if (model) {
                    animationsToPlay.push({ word, path: model.path });
                } else {
                    skippedWords.push(word);
                }
            }

            const statusElem = document.getElementById('isl-viewer-status');
            if (animationsToPlay.length === 0) {
                statusElem.textContent = `No animations found for "${sentence}".`;
                setTimeout(() => this.loadInitialModel(), 2000);
                return;
            }

            const skippedInfo = skippedWords.length > 0 ? `| Skipped: ${skippedWords.join(', ')}` : '';
            
            for (const [index, anim] of animationsToPlay.entries()) {
                statusElem.textContent = `Playing: ${anim.word} (${index + 1}/${animationsToPlay.length}) ${skippedInfo}`;
                await this.loadAndPlayAnimation(anim.path);
                if (index < animationsToPlay.length - 1) {
                    await new Promise(r => setTimeout(r, 250));
                }
            }
            
            statusElem.textContent = 'Sequence complete. Ready for next input.';
            await this.loadInitialModel();

            // Notify popup of completion
            chrome.runtime.sendMessage({
                action: 'updateStatus',
                status: 'Animation sequence completed!'
            });

        } catch (error) {
            console.error('Error processing sentence:', error);
            document.getElementById('isl-viewer-status').textContent = 'An error occurred during playback.';
        } finally {
            this.isPlayingSequence = false;
        }
    }

    async loadAndPlayAnimation(modelPath, options = {}) {
        // Wait for Three.js to be fully loaded with better detection and longer timeout
        let threeReady = false;
        for (let i = 0; i < 200; i++) { // Increased from 100 to 200 (20 seconds)
            if (window.THREE && window.THREE.GLTFLoader && typeof window.THREE.GLTFLoader === 'function') {
                threeReady = true;
                break;
            }
            await new Promise(resolve => setTimeout(resolve, 100));
        }

        if (!threeReady) {
            console.error('Three.js loading timeout - attempting to reload...');
            try {
                await this.loadThreeJS();
                // Check one more time after reload attempt
                if (window.THREE && window.THREE.GLTFLoader && typeof window.THREE.GLTFLoader === 'function') {
                    threeReady = true;
                }
            } catch (error) {
                console.error('Failed to reload Three.js:', error);
            }
        }

        return new Promise(async (resolve, reject) => {
            try {
                if (!threeReady || !window.THREE || !window.THREE.GLTFLoader || typeof window.THREE.GLTFLoader !== 'function') {
                    console.error('THREE.js components check:', {
                        THREE: !!window.THREE,
                        GLTFLoader: !!window.THREE?.GLTFLoader,
                        GLTFLoaderType: typeof window.THREE?.GLTFLoader,
                        windowKeys: Object.keys(window).filter(k => k.includes('THREE'))
                    });
                    
                    const statusElem = document.getElementById('isl-viewer-status');
                    if (statusElem) {
                        statusElem.textContent = 'Failed to load 3D animation library. Please refresh the page.';
                    }
                    
                    return reject(new Error('THREE.js or GLTFLoader not available for animation playback.'));
                }

                const loadingElement = document.getElementById('isl-viewer-loading');
                if (loadingElement) {
                    loadingElement.style.display = 'block';
                }

                // Clean up previous model
                if (this.currentModel) {
                    this.scene.remove(this.currentModel);
                    this.currentModel = null;
                }
                if (this.mixer) {
                    this.mixer.stopAllAction();
                    this.mixer = null;
                }

                // Convert relative path to extension URL
                const fullPath = chrome.runtime.getURL(modelPath);
                console.log('Loading model from:', fullPath);

                const loader = new THREE.GLTFLoader();
                
                // Add timeout to the loader
                const loadPromise = loader.loadAsync(fullPath);
                const timeoutPromise = new Promise((_, reject) => {
                    setTimeout(() => reject(new Error('Model loading timeout')), 15000);
                });
                
                const gltf = await Promise.race([loadPromise, timeoutPromise]);
                this.currentModel = gltf.scene;
                this.scene.add(this.currentModel);

                this.currentModel.traverse(child => {
                    if (child.isMesh) {
                        child.castShadow = true;
                        child.receiveShadow = true;
                    }
                });

                this.centerModel();
                
                if (loadingElement) {
                    loadingElement.style.display = 'none';
                }

                if (gltf.animations && gltf.animations.length > 0) {
                    this.mixer = new THREE.AnimationMixer(this.currentModel);
                    const clip = gltf.animations[0];
                    const action = this.mixer.clipAction(clip);
                    
                    if (options.loop) {
                        action.setLoop(THREE.LoopRepeat);
                        action.play();
                        console.log('Looping animation started for:', modelPath);
                        resolve();
                    } else {
                        action.setLoop(THREE.LoopOnce);
                        action.clampWhenFinished = true;
                        
                        // Set up finished listener
                        const onFinished = () => {
                            this.mixer.removeEventListener('finished', onFinished);
                            console.log('Animation finished for:', modelPath);
                            resolve();
                        };
                        this.mixer.addEventListener('finished', onFinished);
                        
                        action.play();
                        console.log('Single animation started for:', modelPath);
                    }
                } else {
                    console.log('No animations found in model:', modelPath);
                    const statusElem = document.getElementById('isl-viewer-status');
                    if (statusElem) {
                        statusElem.textContent = 'Model loaded but no animations found.';
                    }
                    setTimeout(resolve, 1000);
                }
            } catch (error) {
                console.error(`Failed to load model: ${modelPath}`, error);
                const loadingElement = document.getElementById('isl-viewer-loading');
                if (loadingElement) {
                    loadingElement.style.display = 'none';
                }
                
                const statusElem = document.getElementById('isl-viewer-status');
                if (statusElem) {
                    statusElem.textContent = `Failed to load animation: ${error.message}`;
                }
                
                reject(error);
            }
        });
    }

    centerModel() {
        if (!this.currentModel) return;
        
        // Get the bounding box of the model
        const box = new THREE.Box3().setFromObject(this.currentModel);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        
        // Center the model horizontally
        this.currentModel.position.x = -center.x;
        this.currentModel.position.z = -center.z;
        
        // Position the model so knees are at the bottom of the frame
        // Assume knees are at about 30% of the avatar height from the bottom
        const kneeHeight = size.y * 0.3;
        this.currentModel.position.y = -box.min.y - kneeHeight;
        
        // Scale the model to show from knee to head properly
        // We want the knee-to-head portion (70% of avatar) to fill the frame
        const visibleHeight = size.y * 0.7; // From knee to head
        if (visibleHeight > 2.0) {
            const scale = 2.0 / visibleHeight;
            this.currentModel.scale.setScalar(scale);
        }
        
        // Focus camera on upper torso/chest level for sign language gestures
        this.controls.target.set(0, size.y * 0.4, 0);
        this.controls.update();
    }

    animate() {
        if (!this.isInitialized || !this.container || this.container.style.display === 'none') return;
        
        requestAnimationFrame(() => this.animate());
        if (this.mixer) this.mixer.update(this.clock.getDelta());
        if (this.controls) this.controls.update();
        if (this.renderer && this.scene && this.camera) {
            this.renderer.render(this.scene, this.camera);
        }
    }

    onWindowResize() {
        if (!this.camera || !this.renderer) return;
        // Keep the viewer size fixed with new dimensions
        this.camera.aspect = 320 / 350;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(320, 350);
    }

    showViewer() {
        if (!this.container) return;
        this.container.classList.add('active');
        this.animate(); // Restart animation loop
    }

    hideViewer() {
        if (!this.container) return;
        this.container.classList.remove('active');
    }

    destroy() {
        if (this.container && this.container.parentNode) {
            this.container.parentNode.removeChild(this.container);
        }
        this.container = null;
        this.isInitialized = false;
    }
}

// Global viewer instance
let islViewer = null;

// YouTube Integration Variables
let transcriptData = [];
let translationActive = false;
let lastSyncedWord = '';
let syncInterval = null;
let isYouTubePage = false;

// YouTube Detection and Initialization
function detectYouTubePage() {
    return window.location.hostname === 'www.youtube.com' && window.location.pathname === '/watch';
}

function waitForElement(selector, timeout = 10000) {
    return new Promise((resolve, reject) => {
        const element = document.querySelector(selector);
        if (element) {
            resolve(element);
            return;
        }

        const observer = new MutationObserver((mutations, obs) => {
            const element = document.querySelector(selector);
            if (element) {
                obs.disconnect();
                resolve(element);
            }
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });

        setTimeout(() => {
            observer.disconnect();
            reject(new Error(`Element ${selector} not found within ${timeout}ms`));
        }, timeout);
    });
}

async function extractTranscript() {
    transcriptData = [];
    try {
        const transcriptButton = await waitForElement('button[aria-label="Show transcript"]');
        transcriptButton.click();

        await waitForElement('ytd-transcript-segment-renderer');
        const segments = document.querySelectorAll('ytd-transcript-segment-renderer');

        segments.forEach((segment, index) => {
            const timeEl = segment.querySelector('.segment-timestamp');
            const textEl = segment.querySelector('.segment-text');
            if (timeEl && textEl) {
                const timeText = timeEl.textContent.trim();
                const startTime = parseTimeToSeconds(timeText);
                const segmentText = textEl.textContent.trim();
                const words = segmentText.split(/\s+/).filter(Boolean);
                const wordDuration = 5 / words.length;

                words.forEach((word, wordIndex) => {
                    const cleanedWord = word.toLowerCase().replace(/[^\w\s'-]/g, '');
                    const wordStartTime = startTime + (wordIndex * wordDuration);
                    const wordEndTime = startTime + ((wordIndex + 1) * wordDuration);
                    transcriptData.push({
                        word: cleanedWord,
                        startTime: wordStartTime,
                        endTime: wordEndTime,
                        originalText: word
                    });
                });
            }
        });
        console.log('Transcript extracted:', transcriptData.length, 'words');
    } catch (error) {
        console.error('Transcript extraction failed:', error);
    }
}

function parseTimeToSeconds(timeStr) {
    const parts = timeStr.split(':').map(Number);
    if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
    if (parts.length === 2) return parts[0] * 60 + parts[1];
    return parts[0] || 0;
}

function syncWithVideo(video) {
    if (syncInterval) clearInterval(syncInterval);

    syncInterval = setInterval(() => {
        if (!translationActive || video.paused) return;

        const currentTime = video.currentTime;
        const word = transcriptData.find(w =>
            currentTime >= w.startTime && currentTime <= w.endTime
        );

        if (word && word.word !== lastSyncedWord) {
            lastSyncedWord = word.word;
            updateCurrentWord(word.originalText);
            // Play ISL animation for the word
            if (islViewer && word.word) {
                const model = islViewer.availableModels.find(m => 
                    m.name.toLowerCase() === `${word.word}.glb`
                );
                if (model) {
                    islViewer.loadAndPlayAnimation(model.path).catch(err => {
                        console.log('Animation not found for word:', word.word);
                    });
                }
            }
        }
    }, 100);
}

function updateCurrentWord(word) {
    const display = document.getElementById('currentWordDisplay');
    if (display) {
        display.textContent = word;
        display.classList.add('word-animation');
        setTimeout(() => display.classList.remove('word-animation'), 600);
    }
}

function handleVideoPlay() {
    const video = document.querySelector('video');
    if (!video) return;
    
    if (transcriptData.length === 0) {
        extractTranscript().then(() => {
            translationActive = true;
            syncWithVideo(video);
        });
    } else {
        translationActive = true;
        syncWithVideo(video);
    }
}

function createSignifyButton() {
    const oldBtn = document.getElementById('signify-toggle-btn');
    if (oldBtn) oldBtn.remove();

    const controls = document.querySelector('.ytp-right-controls');
    if (!controls) {
        console.log("Signify: YouTube controls not found, retrying...");
        setTimeout(createSignifyButton, 1000);
        return;
    }

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
        console.log("Signify button clicked");
        showAvatarInterface();
        extractTranscriptAndStart();
    });

    controls.prepend(signifyBtn);
    console.log("Signify button added to player controls");
}

function showAvatarInterface() {
    if (document.getElementById('signify-avatar-container')) return;

    const container = document.createElement('div');
    container.id = 'signify-avatar-container';
    container.innerHTML = `
        <div class="signify-header">
            <div class="signify-title">🤟 Signify ISL Translator</div>
            <button id="signify-close" title="Close">✕</button>
        </div>
        <div class="avatar-display" id="avatarDisplay">
            <div class="avatar-loading">Loading 3D Avatar...</div>
        </div>
        <div class="current-word-display" id="currentWordDisplay">Ready to translate</div>
    `;
    
    // Add styles
    const style = document.createElement('style');
    style.textContent = `
        #signify-avatar-container {
            position: fixed;
            top: 20px;
            right: 20px;
            width: 320px;
            height: 450px;
            background: #1a1a1a;
            border: 2px solid #333;
            border-radius: 10px;
            z-index: 10000;
            font-family: Arial, sans-serif;
        }
        .signify-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #333;
            color: white;
            padding: 10px;
            border-radius: 8px 8px 0 0;
        }
        .signify-title {
            font-weight: bold;
            font-size: 14px;
        }
        #signify-close {
            background: none;
            border: none;
            color: white;
            font-size: 18px;
            cursor: pointer;
            padding: 0;
            width: 20px;
            height: 20px;
        }
        .avatar-display {
            height: 360px;
            background: #2a2a2a;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #666;
        }
        .current-word-display {
            padding: 10px;
            text-align: center;
            background: #222;
            color: #ffeb3b;
            font-size: 16px;
            font-weight: bold;
            border-radius: 0 0 8px 8px;
        }
        .word-animation {
            animation: wordPulse 0.6s ease-in-out;
        }
        @keyframes wordPulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
        }
    `;
    document.head.appendChild(style);
    
    document.body.appendChild(container);

    document.getElementById('signify-close').addEventListener('click', () => {
        container.remove();
        translationActive = false;
        if (syncInterval) clearInterval(syncInterval);
    });

    // Initialize the ISL viewer in the avatar display
    createImmediateAvatar();
}

function createImmediateAvatar() {
    if (!islViewer) {
        islViewer = new ISLExtensionViewer();
    }
    
    // Replace the avatar display with the ISL viewer
    const avatarDisplay = document.getElementById('avatarDisplay');
    if (avatarDisplay) {
        avatarDisplay.innerHTML = '';
        
        islViewer.createViewer().then(() => {
            // Move the ISL viewer container into the avatar display
            const islContainer = document.getElementById('isl-viewer-container');
            if (islContainer) {
                islContainer.style.position = 'relative';
                islContainer.style.width = '100%';
                islContainer.style.height = '100%';
                avatarDisplay.appendChild(islContainer);
                islViewer.showViewer();
            }
        });
    }
}

function extractTranscriptAndStart() {
    const video = document.querySelector('video');
    if (!video) {
        console.error('No video found on page');
        return;
    }

    // Extract transcript and start sync
    handleVideoPlay();
    
    // Listen for video play/pause events
    video.addEventListener('play', () => {
        if (translationActive) {
            syncWithVideo(video);
        }
    });
    
    video.addEventListener('pause', () => {
        if (syncInterval) clearInterval(syncInterval);
    });
}

// Initialize YouTube integration when page loads
function initYouTubeIntegration() {
    isYouTubePage = detectYouTubePage();
    
    if (isYouTubePage) {
        console.log('YouTube page detected, initializing Signify integration');
        
        // Wait for YouTube player to load
        setTimeout(() => {
            createSignifyButton();
        }, 2000);
        
        // Handle navigation within YouTube (SPA routing)
        const observer = new MutationObserver(() => {
            if (detectYouTubePage() && !document.getElementById('signify-toggle-btn')) {
                setTimeout(createSignifyButton, 1000);
            }
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
}

// Initialize when page is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initYouTubeIntegration);
} else {
    initYouTubeIntegration();
}

// Listen for messages from popup
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    if (request.action === 'showViewer') {
        if (!islViewer) {
            islViewer = new ISLExtensionViewer();
        }
        
        islViewer.createViewer().then(() => {
            islViewer.showViewer();
            if (request.sentence) {
                islViewer.processSentence(request.sentence);
            }
            sendResponse({success: true});
        }).catch(error => {
            console.error('Error creating viewer:', error);
            sendResponse({success: false, error: error.message});
        });
        
        return true; // Keep message channel open for async response
    } 
    else if (request.action === 'hideViewer') {
        if (islViewer) {
            islViewer.hideViewer();
        }
        sendResponse({success: true});
    }
    else if (request.action === 'toggleYouTubeTranslation') {
        if (isYouTubePage) {
            if (translationActive) {
                translationActive = false;
                if (syncInterval) clearInterval(syncInterval);
                sendResponse({success: true, status: 'Translation stopped'});
            } else {
                showAvatarInterface();
                extractTranscriptAndStart();
                sendResponse({success: true, status: 'Translation started'});
            }
        } else {
            sendResponse({success: false, error: 'Not on a YouTube page'});
        }
        return true;
    }
});

// Clean up on page unload
window.addEventListener('beforeunload', function() {
    if (islViewer) {
        islViewer.destroy();
    }
    if (syncInterval) {
        clearInterval(syncInterval);
    }
});
