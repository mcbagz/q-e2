export class ApiClient {
  constructor() {
    this.baseUrl = '/api';
  }

  async fetch(endpoint, options = {}) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
      throw new Error(error.detail || `HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  // Simulations API
  async getSimulations() {
    return this.fetch('/simulations');
  }

  async getSimulation(id) {
    return this.fetch(`/simulations/${id}`);
  }

  async createSimulation(data) {
    return this.fetch('/simulations', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async startSimulation(id) {
    return this.fetch(`/simulations/${id}/start`, {
      method: 'POST',
    });
  }

  async stopSimulation(id) {
    return this.fetch(`/simulations/${id}/stop`, {
      method: 'POST',
    });
  }

  async deleteSimulation(id) {
    return this.fetch(`/simulations/${id}`, {
      method: 'DELETE',
    });
  }

  async getSimulationLogs(id) {
    return this.fetch(`/simulations/${id}/logs`);
  }
}