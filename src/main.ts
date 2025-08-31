/**
 * Main entry point for the modern Fake 3D effect
 */

import { Fake3DEffect } from './fake3d'

// Initialize the effect when DOM is ready
function init() {
  try {
    new Fake3DEffect('gl')
  } catch (error) {
    console.error('Failed to initialize Fake3D effect:', error)

    // Show fallback message
    const container = document.getElementById('gl')
    if (container) {
      container.innerHTML = `
        <div style="
          display: flex;
          align-items: center;
          justify-content: center;
          height: 100%;
          color: #666;
          font-family: Arial, sans-serif;
          text-align: center;
          padding: 2rem;
        ">
          <div>
            <h3>WebGL not supported</h3>
            <p>Your browser doesn't support WebGL or it's disabled.</p>
            <p>Please try a modern browser or enable WebGL.</p>
          </div>
        </div>
      `
    }
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init)
} else {
  init()
}
