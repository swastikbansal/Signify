// Signify ISL Translator - Popup Script

document.addEventListener('DOMContentLoaded', initializePopup);

async function initializePopup() {
    await loadSettings();
    await loadStats();
    checkCurrentTab();
    setupEventListeners();
    startStatusUpdates();
}

// Load user settings
async function loadSettings() {
    try {
        const settings = await chrome.storage.sync.get([
            'autoStart',
            'showAvatar',
            'highQuality',
            'signifyEnabled'
        ]);

        // Update toggle states
        updateToggle('autoStartToggle', settings.autoStart || false);
        updateToggle('showAvatarToggle', settings.showAvatar !== false);
        updateToggle('highQualityToggle', settings.highQuality !== false);
        
    } catch (error) {
        console.error('Error loading settings:', error);
    }
}

// Load usage statistics
async function loadStats() {
    try {
        const stats = await chrome.storage.local.get([
            'videosTranslated',
            'wordsTranslated',
            'totalUsageTime'
        ]);

        document.getElementById('videosTranslated').textContent = stats.videosTranslated || 0;
        document.getElementById('wordsTranslated').textContent = stats.wordsTranslated || 0;
        
    } catch (error) {
        console.error('Error loading stats:', error);
    }
}

// Check current tab and update status
async function checkCurrentTab() {
    try {
        const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
        
        if (tab.url.includes('youtube.com')) {
            updateStatus('Ready to translate', 'YouTube detected - Click the Signify button on videos');
            checkModelStatus();
        } else {
            updateStatus('Not on YouTube', 'Navigate to YouTube to use Signify');
            updateModelStatus('inactive', 'Model inactive');
        }
    } catch (error) {
        console.error('Error checking current tab:', error);
        updateStatus('Error', 'Could not check current page');
    }
}

// Setup event listeners
function setupEventListeners() {
    // Quick action buttons
    document.getElementById('openYouTubeBtn').addEventListener('click', openYouTube);
    document.getElementById('settingsBtn').addEventListener('click', toggleSettings);
    document.getElementById('helpBtn').addEventListener('click', openHelp);
    
    // Setting toggles
    document.getElementById('autoStartToggle').addEventListener('click', () => {
        toggleSetting('autoStartToggle', 'autoStart');
    });
    
    document.getElementById('showAvatarToggle').addEventListener('click', () => {
        toggleSetting('showAvatarToggle', 'showAvatar');
    });
    
    document.getElementById('highQualityToggle').addEventListener('click', () => {
        toggleSetting('highQualityToggle', 'highQuality');
    });
}

// Update status display
function updateStatus(status, detail) {
    document.getElementById('statusText').textContent = status;
    document.getElementById('statusDetail').textContent = detail;
}

// Update model status
function updateModelStatus(status, text) {
    const dot = document.getElementById('modelStatusDot');
    const statusText = document.getElementById('modelStatusText');
    
    dot.className = status === 'active' ? 'status-dot active' : 'status-dot';
    statusText.textContent = text;
}

// Check model loading status
async function checkModelStatus() {
    try {
        // Check if avatar model is cached
        const modelData = await chrome.storage.local.get('model_avatar');
        
        if (modelData.model_avatar) {
            updateModelStatus('active', 'Avatar model ready');
        } else {
            updateModelStatus('inactive', 'Downloading avatar model...');
            showProgress(0);
            
            // Simulate model download progress
            let progress = 0;
            const progressInterval = setInterval(() => {
                progress += Math.random() * 15;
                if (progress >= 100) {
                    progress = 100;
                    clearInterval(progressInterval);
                    hideProgress();
                    updateModelStatus('active', 'Avatar model ready');
                }
                showProgress(progress);
            }, 200);
        }
    } catch (error) {
        console.error('Error checking model status:', error);
        updateModelStatus('inactive', 'Model loading failed');
    }
}

// Show/hide progress bar
function showProgress(percentage) {
    const progressBar = document.getElementById('progressBar');
    const progressFill = document.getElementById('progressFill');
    
    progressBar.classList.remove('hidden');
    progressFill.style.width = percentage + '%';
}

function hideProgress() {
    document.getElementById('progressBar').classList.add('hidden');
}

// Update toggle state
function updateToggle(toggleId, isActive) {
    const toggle = document.getElementById(toggleId);
    if (isActive) {
        toggle.classList.add('active');
    } else {
        toggle.classList.remove('active');
    }
}

// Toggle setting and save
async function toggleSetting(toggleId, settingKey) {
    const toggle = document.getElementById(toggleId);
    const isActive = !toggle.classList.contains('active');
    
    updateToggle(toggleId, isActive);
    
    // Save setting
    try {
        await chrome.storage.sync.set({ [settingKey]: isActive });
        
        // Send message to content script if on YouTube
        const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
        if (tab.url.includes('youtube.com')) {
            chrome.tabs.sendMessage(tab.id, {
                action: 'settingChanged',
                setting: settingKey,
                value: isActive
            }).catch(() => {
                // Content script might not be loaded, ignore error
            });
        }
    } catch (error) {
        console.error('Error saving setting:', error);
        // Revert toggle state on error
        updateToggle(toggleId, !isActive);
    }
}

// Open YouTube in new tab
async function openYouTube() {
    try {
        await chrome.tabs.create({ url: 'https://www.youtube.com/' });
        window.close();
    } catch (error) {
        console.error('Error opening YouTube:', error);
    }
}

// Toggle settings panel
function toggleSettings() {
    const settingsSection = document.getElementById('settingsSection');
    const statsSection = document.getElementById('statsSection');
    
    if (settingsSection.classList.contains('hidden')) {
        settingsSection.classList.remove('hidden');
        statsSection.classList.add('hidden');
        document.getElementById('settingsBtn').textContent = '📊 Statistics';
    } else {
        settingsSection.classList.add('hidden');
        statsSection.classList.remove('hidden');
        document.getElementById('settingsBtn').textContent = '⚙️ Settings';
    }
}

// Open help page
function openHelp() {
    chrome.tabs.create({ 
        url: 'https://github.com/your-repo/signify-help' 
    });
    window.close();
}

// Start periodic status updates
function startStatusUpdates() {
    // Update status every 5 seconds
    setInterval(async () => {
        await checkCurrentTab();
        await loadStats();
    }, 5000);
}

// Listen for messages from content script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    switch (request.action) {
        case 'updateStatus':
            updateStatus(request.status, request.detail);
            break;
            
        case 'updateModelStatus':
            updateModelStatus(request.status, request.text);
            break;
            
        case 'updateProgress':
            showProgress(request.percentage);
            break;
            
        case 'hideProgress':
            hideProgress();
            break;
            
        case 'updateStats':
            if (request.videosTranslated !== undefined) {
                document.getElementById('videosTranslated').textContent = request.videosTranslated;
            }
            if (request.wordsTranslated !== undefined) {
                document.getElementById('wordsTranslated').textContent = request.wordsTranslated;
            }
            break;
    }
});

// Handle popup close
window.addEventListener('beforeunload', () => {
    // Save any pending changes
    console.log('Popup closing');
});