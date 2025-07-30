// Signify ISL Translator - Side Panel Script

let avatarActive = false;
let currentAnimation = null;

document.addEventListener('DOMContentLoaded', initializeSidePanel);

async function initializeSidePanel() {
    console.log('Side panel initialized');
    await checkYouTubeTab();
    setupMessageListener();
    setupTabListener();
}

// Check if current tab is YouTube
async function checkYouTubeTab() {
    try {
        const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
        const currentTab = tabs[0];
        
        if (currentTab && currentTab.url.includes('youtube.com/watch')) {
            updateStatus('YouTube Video Detected', 'Avatar ready to translate sign language');
            initializeAvatarForCurrentVideo();
        } else if (currentTab && currentTab.url.includes('youtube.com')) {
            updateStatus('On YouTube', 'Navigate to a video to start translation');
        } else {
            updateStatus('Not on YouTube', 'Please navigate to YouTube to use Signify');
        }
    } catch (error) {
        console.error('Error checking YouTube tab:', error);
        updateStatus('Error', 'Could not check current page');
    }
}

// Initialize avatar for current video
async function initializeAvatarForCurrentVideo() {
    try {
        const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
        const currentTab = tabs[0];
        
        if (currentTab && currentTab.url.includes('youtube.com/watch')) {
            showLoading(true);
            
            // Send message to content script to initialize avatar in side panel mode
            chrome.tabs.sendMessage(currentTab.id, {
                action: 'initializeSidePanelAvatar'
            });
        }
    } catch (error) {
        console.error('Error initializing avatar:', error);
        showLoading(false);
    }
}

// Setup message listener
function setupMessageListener() {
    chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
        console.log('Side panel received message:', request);
        
        switch (request.action) {
            case 'updateSidePanelStatus':
                updateStatus(request.status, request.detail);
                break;
                
            case 'showAvatarInSidePanel':
                showAvatarContainer(request.avatarData);
                break;
                
            case 'updateSidePanelAnimation':
                updateAnimation(request.animation);
                break;
                
            case 'sidePanelLoading':
                showLoading(request.loading);
                break;
                
            case 'avatarError':
                handleAvatarError(request.error);
                break;
        }
    });
}

// Setup tab listener
function setupTabListener() {
    chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
        if (changeInfo.status === 'complete') {
            checkYouTubeTab();
        }
    });
    
    chrome.tabs.onActivated.addListener(() => {
        checkYouTubeTab();
    });
}

// Update status display
function updateStatus(status, detail) {
    document.getElementById('statusText').textContent = status;
    document.getElementById('statusDetail').textContent = detail;
}

// Show/hide loading indicator
function showLoading(show) {
    const loadingIndicator = document.getElementById('loadingIndicator');
    const avatarPlaceholder = document.getElementById('avatarPlaceholder');
    
    if (show) {
        loadingIndicator.classList.remove('hidden');
        avatarPlaceholder.classList.add('hidden');
    } else {
        loadingIndicator.classList.add('hidden');
        avatarPlaceholder.classList.remove('hidden');
    }
}

// Show avatar container
function showAvatarContainer(avatarData) {
    const container = document.getElementById('avatarContainer');
    const placeholder = document.getElementById('avatarPlaceholder');
    const loading = document.getElementById('loadingIndicator');
    
    // Hide loading and placeholder
    loading.classList.add('hidden');
    placeholder.classList.add('hidden');
    
    // Create or update avatar display
    let avatarDisplay = document.getElementById('avatarDisplay');
    if (!avatarDisplay) {
        avatarDisplay = document.createElement('div');
        avatarDisplay.id = 'avatarDisplay';
        avatarDisplay.style.width = '100%';
        avatarDisplay.style.height = '100%';
        avatarDisplay.style.display = 'flex';
        avatarDisplay.style.alignItems = 'center';
        avatarDisplay.style.justifyContent = 'center';
        avatarDisplay.style.fontSize = '48px';
        container.appendChild(avatarDisplay);
    }
    
    // For now, show a placeholder for the 3D avatar
    // In a full implementation, this would render the actual 3D model
    avatarDisplay.innerHTML = `
        <div style="text-align: center;">
            <div style="font-size: 48px; margin-bottom: 10px;">🤖</div>
            <div style="font-size: 14px; color: #FFBF00;">Avatar Active</div>
            <div style="font-size: 12px; color: #666; margin-top: 4px;">Translating video content</div>
        </div>
    `;
    
    avatarActive = true;
    updateControlButtons();
}

// Update animation
function updateAnimation(animation) {
    if (!avatarActive) return;
    
    currentAnimation = animation;
    console.log('Playing animation:', animation);
    
    // Update avatar display to show current animation
    const avatarDisplay = document.getElementById('avatarDisplay');
    if (avatarDisplay) {
        // Add visual feedback for animation changes
        avatarDisplay.style.transform = 'scale(1.05)';
        setTimeout(() => {
            avatarDisplay.style.transform = 'scale(1)';
        }, 200);
    }
}

// Handle avatar error
function handleAvatarError(error) {
    console.error('Avatar error:', error);
    showLoading(false);
    updateStatus('Error', 'Could not load avatar. Please refresh the page.');
    
    const container = document.getElementById('avatarContainer');
    const placeholder = document.getElementById('avatarPlaceholder');
    placeholder.innerHTML = `
        <div>❌</div>
        <div style="margin-top: 8px; font-size: 14px;">Avatar Error</div>
        <div style="margin-top: 4px; font-size: 12px; color: #666;">${error}</div>
    `;
    placeholder.classList.remove('hidden');
}

// Control functions
function togglePlay() {
    if (!avatarActive) return;
    
    const playBtn = document.getElementById('playBtn');
    playBtn.classList.add('active');
    document.getElementById('pauseBtn').classList.remove('active');
    
    // Send message to content script
    sendMessageToContentScript('playAvatar');
}

function togglePause() {
    if (!avatarActive) return;
    
    const pauseBtn = document.getElementById('pauseBtn');
    pauseBtn.classList.add('active');
    document.getElementById('playBtn').classList.remove('active');
    
    // Send message to content script
    sendMessageToContentScript('pauseAvatar');
}

function resetAvatar() {
    if (!avatarActive) return;
    
    document.getElementById('resetBtn').classList.add('active');
    setTimeout(() => {
        document.getElementById('resetBtn').classList.remove('active');
    }, 200);
    
    // Send message to content script
    sendMessageToContentScript('resetAvatar');
}

// Update control button states
function updateControlButtons() {
    const buttons = document.querySelectorAll('.control-btn');
    buttons.forEach(btn => {
        btn.disabled = !avatarActive;
        btn.style.opacity = avatarActive ? '1' : '0.5';
    });
}

// Send message to content script
async function sendMessageToContentScript(action) {
    try {
        const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
        const currentTab = tabs[0];
        
        if (currentTab && currentTab.url.includes('youtube.com')) {
            chrome.tabs.sendMessage(currentTab.id, { action });
        }
    } catch (error) {
        console.error('Error sending message to content script:', error);
    }
}

// Initial button state
updateControlButtons();
