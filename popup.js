document.addEventListener('DOMContentLoaded', async () => {
    try {
        await loadSettings();
        await loadFavoriteSites();
        setupEventListeners();
    wireStaticButtons();
    await loadTransparencySettings();
    } catch (e) {
        console.error('Popup init failed', e);
    }
});

// Load user settings
async function loadSettings() {
    try {
    const settings = await chrome.storage.sync.get(['autoStart']);
    updateToggle('autoStartToggle', settings.autoStart !== false);
        
        console.log('Loaded settings:', settings);
        
    } catch (error) {
        console.error('Error loading settings:', error);
    }
}

// Load transparency / panel settings from local storage
async function loadTransparencySettings() {
    try {
        const local = await chrome.storage.local.get(['signifyPanelAlpha','signifyPanelVisible']);
        const visible = !!local.signifyPanelVisible;
        updateToggle('panelBgToggle', visible);
        const controls = document.getElementById('panelBgControls');
        if (controls) controls.style.display = visible ? 'flex' : 'none';
        const alpha = (typeof local.signifyPanelAlpha === 'number') ? local.signifyPanelAlpha : 0.55;
        const range = document.getElementById('panelAlphaRange');
        const val = document.getElementById('panelAlphaValue');
        if (range) range.value = Math.round(alpha*100);
        if (val) val.textContent = Math.round(alpha*100)+'%';
    } catch (e) { console.warn('Transparency load failed', e); }
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

function wireStaticButtons() {
    // Toggle auto-start via click
    const autoToggle = document.getElementById('autoStartToggle');
    if (autoToggle) {
        autoToggle.addEventListener('click', () => toggleSetting('autoStart'));
        autoToggle.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                toggleSetting('autoStart');
            }
        });
    }
    const bgToggle = document.getElementById('panelBgToggle');
    if (bgToggle) {
        bgToggle.addEventListener('click', togglePanelBackground);
        bgToggle.addEventListener('keydown', (e)=>{ if(e.key==='Enter'||e.key===' '){ e.preventDefault(); togglePanelBackground(); }});
    }
    const alphaRange = document.getElementById('panelAlphaRange');
    if (alphaRange) {
        alphaRange.addEventListener('input', handleAlphaChange);
    }
    // Favorite site static buttons
    const ytBtn = document.getElementById('favYouTube');
    if (ytBtn) ytBtn.addEventListener('click', () => openSite('https://www.youtube.com'));
    const addBtn = document.getElementById('favAdd');
    if (addBtn) addBtn.addEventListener('click', addSite);
    const helpBtn = document.getElementById('helpBtn');
    if (helpBtn) helpBtn.addEventListener('click', openHelp);
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

async function togglePanelBackground() {
    const toggleElement = document.getElementById('panelBgToggle');
    if (!toggleElement) return;
    const willActivate = !toggleElement.classList.contains('active');
    toggleElement.classList.toggle('active', willActivate);
    // Show/hide controls
    const controls = document.getElementById('panelBgControls');
    if (controls) controls.style.display = willActivate ? 'flex' : 'none';
    await chrome.storage.local.set({ signifyPanelVisible: willActivate });
    // Send message to active tab to update immediately
    try {
        const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
        if (tabs[0]) {
            chrome.tabs.sendMessage(tabs[0].id, { action: 'updateTransparency', visible: willActivate });
        }
    } catch (e) { console.log('Could not send visibility update', e); }
}

async function handleAlphaChange(e) {
    const range = e.target;
    const val = document.getElementById('panelAlphaValue');
    const pct = parseInt(range.value,10);
    if (val) val.textContent = pct+'%';
    const alpha = pct/100;
    await chrome.storage.local.set({ signifyPanelAlpha: alpha });
    try {
        const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
        if (tabs[0]) {
            chrome.tabs.sendMessage(tabs[0].id, { action: 'updateTransparency', alpha });
        }
    } catch (err) { console.log('Alpha update message failed', err); }
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
