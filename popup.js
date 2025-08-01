document.addEventListener('DOMContentLoaded', function() {
    const sentenceInput = document.getElementById('sentenceInput');
    const showViewerBtn = document.getElementById('showViewer');
    const hideViewerBtn = document.getElementById('hideViewer');
    const statusDiv = document.getElementById('status');

    // Load saved sentence from storage
    chrome.storage.local.get(['savedSentence'], function(result) {
        if (result.savedSentence) {
            sentenceInput.value = result.savedSentence;
        }
    });

    // Save sentence when typing
    sentenceInput.addEventListener('input', function() {
        chrome.storage.local.set({savedSentence: sentenceInput.value});
    });

    // Show viewer
    showViewerBtn.addEventListener('click', function() {
        const sentence = sentenceInput.value.trim();
        if (!sentence) {
            statusDiv.textContent = 'Please enter a sentence first.';
            return;
        }

        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            chrome.tabs.sendMessage(tabs[0].id, {
                action: 'showViewer',
                sentence: sentence
            }, function(response) {
                if (chrome.runtime.lastError) {
                    statusDiv.textContent = 'Error: Could not inject viewer. Try refreshing the page.';
                } else {
                    statusDiv.textContent = 'Viewer shown! Processing sentence...';
                }
            });
        });
    });

    // Hide viewer
    hideViewerBtn.addEventListener('click', function() {
        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            chrome.tabs.sendMessage(tabs[0].id, {
                action: 'hideViewer'
            }, function(response) {
                if (chrome.runtime.lastError) {
                    statusDiv.textContent = 'Error: Could not hide viewer.';
                } else {
                    statusDiv.textContent = 'Viewer hidden.';
                }
            });
        });
    });

    // Listen for messages from content script
    chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
        if (request.action === 'updateStatus') {
            statusDiv.textContent = request.status;
        }
    });
});

// Load user settings
async function loadSettings() {
    try {
        const settings = await chrome.storage.sync.get([
            'autoStart',
            'showAvatar'
        ]);

        // Update toggle states - default to true if not set
        updateToggle('autoStartToggle', settings.autoStart !== false);
        updateToggle('showAvatarToggle', settings.showAvatar !== false);
        
        console.log('Loaded settings:', settings);
        
    } catch (error) {
        console.error('Error loading settings:', error);
    }
}

// Load favorite sites
async function loadFavoriteSites() {
    try {
        const data = await chrome.storage.sync.get(['favoriteSites']);
        const sites = data.favoriteSites || [];
        
        const container = document.getElementById('favoriteSites');
        
        // Only clear the saved sites, keep YouTube and Add button from HTML
        const existingButtons = container.querySelectorAll('.site-btn:not(.youtube):not(.add)');
        existingButtons.forEach(btn => btn.remove());
        
        // Add saved sites before the add button
        const addButton = container.querySelector('.add');
        sites.forEach(site => {
            addSiteButton(site.name, site.url, site.icon);
        });
        
    } catch (error) {
        console.error('Error loading favorite sites:', error);
    }
}

// Add site button to the UI
function addSiteButton(name, url, iconUrl = null) {
    const container = document.getElementById('favoriteSites');
    const addButton = container.querySelector('.add');
    
    const siteBtn = document.createElement('button');
    siteBtn.className = 'site-btn';
    siteBtn.title = name;
    siteBtn.onclick = () => openSite(url);
    
    if (iconUrl) {
        const img = document.createElement('img');
        img.src = iconUrl;
        img.width = 24;
        img.height = 24;
        img.style.borderRadius = '4px';
        img.onerror = () => {
            // Fallback if image fails to load
            img.style.display = 'none';
            siteBtn.textContent = name.charAt(0).toUpperCase();
            siteBtn.style.fontSize = '14px';
            siteBtn.style.fontWeight = '600';
            siteBtn.style.background = '#666';
        };
        siteBtn.appendChild(img);
    } else {
        // Use first letter of site name as fallback
        siteBtn.textContent = name.charAt(0).toUpperCase();
        siteBtn.style.fontSize = '14px';
        siteBtn.style.fontWeight = '600';
        siteBtn.style.background = '#666';
    }
    
    // Insert before add button
    if (addButton) {
        container.insertBefore(siteBtn, addButton);
    } else {
        container.appendChild(siteBtn);
    }
}

// Setup event listeners
function setupEventListeners() {
    // Close modal when clicking outside
    document.getElementById('addSiteModal').addEventListener('click', (e) => {
        if (e.target.classList.contains('modal')) {
            hideAddSiteModal();
        }
    });
    
    // Handle Enter key in modal inputs
    document.getElementById('siteName').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') addNewSite();
    });
    
    document.getElementById('siteUrl').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') addNewSite();
    });
}

