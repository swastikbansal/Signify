// Simple THREE.js test file for debugging
console.log('Signify: Simple test script loaded');

// Simple THREE.js test file for debugging
console.log('Signify: Simple test script loaded');

function simpleThreeTest() {
    console.log('Signify: Starting simple THREE.js test');
    
    const container = document.getElementById('avatarDisplay');
    if (!container) {
        console.error('Signify: Container not found');
        return;
    }
    
    container.innerHTML = '<div style="color: white; padding: 20px;">Testing THREE.js access...</div>';
    
    // First, let's check if we can access the file directly
    const threeUrl = chrome.runtime.getURL('three.min.js');
    console.log('Signify: Testing file access to:', threeUrl);
    
    // Test file access with fetch
    fetch(threeUrl)
        .then(response => {
            console.log('Signify: Fetch response status:', response.status);
            if (response.ok) {
                container.innerHTML = '<div style="color: green; padding: 20px;">✅ File is accessible via fetch</div>';
                return response.text();
            } else {
                throw new Error('HTTP ' + response.status);
            }
        })
        .then(content => {
            console.log('Signify: File size:', content.length, 'bytes');
            console.log('Signify: File starts with:', content.substring(0, 100));
            console.log('Signify: File contains THREE:', content.includes('THREE'));
            
            // Now try script injection method
            container.innerHTML = '<div style="color: yellow; padding: 20px;">📜 File loaded, trying script injection...</div>';
            loadThreeJSScript(threeUrl, container);
        })
        .catch(error => {
            console.error('Signify: File access error:', error);
            container.innerHTML = '<div style="color: red; padding: 20px;">❌ Cannot access file: ' + error.message + '</div>';
        });
}

function loadThreeJSScript(threeUrl, container) {
    console.log('Signify: Creating script element for:', threeUrl);
    
    const script = document.createElement('script');
    script.src = threeUrl;
    script.type = 'text/javascript';
    
    script.onload = function() {
        console.log('Signify: Script onload fired');
        console.log('Signify: window.THREE type:', typeof window.THREE);
        console.log('Signify: window.THREE object:', window.THREE);
        
        if (window.THREE) {
            container.innerHTML = '<div style="color: green; padding: 20px;">✅ THREE.js loaded successfully!</div>';
            setTimeout(() => createTestScene(container), 1000);
        } else {
            container.innerHTML = '<div style="color: orange; padding: 20px;">⚠️ Script loaded but window.THREE undefined</div>';
        }
    };
    
    script.onerror = function(event) {
        console.error('Signify: Script error:', event);
        container.innerHTML = '<div style="color: red; padding: 20px;">❌ Script loading failed</div>';
    };
    
    document.head.appendChild(script);
    console.log('Signify: Script element added to DOM');
}

function createTestScene(container) {
    try {
        container.innerHTML = '';
        
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x000033);
        
        const camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
        camera.position.z = 5;
        
        const renderer = new THREE.WebGLRenderer();
        renderer.setSize(container.clientWidth, container.clientHeight);
        container.appendChild(renderer.domElement);
        
        const geometry = new THREE.BoxGeometry();
        const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
        const cube = new THREE.Mesh(geometry, material);
        scene.add(cube);
        
        function animate() {
            requestAnimationFrame(animate);
            cube.rotation.x += 0.01;
            cube.rotation.y += 0.01;
            renderer.render(scene, camera);
        }
        animate();
        
        console.log('Signify: Test scene created successfully!');
        
    } catch (error) {
        console.error('Signify: Error creating test scene:', error);
        container.innerHTML = '<div style="color: red; padding: 20px;">❌ Error: ' + error.message + '</div>';
    }
}

// Replace the complex initializeAvatar function with this simple test
if (typeof window !== 'undefined') {
    window.initializeAvatar = simpleThreeTest;
    window.simpleThreeTest = simpleThreeTest;
}
