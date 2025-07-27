// Signify ISL Translator - Background Service Worker

// Extension installation
chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    console.log('Signify ISL Translator installed successfully');
    
    // Set default settings
    chrome.storage.sync.set({
      signifyEnabled: true,
      animationSpeed: 1.0,
      autoStart: false,
      avatarSize: 'medium',
      theme: 'dark'
    });
    
    // Open welcome page
    chrome.tabs.create({
      url: 'https://www.youtube.com/'
    });
  } else if (details.reason === 'update') {
    console.log('Signify ISL Translator updated to version', chrome.runtime.getManifest().version);
  }
});

// Handle extension icon click
chrome.action.onClicked.addListener((tab) => {
  // Check if we're on YouTube
  if (tab.url.includes('youtube.com')) {
    // Toggle Signify panel
    chrome.tabs.sendMessage(tab.id, {
      action: 'toggleSignify'
    });
  } else {
    // Redirect to YouTube
    chrome.tabs.update(tab.id, {
      url: 'https://www.youtube.com/'
    });
  }
});

// Handle messages from content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  switch (request.action) {
    case 'getSettings':
      chrome.storage.sync.get([
        'signifyEnabled',
        'animationSpeed',
        'autoStart',
        'avatarSize',
        'theme'
      ], (result) => {
        sendResponse(result);
      });
      return true; // Keep the message channel open for async response
      
    case 'saveSettings':
      chrome.storage.sync.set(request.settings, () => {
        sendResponse({ success: true });
      });
      return true;
      
    case 'downloadModel':
      // Handle GLB model downloads
      downloadGLBModel(request.modelName, request.url)
        .then((result) => sendResponse(result))
        .catch((error) => sendResponse({ error: error.message }));
      return true;
      
    case 'getTranscript':
      // Extract transcript from YouTube video
      extractVideoTranscript(request.videoId)
        .then((transcript) => sendResponse({ transcript }))
        .catch((error) => sendResponse({ error: error.message }));
      return true;
      
    case 'logError':
      console.error('Signify Error:', request.error);
      break;
      
    case 'logInfo':
      console.log('Signify Info:', request.message);
      break;
  }
});

// Download and cache GLB models
async function downloadGLBModel(modelName, url) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to download model: ${response.statusText}`);
    }
    
    const arrayBuffer = await response.arrayBuffer();
    
    // Store in Chrome storage (note: limited to 8MB per item)
    const base64Data = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));
    
    await chrome.storage.local.set({
      [`model_${modelName}`]: {
        data: base64Data,
        timestamp: Date.now(),
        size: arrayBuffer.byteLength
      }
    });
    
    return { success: true, size: arrayBuffer.byteLength };
  } catch (error) {
    console.error('Error downloading GLB model:', error);
    throw error;
  }
}

// Extract transcript from YouTube video
async function extractVideoTranscript(videoId) {
  try {
    // Note: This would typically require YouTube API access
    // For now, we'll rely on the content script to extract from DOM
    return { message: 'Transcript extraction handled by content script' };
  } catch (error) {
    console.error('Error extracting transcript:', error);
    throw error;
  }
}

// Clean up old cached models (run periodically)
chrome.alarms.create('cleanupModels', { periodInMinutes: 60 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'cleanupModels') {
    cleanupOldModels();
  }
});

async function cleanupOldModels() {
  try {
    const storage = await chrome.storage.local.get();
    const oneWeekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
    
    const keysToRemove = [];
    for (const [key, value] of Object.entries(storage)) {
      if (key.startsWith('model_') && value.timestamp < oneWeekAgo) {
        keysToRemove.push(key);
      }
    }
    
    if (keysToRemove.length > 0) {
      await chrome.storage.local.remove(keysToRemove);
      console.log(`Cleaned up ${keysToRemove.length} old model files`);
    }
  } catch (error) {
    console.error('Error cleaning up old models:', error);
  }
}

// Context menu for quick actions
chrome.contextMenus.create({
  id: 'signify-translate',
  title: 'Translate to ISL',
  contexts: ['selection'],
  documentUrlPatterns: ['*://www.youtube.com/*', '*://youtube.com/*']
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'signify-translate' && info.selectionText) {
    chrome.tabs.sendMessage(tab.id, {
      action: 'translateText',
      text: info.selectionText
    });
  }
});

// Handle tab updates to inject content script
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.url && tab.url.includes('youtube.com')) {
    // Ensure content script is loaded
    chrome.scripting.executeScript({
      target: { tabId: tabId },
      files: ['content.js']
    }).catch(() => {
      // Script might already be injected, ignore error
    });
    
    chrome.scripting.insertCSS({
      target: { tabId: tabId },
      files: ['styles.css']
    }).catch(() => {
      // CSS might already be injected, ignore error
    });
  }
});

// Performance monitoring
let performanceMetrics = {
  translationsStarted: 0,
  errorsEncountered: 0,
  averageLoadTime: 0,
  modelsLoaded: 0
};

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'updateMetrics') {
    performanceMetrics[request.metric] = request.value;
    
    // Store metrics periodically
    chrome.storage.local.set({ performanceMetrics });
  }
});

// Handle extension uninstall
chrome.runtime.setUninstallURL('https://forms.google.com/feedback-form', () => {
  console.log('Uninstall URL set');
});