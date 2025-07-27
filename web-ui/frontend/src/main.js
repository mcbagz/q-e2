import './styles/main.css';
import { Router } from './js/router.js';
import { ApiClient } from './js/api.js';
import { WebSocketClient } from './js/websocket.js';

// Initialize the application
class App {
  constructor() {
    this.api = new ApiClient();
    this.ws = new WebSocketClient();
    this.router = new Router(this.api, this.ws);
  }

  async init() {
    // Initialize router
    await this.router.init();
    
    // Don't connect WebSocket here - it needs a simulation ID
    // WebSocket will be connected when viewing a specific simulation
  }
}

// Start the application when DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
  const app = new App();
  await app.init();
});