// Update toggle appearance
function updateToggle(toggleId, isActive) {
    const toggle = document.getElementById(toggleId);
    if (toggle) {
        if (isActive) {
            toggle.classList.add('active');
        } else {
            toggle.classList.remove('active');
        }
        console.log(`Toggle ${toggleId} set to ${isActive ? 'active' : 'inactive'}`);
    }
}

// Toggle setting function called from HTML
async function toggleSetting(setting) {
    console.log('Toggling setting:', setting);
    const toggleElement = document.getElementById(setting + 'Toggle');
    const wasActive = toggleElement.classList.contains('active');
    const isActive = !wasActive;
    
    console.log('Was active:', wasActive, 'Now active:', isActive);
    
    toggleElement.classList.toggle('active', isActive);
    
    // Save setting
    const settings = {};
    settings[setting] = isActive;
    await chrome.storage.sync.set(settings);
    
    console.log('Saved setting:', settings);
    
    // Send message to content script if needed for autoStart
    if (setting === 'autoStart') {
        try {
            const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
            if (tabs[0] && (tabs[0].url.includes('youtube.com'))) {
                chrome.tabs.sendMessage(tabs[0].id, {
                    action: 'updateAutoStart',
                    autoStart: isActive
                });
            }
        } catch (error) {
            console.log('Content script not available or not on YouTube');
        }
    }
}

// Open site function
function openSite(url) {
    chrome.tabs.create({ url: url });
    window.close();
}

// Add site functionality
function addSite() {
    showAddSiteModal();
}

// Show add site modal
function showAddSiteModal() {
    console.log('Showing add site modal...');
    document.getElementById('addSiteModal').classList.remove('hidden');
    document.getElementById('siteName').focus();
}

// Hide add site modal
function hideAddSiteModal() {
    console.log('Hiding add site modal...');
    document.getElementById('addSiteModal').classList.add('hidden');
    document.getElementById('siteName').value = '';
    document.getElementById('siteUrl').value = '';
}

// Add new site
async function addNewSite() {
    console.log('Adding new site...');
    const nameInput = document.getElementById('siteName');
    const urlInput = document.getElementById('siteUrl');
    
    if (!nameInput || !urlInput) {
        console.error('Input elements not found');
        return;
    }
    
    const name = nameInput.value.trim();
    let url = urlInput.value.trim();
    
    console.log('Site name:', name, 'URL:', url);
    
    if (!name || !url) {
        alert('Please enter both site name and URL');
        return;
    }
    
    // Add https:// if no protocol is specified
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://' + url;
    }
    
    // Validate URL
    try {
        new URL(url);
    } catch (error) {
        alert('Please enter a valid URL');
        return;
    }
    
    console.log('URL validation passed, fetching favicon...');
    
    // Try to fetch favicon (with shorter timeout to prevent hanging)
    let iconUrl = null;
    try {
        iconUrl = await getFavicon(url);
        console.log('Favicon URL:', iconUrl);
    } catch (error) {
        console.log('Favicon fetch failed, continuing without icon:', error);
    }
    
    // Save to storage
    try {
        const data = await chrome.storage.sync.get(['favoriteSites']);
        const sites = data.favoriteSites || [];
        
        const newSite = { name, url, icon: iconUrl };
        sites.push(newSite);
        await chrome.storage.sync.set({ favoriteSites: sites });
        
        console.log('Site saved to storage:', newSite);
        
        // Add to UI
        addSiteButton(name, url, iconUrl);
        console.log('Site button added to UI');
        
        // Close modal
        hideAddSiteModal();
        
    } catch (error) {
        console.error('Error saving site:', error);
        alert('Error saving site. Please try again.');
    }
}

// Get favicon for a URL
async function getFavicon(url) {
    try {
        const domain = new URL(url).origin;
        const faviconUrl = `${domain}/favicon.ico`;
        
        // Test if favicon exists with a shorter timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 1500); // 1.5 second timeout
        
        const response = await fetch(faviconUrl, { 
            method: 'HEAD',
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (response.ok) {
            return faviconUrl;
        }
    } catch (error) {
        console.log('Could not fetch favicon:', error);
    }
    
    return null;
}

// Open help page
function openHelp() {
    console.log('Opening help page...');
    try {
        const helpUrl = chrome.runtime.getURL('help.html');
        console.log('Help URL:', helpUrl);
        chrome.tabs.create({ url: helpUrl });
        window.close();
    } catch (error) {
        console.error('Error opening help page:', error);
        // Fallback: try to open in same tab
        window.open('help.html', '_blank');
    }
}
