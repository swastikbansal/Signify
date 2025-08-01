// Simple icon generator for extension
// You can run this in a browser console to generate base64 icons

function createIcon(size) {
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');
    
    // Background
    ctx.fillStyle = '#4CAF50';
    ctx.fillRect(0, 0, size, size);
    
    // Simple sign language hand gesture representation
    ctx.fillStyle = 'white';
    const centerX = size / 2;
    const centerY = size / 2;
    
    // Draw a simple hand-like shape
    ctx.beginPath();
    ctx.arc(centerX, centerY - size * 0.1, size * 0.3, 0, Math.PI * 2);
    ctx.fill();
    
    // Draw fingers
    ctx.fillRect(centerX - size * 0.15, centerY - size * 0.35, size * 0.1, size * 0.25);
    ctx.fillRect(centerX - size * 0.05, centerY - size * 0.4, size * 0.1, size * 0.3);
    ctx.fillRect(centerX + size * 0.05, centerY - size * 0.35, size * 0.1, size * 0.25);
    
    // Add ISL text
    ctx.font = `${size * 0.2}px Arial`;
    ctx.textAlign = 'center';
    ctx.fillText('ISL', centerX, centerY + size * 0.35);
    
    return canvas.toDataURL();
}

// Generate icons for different sizes
console.log('16x16:', createIcon(16));
console.log('48x48:', createIcon(48));
console.log('128x128:', createIcon(128));
