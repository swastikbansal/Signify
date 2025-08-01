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
