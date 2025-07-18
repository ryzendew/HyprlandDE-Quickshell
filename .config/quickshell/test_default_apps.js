#!/usr/bin/env node

// Simple test script to verify default apps functionality
const { execSync } = require('child_process');

console.log("Testing default apps functionality...");

// Test 1: Check current HTTP handler
try {
    const currentHttp = execSync('xdg-mime query default x-scheme-handler/http', { encoding: 'utf8' }).trim();
    console.log(`Current HTTP handler: ${currentHttp}`);
} catch (error) {
    console.error("Error querying HTTP handler:", error.message);
}

// Test 2: Set Microsoft Edge as default
try {
    console.log("Setting Microsoft Edge as default browser...");
    execSync('xdg-mime default microsoft-edge-dev.desktop x-scheme-handler/http');
    execSync('xdg-mime default microsoft-edge-dev.desktop x-scheme-handler/https');
    console.log("Successfully set Microsoft Edge as default browser");
} catch (error) {
    console.error("Error setting Microsoft Edge:", error.message);
}

// Test 3: Verify the change
try {
    const newHttp = execSync('xdg-mime query default x-scheme-handler/http', { encoding: 'utf8' }).trim();
    console.log(`New HTTP handler: ${newHttp}`);
    
    if (newHttp === 'microsoft-edge-dev.desktop') {
        console.log("✅ SUCCESS: Microsoft Edge is now the default browser");
    } else {
        console.log("❌ FAILED: Microsoft Edge is not the default browser");
    }
} catch (error) {
    console.error("Error verifying change:", error.message);
}

// Test 4: Check available desktop entries
try {
    console.log("\nAvailable Microsoft Edge desktop entries:");
    const edgeEntries = execSync('find /usr/share/applications -name "*edge*" -o -name "*microsoft*"', { encoding: 'utf8' });
    console.log(edgeEntries);
} catch (error) {
    console.error("Error finding Edge entries:", error.message);
} 