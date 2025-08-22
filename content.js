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
    this.defaultModelPath = null; // cached resolved default.glb path (remote preferred)
    // When false, don't show looping default avatar in idle state; only show during actual word animations
    this.enableIdleDefault = false;
    // Caching & preloading
    this.modelCache = new Map(); // key: resolved fullPath -> gltf
    this.preloadPromises = new Map(); // key: resolved fullPath -> promise
    this.lastPreloadTranscriptIndex = -1;
    this.playbackSpeed = 1.25; // speed multiplier for animation to better sync with displayed words

        // Known models; actual URLs will be resolved from Supabase when configured,
        // otherwise they fall back to local extension assets under animation/
        this.knownModelNames = [
            'default.glb',
            // 'baby.glb',
            // 'book.glb',
            // 'boy.glb',
            // 'cold.glb',
            // 'drink.glb',
            // 'happy.glb',
            // 'teacher.glb',
            // 'work.glb'
        ];
        this.availableModels = [];
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
        
    // Resolve models from Supabase (if configured) before initializing the scene
    await this.resolveAvailableModels();

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
        
        if (this.enableIdleDefault) {
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
        // Ensure models are resolved at least once
        if (!this.availableModels || this.availableModels.length === 0) {
            await this.resolveAvailableModels();
        }
        let defaultUrl = this.availableModels.find(m => m.name.toLowerCase() === 'default.glb')?.path;
        if (!defaultUrl && window.SupabaseStorage && window.SupabaseStorage.isConfigured && window.SupabaseStorage.isConfigured()) {
            try {
                defaultUrl = await window.SupabaseStorage.getObjectURL('default.glb');
                if (defaultUrl) {
                    this.availableModels.push({ name: 'default.glb', path: defaultUrl });
                }
            } catch (_) {}
        }
        if (defaultUrl) {
            this.defaultModelPath = defaultUrl;
            await this.loadAndPlayAnimation(defaultUrl, { loop: true });
        } else {
            // Per request: allow local default.glb as a fallback for initial/idle state only
            const localDefault = 'animation/default.glb';
            console.log('Supabase default not available, falling back to local:', localDefault);
            this.defaultModelPath = localDefault;
            await this.loadAndPlayAnimation(localDefault, { loop: true });
        }
    }

    async resolveAvailableModels() {
        try {
            if (window.SupabaseStorage) {
                await window.SupabaseStorage.init();
                if (window.SupabaseStorage.isConfigured()) {
                    const remote = await window.SupabaseStorage.fetchAvailableModels();
                    this.availableModels = Array.isArray(remote) ? remote : [];
                    console.log('Available models resolved from Supabase:', this.availableModels);
                    return;
                }
            }
        } catch (e) {
            console.warn('Supabase model resolution failed, no local fallback per configuration:', e);
        }
        // Supabase-only mode: do not populate local fallbacks
        this.availableModels = [];
    }

    async getDefaultModelPath() {
        if (this.defaultModelPath) return this.defaultModelPath;
        // try to resolve again (in case initial resolution happened before Supabase init)
        try {
            if (window.SupabaseStorage && window.SupabaseStorage.isConfigured && window.SupabaseStorage.isConfigured()) {
                const url = await window.SupabaseStorage.getObjectURL('default.glb');
                if (url) {
                    this.defaultModelPath = url;
                    if (!this.availableModels.find(m => m.name.toLowerCase() === 'default.glb')) {
                        this.availableModels.push({ name: 'default.glb', path: url });
                    }
                    return url;
                }
            }
        } catch (_) {}
        // local fallback
        this.defaultModelPath = 'animation/default.glb';
        return this.defaultModelPath;
    }

    async processSentence(sentence) {
        if (this.isPlayingSequence) return;
        this.isPlayingSequence = true;

        try {
            const words = sentence.toLowerCase().split(/\s+/).filter(Boolean);
            const animationsToPlay = [];
            const skippedWords = [];

            for (const word of words) {
                const res = await this.resolveWordModel(word);
                if (res.fallback) skippedWords.push(word);
                animationsToPlay.push({ word, path: res.path, fallback: res.fallback });
            }

            const statusElem = document.getElementById('isl-viewer-status');
            if (animationsToPlay.length === 0) {
                statusElem.textContent = `No animations found for "${sentence}".`;
                setTimeout(() => this.loadInitialModel(), 2000);
                return;
            }

            const skippedInfo = skippedWords.length > 0 ? `| Skipped: ${skippedWords.join(', ')}` : '';

            // Preload all animations first to eliminate mid-sequence delays
            const uniquePaths = [...new Set(animationsToPlay.map(a => a.path))];
            let loadedCount = 0;
            statusElem.textContent = `Preloading animations (0/${uniquePaths.length})...`;
            await Promise.all(uniquePaths.map(async p => {
                try {
                    await this.preloadModel(p);
                    loadedCount++;
                    statusElem.textContent = `Preloading animations (${loadedCount}/${uniquePaths.length})...`;
                } catch (e) {
                    console.warn('[ISL][PRELOAD][FAIL]', p, e.message);
                }
            }));
            statusElem.textContent = 'Starting sequence...';
            
            for (const [index, anim] of animationsToPlay.entries()) {
                statusElem.textContent = `Playing: ${anim.word}${anim.fallback ? ' (default)' : ''} (${index + 1}/${animationsToPlay.length}) ${skippedInfo}`;
                await this.loadAndPlayAnimation(anim.path, { crossFade: 0.25, useCache: true });
                if (index < animationsToPlay.length - 1) {
                    await new Promise(r => setTimeout(r, 250));
                    // Opportunistic preload of next+1 (already preloaded globally, but could have failed earlier)
                    const nextAnim = animationsToPlay[index + 1];
                    if (nextAnim) this.preloadModel(nextAnim.path).catch(()=>{});
                }
            }
            
            statusElem.textContent = 'Sequence complete.';
            if (this.enableIdleDefault) {
                await this.loadInitialModel();
            } else {
                // Clear model after short pause to remove resting avatar
                setTimeout(() => {
                    if (this.currentModel && this.scene) {
                        try { this.scene.remove(this.currentModel); } catch(_){}
                        this.currentModel = null;
                    }
                }, 1200);
            }

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

                // Instead of removing immediately, fade out previous animation if desired (simple clear for now)
                if (this.currentModel) {
                    try { this.scene.remove(this.currentModel); } catch(_){}
                    this.currentModel = null;
                }
                if (this.mixer) {
                    try { this.mixer.stopAllAction(); } catch(_){}
                    this.mixer = null;
                }

                // Use remote URLs directly; convert relative paths to extension URLs
                let fullPath = modelPath;
                let source = 'remote';
                if (!/^https?:\/\//i.test(modelPath)) {
                    fullPath = chrome.runtime.getURL(modelPath);
                    source = 'local';
                }
                const fetchStart = (performance && performance.now) ? performance.now() : Date.now();
                console.log(`[ISL][FETCH][START] src="${fullPath}" origin=${source}`);

                // Use cache / preload when available
                let gltf = null;
                if (options.useCache && this.modelCache.has(fullPath)) {
                    gltf = this.modelCache.get(fullPath);
                } else {
                    gltf = await this.preloadModel(fullPath, { directPath: true });
                }
                this.currentModel = gltf.scene;
                if (this.scene && this.currentModel) {
                    this.scene.add(this.currentModel);
                } else {
                    throw new Error('Scene not initialized for model add');
                }
                const fetchEnd = (performance && performance.now) ? performance.now() : Date.now();
                console.log(`[ISL][FETCH][SUCCESS] src="${fullPath}" origin=${source} timeMs=${(fetchEnd - fetchStart).toFixed(1)} animations=${gltf.animations ? gltf.animations.length : 0}`);

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
                    const prevMixer = this.mixer;
                    const prevAction = this.previousAction;
                    this.mixer = new THREE.AnimationMixer(this.currentModel);
                    const clip = gltf.animations[0];
                    console.log('Playing clip:', clip.name || '(unnamed)', 'duration(s)=', clip.duration);
                    const action = this.mixer.clipAction(clip);
                    action.timeScale = this.playbackSpeed; // apply speed multiplier
                    if (options.loop) {
                        action.setLoop(THREE.LoopRepeat);
                    } else {
                        action.setLoop(THREE.LoopOnce);
                        action.clampWhenFinished = true;
                    }
                    // Cross-fade only if same mixer/root
                    if (prevAction && prevMixer === this.mixer && options.crossFade) {
                        prevAction.crossFadeTo(action, options.crossFade, false);
                    } else {
                        action.reset();
                        action.enabled = true;
                        action.weight = 1.0;
                    }
                    action.play();
                    this.previousAction = action;
                    if (prevMixer && prevMixer !== this.mixer) {
                        try { prevMixer.stopAllAction(); } catch (_) {}
                    }
                    if (options.loop) {
                        console.log('Looping animation started for:', modelPath);
                        resolve();
                    } else {
                        const duration = (clip.duration / this.playbackSpeed) * 1000; // adjust wait based on speed
                        let finished = false;
                        const safeResolve = () => { if (!finished) { finished = true; resolve(); } };
                        const onFinished = () => { finished = true; this.mixer.removeEventListener('finished', onFinished); console.log('Animation finished for:', modelPath); safeResolve(); };
                        this.mixer.addEventListener('finished', onFinished);
                        setTimeout(safeResolve, duration + 250);
                        console.log('Single animation started for:', modelPath, 'duration(ms)=', duration);
                    }
                } else {
                    console.log(`[ISL][FETCH][NO_ANIMATION] src="${fullPath}"`);
                    const statusElem = document.getElementById('isl-viewer-status');
                    if (statusElem) {
                        statusElem.textContent = 'Model loaded but no animations found.';
                    }
                    setTimeout(resolve, 1000);
                }
            } catch (error) {
                console.error(`[ISL][FETCH][FAIL] src="${modelPath}" error=${error.message}`);
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
    if (!this.currentModel || !this.camera || !this.controls) return;

    const box = new THREE.Box3().setFromObject(this.currentModel);
    const size = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());

    // Re-center model at origin horizontally
    this.currentModel.position.x = this.currentModel.position.x - center.x;
    this.currentModel.position.z = this.currentModel.position.z - center.z;

    // Desired framing parameters
    const HEAD_ROOM = 0.03; // minimal headroom
    const LOWER_CROP = 0.18; // include a bit more lower torso
    const TARGET_SCREEN_HEIGHT = 3.1; // larger scale for near-fill

    // Raw height
    const fullHeight = size.y || 1;
    const scale = TARGET_SCREEN_HEIGHT / (fullHeight * (1 - LOWER_CROP - HEAD_ROOM));
    this.currentModel.scale.setScalar(scale);

    // Recompute box after scale for precise positioning
    const scaledBox = new THREE.Box3().setFromObject(this.currentModel);
    const scaledSize = scaledBox.getSize(new THREE.Vector3());
    const scaledMin = scaledBox.min;
    const scaledMax = scaledBox.max;

    // Position so that the LOWER_CROP point (e.g., upper thighs) sits near y=0
    const targetLowerY = scaledMin.y + scaledSize.y * LOWER_CROP;
    this.currentModel.position.y -= targetLowerY; // shift so that lower crop aligns with ground plane

    // Compute camera distance from bounding sphere to fit height comfortably
    const sphere = new THREE.Sphere();
    scaledBox.getBoundingSphere(sphere);
    const fov = this.camera.fov * (Math.PI / 180);
    // distance = radius / sin(fov/2); but we want vertical fit: use height/ (2*tan(fov/2))
    const desiredHalfHeight = (scaledSize.y * (1 - LOWER_CROP + HEAD_ROOM)) / 2;
    const distance = desiredHalfHeight / Math.tan(fov / 2) * 1.05; // small padding
    this.camera.position.set(0.15, scaledSize.y * 0.62, distance * 0.82); // slight horizontal offset + closer
    this.camera.near = Math.max(0.01, distance * 0.1);
    this.camera.far = distance * 10;
    this.camera.updateProjectionMatrix();

    // Aim controls target at chest/hands zone (~40% of height above lower crop)
    this.controls.target.set(0.05, scaledSize.y * (LOWER_CROP + 0.47), 0);
    this.controls.update();
    }

    async resolveWordModel(word) {
        const fnameLower = `${word}.glb`;
        const fnameTitle = `${word.charAt(0).toUpperCase()}${word.slice(1)}.glb`;
        let model = this.availableModels.find(m => m.name.toLowerCase() === fnameLower.toLowerCase());
        if (!model && window.SupabaseStorage && window.SupabaseStorage.isConfigured && window.SupabaseStorage.isConfigured()) {
            try {
                let url = await window.SupabaseStorage.getObjectURL(fnameLower);
                if (!url) url = await window.SupabaseStorage.getObjectURL(fnameTitle);
                if (url) {
                    const pickedName = url.includes(fnameTitle) ? fnameTitle : fnameLower;
                    model = { name: pickedName, path: url };
                    this.availableModels.push(model);
                    console.log(`[ISL][RESOLVE] word="${word}" status=FOUND url=${url}`);
                }
            } catch (e) {
                console.warn('[ISL][RESOLVE][ERR]', word, e.message);
            }
        }
        if (model) return { path: model.path, fallback: false };
        const fallbackPath = await this.getDefaultModelPath();
        console.log(`[ISL][RESOLVE] word="${word}" status=MISS usingDefault path=${fallbackPath}`);
        return { path: fallbackPath, fallback: true };
    }

    async preloadModel(path, { directPath = false } = {}) {
        // Accept already-resolved full paths or relative model paths
        let fullPath = path;
        if (!directPath && !/^https?:\/\//i.test(path)) {
            fullPath = chrome.runtime.getURL(path);
        }
        if (this.modelCache.has(fullPath)) return this.modelCache.get(fullPath);
        if (this.preloadPromises.has(fullPath)) return this.preloadPromises.get(fullPath);
        const promise = (async () => {
            // Ensure THREE ready
            for (let i=0;i<100;i++) {
                if (window.THREE && window.THREE.GLTFLoader) break;
                await new Promise(r=>setTimeout(r,50));
            }
            console.log(`[ISL][PRELOAD][START] ${fullPath}`);
            const loader = new THREE.GLTFLoader();
            if (typeof loader.setCrossOrigin === 'function') loader.setCrossOrigin('anonymous');
            try {
                const gltf = await loader.loadAsync(fullPath);
                this.modelCache.set(fullPath, gltf);
                console.log(`[ISL][PRELOAD][SUCCESS] ${fullPath}`);
                return gltf;
            } catch (e) {
                console.warn(`[ISL][PRELOAD][FAIL] ${fullPath} ${e.message}`);
                throw e;
            } finally {
                this.preloadPromises.delete(fullPath);
            }
        })();
        this.preloadPromises.set(fullPath, promise);
        return promise;
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
                const fnameLower = `${word.word}.glb`;
                const fnameTitle = `${word.word.charAt(0).toUpperCase()}${word.word.slice(1)}.glb`;
                let model = islViewer.availableModels.find(m => m.name.toLowerCase() === fnameLower.toLowerCase());
                const tryPlay = async () => {
                    if (model) {
                        await islViewer.loadAndPlayAnimation(model.path);
                        return true;
                    }
                    // Resolve from Supabase on demand
                    if (window.SupabaseStorage && window.SupabaseStorage.isConfigured && window.SupabaseStorage.isConfigured()) {
                        try {
                            console.log('[Supabase][YouTube] Resolving model for', word.word, 'trying', fnameLower, 'then', fnameTitle);
                            let url = await window.SupabaseStorage.getObjectURL(fnameLower);
                            if (!url) url = await window.SupabaseStorage.getObjectURL(fnameTitle);
                            if (url) {
                                const pickedName = url.includes(fnameTitle) ? fnameTitle : fnameLower;
                                model = { name: pickedName, path: url };
                                islViewer.availableModels.push(model);
                                await islViewer.loadAndPlayAnimation(url);
                                return true;
                            }
                        } catch (_) {}
                    }
                    return false;
                };
                tryPlay().catch(async () => {
                    console.log('[ISL][YouTube] Animation not found, using default for word:', word.word);
                    const fallback = await islViewer.getDefaultModelPath();
                    await islViewer.loadAndPlayAnimation(fallback, { crossFade: 0.25 });
                });
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
