export class DashboardPage {
  constructor(api, router) {
    this.api = api;
    this.router = router;
    this.simulations = [];
  }

  async render() {
    return `
      <div class="container mx-auto px-4 py-8">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-3xl font-bold">Quantum ESPRESSO Simulations</h1>
          <a href="/new" data-link class="btn btn-primary">
            New Simulation
          </a>
        </div>

        <div id="simulations-list" class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <div class="flex justify-center items-center h-32">
            <p class="text-gray-500">Loading simulations...</p>
          </div>
        </div>
      </div>
    `;
  }

  async init() {
    await this.loadSimulations();
  }

  async loadSimulations() {
    try {
      this.simulations = await this.api.getSimulations();
      this.renderSimulations();
    } catch (error) {
      console.error('Failed to load simulations:', error);
      this.renderError(error.message);
    }
  }

  renderSimulations() {
    const container = document.getElementById('simulations-list');
    
    if (this.simulations.length === 0) {
      container.innerHTML = `
        <div class="col-span-full text-center py-8">
          <p class="text-gray-500 mb-4">No simulations yet</p>
          <a href="/new" data-link class="btn btn-primary">
            Create your first simulation
          </a>
        </div>
      `;
      return;
    }

    container.innerHTML = this.simulations.map(sim => this.renderSimulationCard(sim)).join('');
  }

  renderSimulationCard(simulation) {
    const statusColors = {
      'draft': 'bg-gray-100 text-gray-800',
      'running': 'bg-blue-100 text-blue-800',
      'completed': 'bg-green-100 text-green-800',
      'error': 'bg-red-100 text-red-800',
      'stopped': 'bg-yellow-100 text-yellow-800'
    };

    const statusClass = statusColors[simulation.status] || 'bg-gray-100 text-gray-800';

    return `
      <div class="card hover:shadow-lg transition-shadow cursor-pointer" onclick="window.location.href='/simulation/${simulation.id}'">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-lg font-semibold">${simulation.prefix || 'Untitled'}</h3>
          <span class="px-2 py-1 rounded-full text-xs font-medium ${statusClass}">
            ${simulation.status}
          </span>
        </div>
        
        <div class="text-sm text-gray-600 space-y-1">
          <p>Output: ${simulation.outdir || 'Not specified'}</p>
          <p>Created: ${new Date(simulation.created_at).toLocaleString()}</p>
          ${simulation.updated_at ? `<p>Updated: ${new Date(simulation.updated_at).toLocaleString()}</p>` : ''}
        </div>

        <div class="mt-4 flex justify-end space-x-2">
          <a href="/simulation/${simulation.id}" data-link class="btn btn-secondary btn-sm">
            View Details
          </a>
        </div>
      </div>
    `;
  }

  renderError(message) {
    const container = document.getElementById('simulations-list');
    container.innerHTML = `
      <div class="col-span-full">
        <div class="bg-red-50 border border-red-200 rounded-md p-4">
          <p class="text-red-800">Error: ${message}</p>
        </div>
      </div>
    `;
  }
}