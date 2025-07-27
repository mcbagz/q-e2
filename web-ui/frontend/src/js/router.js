import { DashboardPage } from '../pages/dashboard.js';
import { NewSimulationPage } from '../pages/new-simulation.js';
import { SimulationDetailPage } from '../pages/simulation-detail.js';

export class Router {
  constructor(api, ws) {
    this.api = api;
    this.ws = ws;
    this.routes = {
      '/': () => new DashboardPage(this.api, this),
      '/new': () => new NewSimulationPage(this.api, this),
      '/simulation/:id': (params) => new SimulationDetailPage(this.api, this.ws, this, params.id),
    };
    this.currentPage = null;
  }

  async init() {
    // Handle browser navigation
    window.addEventListener('popstate', () => this.loadRoute());
    
    // Handle link clicks
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-link]')) {
        e.preventDefault();
        this.navigate(e.target.href);
      }
    });

    // Load initial route
    await this.loadRoute();
  }

  navigate(url) {
    window.history.pushState(null, null, url);
    this.loadRoute();
  }

  async loadRoute() {
    const path = window.location.pathname;
    let route = null;
    let params = {};

    // Find matching route
    for (const [pattern, handler] of Object.entries(this.routes)) {
      const regex = new RegExp('^' + pattern.replace(/:[^\s/]+/g, '([\\w-]+)') + '$');
      const match = path.match(regex);
      
      if (match) {
        route = handler;
        
        // Extract params
        const paramNames = pattern.match(/:[^\s/]+/g) || [];
        paramNames.forEach((name, index) => {
          params[name.substring(1)] = match[index + 1];
        });
        
        break;
      }
    }

    if (!route) {
      route = () => new DashboardPage(this.api, this); // Default to dashboard
    }

    // Cleanup current page
    if (this.currentPage && this.currentPage.cleanup) {
      this.currentPage.cleanup();
    }

    // Create and render new page
    this.currentPage = route(params);
    const app = document.getElementById('app');
    app.innerHTML = '';
    
    const pageContent = await this.currentPage.render();
    if (typeof pageContent === 'string') {
      app.innerHTML = pageContent;
    } else {
      app.appendChild(pageContent);
    }

    // Initialize page
    if (this.currentPage.init) {
      await this.currentPage.init();
    }
  }
}