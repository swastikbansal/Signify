// Fallback 3D Avatar using pure CSS and DOM manipulation
// This provides a working avatar when THREE.js fails to load

function createFallbackAvatar(container) {
    console.log('Signify: Creating fallback CSS-based avatar');
    
    container.innerHTML = `
        <div class="css-avatar-container">
            <div class="css-avatar">
                <div class="avatar-head"></div>
                <div class="avatar-body"></div>
                <div class="avatar-arm avatar-arm-left"></div>
                <div class="avatar-arm avatar-arm-right"></div>
                <div class="avatar-status">🤟 ISL Ready</div>
            </div>
        </div>
    `;
    
    // Add CSS styles
    const style = document.createElement('style');
    style.textContent = `
        .css-avatar-container {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            position: relative;
            overflow: hidden;
        }
        
        .css-avatar {
            position: relative;
            transform-style: preserve-3d;
            animation: avatarFloat 3s ease-in-out infinite;
        }
        
        .avatar-head {
            width: 40px;
            height: 40px;
            background: #fdbcb4;
            border-radius: 50%;
            position: relative;
            margin: 0 auto 5px;
            border: 2px solid #f1c27d;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
        }
        
        .avatar-head::before {
            content: '👤';
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            font-size: 20px;
        }
        
        .avatar-body {
            width: 50px;
            height: 60px;
            background: #4CAF50;
            border-radius: 10px;
            position: relative;
            margin: 0 auto;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
        }
        
        .avatar-arm {
            width: 15px;
            height: 40px;
            background: #fdbcb4;
            border-radius: 10px;
            position: absolute;
            top: 45px;
            animation: armWave 2s ease-in-out infinite;
            box-shadow: 0 1px 5px rgba(0,0,0,0.1);
        }
        
        .avatar-arm-left {
            left: -10px;
            transform-origin: top center;
            animation-delay: 0s;
        }
        
        .avatar-arm-right {
            right: -10px;
            transform-origin: top center;
            animation-delay: 1s;
        }
        
        .avatar-status {
            position: absolute;
            bottom: -30px;
            left: 50%;
            transform: translateX(-50%);
            color: white;
            font-size: 12px;
            font-weight: bold;
            text-shadow: 0 1px 2px rgba(0,0,0,0.5);
            white-space: nowrap;
        }
        
        @keyframes avatarFloat {
            0%, 100% { transform: translateY(0px) rotateY(0deg); }
            50% { transform: translateY(-10px) rotateY(5deg); }
        }
        
        @keyframes armWave {
            0%, 100% { transform: rotate(0deg); }
            25% { transform: rotate(-20deg); }
            75% { transform: rotate(20deg); }
        }
        
        .css-avatar-container::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: linear-gradient(45deg, transparent 30%, rgba(255,255,255,0.1) 50%, transparent 70%);
            animation: shine 4s ease-in-out infinite;
        }
        
        @keyframes shine {
            0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
            100% { transform: translateX(100%) translateY(100%) rotate(45deg); }
        }
    `;
    document.head.appendChild(style);
    
    console.log('Signify: Fallback avatar created successfully');
    return true;
}

// Export for use in main content script
if (typeof window !== 'undefined') {
    window.createFallbackAvatar = createFallbackAvatar;
}
