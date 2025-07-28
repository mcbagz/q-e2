export class SimulationDetailPage {
  constructor(api, ws, router, simulationId) {
    this.api = api;
    this.ws = ws;
    this.router = router;
    this.simulationId = simulationId;
    this.simulation = null;
    this.logContainer = null;
    this.autoScroll = true;
  }

  async render() {
    return `
      <div class="container mx-auto px-4 py-8">
        <div class="mb-8">
          <a href="/" data-link class="text-blue-600 hover:text-blue-800 mb-4 inline-block">
            ← Back to Dashboard
          </a>
          <div id="simulation-header">
            <div class="animate-pulse">
              <div class="h-8 bg-gray-200 rounded w-1/4 mb-2"></div>
              <div class="h-4 bg-gray-200 rounded w-1/3"></div>
            </div>
          </div>
        </div>

        <div class="grid gap-6 lg:grid-cols-3">
          <div class="lg:col-span-2">
            <div class="card">
              <div class="flex justify-between items-center mb-4">
                <h2 class="text-xl font-semibold">Logs</h2>
                <div class="flex items-center space-x-2">
                  <label class="flex items-center text-sm">
                    <input
                      type="checkbox"
                      id="auto-scroll"
                      checked
                      class="mr-2"
                    />
                    Auto-scroll
                  </label>
                  <button id="clear-logs" class="btn btn-secondary btn-sm">
                    Clear
                  </button>
                </div>
              </div>
              
              <div
                id="log-output"
                class="bg-gray-900 text-gray-100 font-mono text-sm p-4 rounded-md h-96 overflow-y-auto"
              >
                <p class="text-gray-500">Waiting for logs...</p>
              </div>
            </div>
          </div>

          <div class="lg:col-span-1 space-y-6">
            <div id="simulation-controls" class="card">
              <h3 class="text-lg font-semibold mb-4">Controls</h3>
              <div class="space-y-3">
                <button id="run-btn" class="btn btn-primary w-full" disabled>
                  Loading...
                </button>
                <button id="stop-btn" class="btn btn-danger w-full" disabled>
                  Stop
                </button>
                <button id="snapshot-btn" class="btn btn-secondary w-full" disabled>
                  Take Snapshot
                </button>
                <button id="checkpoint-btn" class="btn btn-secondary w-full" disabled>
                  Create Checkpoint
                </button>
              </div>
            </div>

            <div id="simulation-info" class="card">
              <h3 class="text-lg font-semibold mb-4">Information</h3>
              <div class="space-y-2 text-sm">
                <div class="animate-pulse">
                  <div class="h-4 bg-gray-200 rounded w-full mb-2"></div>
                  <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                  <div class="h-4 bg-gray-200 rounded w-1/2"></div>
                </div>
              </div>
            </div>

            <div class="card">
              <h3 class="text-lg font-semibold mb-4">Progress</h3>
              <div id="progress-info" class="space-y-2 text-sm">
                <p class="text-gray-500">No progress data available</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  async init() {
    // Set up event listeners
    this.setupEventListeners();
    
    // Load simulation data
    await this.loadSimulation();
    
    // Start polling if simulation is running
    if (this.simulation && this.simulation.status === 'running') {
      this.startPolling();
    }
  }

  cleanup() {
    // Stop polling
    this.stopPolling();
  }

  startPolling() {
    // Poll every 2 seconds
    this.pollingInterval = setInterval(async () => {
      await this.pollStatus();
    }, 2000);
  }

  stopPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }

  async pollStatus() {
    try {
      const updatedSimulation = await this.api.getSimulation(this.simulationId);
      
      // Check if status changed
      if (updatedSimulation.status !== this.simulation.status) {
        this.simulation = updatedSimulation;
        this.updateUI();
        
        // If no longer running, stop polling and load final logs
        if (updatedSimulation.status !== 'running') {
          this.stopPolling();
          await this.loadLogs();
          
          // Show completion message
          if (updatedSimulation.status === 'completed') {
            this.appendLog('[COMPLETED] Simulation finished successfully', 'status');
          } else if (updatedSimulation.status === 'error') {
            this.appendLog('[ERROR] Simulation failed', 'status');
          }
        }
      }
      
      // Update progress info if simulation is running
      if (updatedSimulation.status === 'running') {
        // Update total energy if changed
        if (updatedSimulation.total_energy && updatedSimulation.total_energy !== this.simulation.total_energy) {
          this.simulation.total_energy = updatedSimulation.total_energy;
          if (!this.progressData) this.progressData = {};
          this.progressData.energy = updatedSimulation.total_energy;
          this.renderProgress();
        }
        
        // Periodically reload logs while running
        await this.loadLogs();
      }
    } catch (error) {
      console.error('Polling error:', error);
    }
  }

  setupEventListeners() {
    // Auto-scroll checkbox
    const autoScrollCheckbox = document.getElementById('auto-scroll');
    autoScrollCheckbox.addEventListener('change', (e) => {
      this.autoScroll = e.target.checked;
    });

    // Clear logs button
    document.getElementById('clear-logs').addEventListener('click', () => {
      this.clearLogs();
    });

    // Control buttons
    document.getElementById('run-btn').addEventListener('click', () => this.runSimulation());
    document.getElementById('stop-btn').addEventListener('click', () => this.stopSimulation());
    document.getElementById('snapshot-btn').addEventListener('click', () => this.takeSnapshot());
    document.getElementById('checkpoint-btn').addEventListener('click', () => this.createCheckpoint());

    // Get log container reference
    this.logContainer = document.getElementById('log-output');
  }

  async loadSimulation() {
    try {
      this.simulation = await this.api.getSimulation(this.simulationId);
      this.updateUI();
      
      // Load logs
      await this.loadLogs();
    } catch (error) {
      console.error('Failed to load simulation:', error);
      this.showError(error.message);
    }
  }

  async loadLogs() {
    try {
      const logs = await this.api.getSimulationLogs(this.simulationId);
      if (logs) {
        this.displayLogs(logs.stdout || logs.logs || '', logs.stderr || '');
      }
    } catch (error) {
      console.error('Failed to load logs:', error);
    }
  }

  updateUI() {
    // Update header
    const headerDiv = document.getElementById('simulation-header');
    headerDiv.innerHTML = `
      <h1 class="text-3xl font-bold">${this.simulation.prefix || 'Untitled Simulation'}</h1>
      <p class="text-gray-600">ID: ${this.simulation.id}</p>
    `;

    // Update info panel
    const infoDiv = document.getElementById('simulation-info');
    const statusColors = {
      'draft': 'text-gray-800',
      'running': 'text-blue-800',
      'completed': 'text-green-800',
      'error': 'text-red-800',
      'stopped': 'text-yellow-800',
      'checkpointed': 'text-purple-800'
    };
    
    infoDiv.innerHTML = `
      <h3 class="text-lg font-semibold mb-4">Information</h3>
      <div class="space-y-2 text-sm">
        <div>
          <span class="font-medium">Status:</span>
          <span class="${statusColors[this.simulation.status] || 'text-gray-800'} font-medium">
            ${this.simulation.status}
          </span>
        </div>
        <div>
          <span class="font-medium">Output Directory:</span>
          <span>${this.simulation.outdir}</span>
        </div>
        <div>
          <span class="font-medium">Calculation:</span>
          <span>${this.simulation.calculation || 'scf'}</span>
        </div>
        <div>
          <span class="font-medium">Created:</span>
          <span>${new Date(this.simulation.created_at).toLocaleString()}</span>
        </div>
        ${this.simulation.updated_at ? `
          <div>
            <span class="font-medium">Updated:</span>
            <span>${new Date(this.simulation.updated_at).toLocaleString()}</span>
          </div>
        ` : ''}
      </div>
    `;

    // Update control buttons based on status
    const runBtn = document.getElementById('run-btn');
    const stopBtn = document.getElementById('stop-btn');
    const snapshotBtn = document.getElementById('snapshot-btn');
    const checkpointBtn = document.getElementById('checkpoint-btn');

    if (this.simulation.status === 'running') {
      runBtn.disabled = true;
      runBtn.textContent = 'Running...';
      stopBtn.disabled = false;
      snapshotBtn.disabled = false;
      checkpointBtn.disabled = false;
    } else if (this.simulation.status === 'checkpointed' && this.simulation.checkpoint_available) {
      runBtn.disabled = false;
      runBtn.textContent = 'Resume from Checkpoint';
      runBtn.onclick = () => this.resumeSimulation();
      stopBtn.disabled = true;
      snapshotBtn.disabled = true;
      checkpointBtn.disabled = true;
    } else if (this.simulation.status === 'draft' || this.simulation.status === 'stopped') {
      runBtn.disabled = false;
      runBtn.textContent = 'Run Simulation';
      runBtn.onclick = () => this.runSimulation();
      stopBtn.disabled = true;
      snapshotBtn.disabled = true;
      checkpointBtn.disabled = true;
    } else {
      runBtn.disabled = false;
      runBtn.textContent = 'Re-run Simulation';
      runBtn.onclick = () => this.runSimulation();
      stopBtn.disabled = true;
      snapshotBtn.disabled = true;
      checkpointBtn.disabled = true;
    }
  }


  displayLogs(stdout, stderr = '') {
    // Clear existing content
    this.logContainer.innerHTML = '';
    
    // Only display stderr (which contains the progress messages)
    if (stderr && stderr.trim()) {
      const logsPre = document.createElement('pre');
      logsPre.className = 'text-gray-100';
      logsPre.textContent = stderr;
      this.logContainer.appendChild(logsPre);
    } else {
      this.logContainer.innerHTML = '<p class="text-gray-500">No logs available yet...</p>';
    }
    
    if (this.autoScroll) {
      this.logContainer.scrollTop = this.logContainer.scrollHeight;
    }
  }

  appendLog(message, stream = 'stdout') {
    const wasAtBottom = this.logContainer.scrollHeight - this.logContainer.scrollTop === this.logContainer.clientHeight;
    
    const logLine = document.createElement('div');
    logLine.textContent = message;
    
    // Style based on stream type
    if (stream === 'stderr') {
      logLine.classList.add('text-yellow-400', 'font-semibold');
    } else if (stream === 'status') {
      logLine.classList.add('text-blue-400', 'font-semibold', 'mt-2');
    }
    
    this.logContainer.appendChild(logLine);
    
    if (this.autoScroll || wasAtBottom) {
      this.logContainer.scrollTop = this.logContainer.scrollHeight;
    }
  }

  clearLogs() {
    this.logContainer.innerHTML = '<p class="text-gray-500">Logs cleared</p>';
  }

  updateProgress(data) {
    if (!this.progressData) {
      this.progressData = {};
    }
    
    // Update stored progress data
    if (data.iteration !== undefined) this.progressData.iteration = data.iteration;
    if (data.energy !== undefined) this.progressData.energy = data.energy;
    if (data.converged !== undefined) this.progressData.converged = data.converged;
    
    this.renderProgress();
  }

  updateAccuracy(accuracy) {
    if (!this.progressData) {
      this.progressData = {};
    }
    this.progressData.accuracy = accuracy;
    this.renderProgress();
  }

  updateCpuTime(cpuTime) {
    if (!this.progressData) {
      this.progressData = {};
    }
    this.progressData.cpuTime = cpuTime;
    this.renderProgress();
  }

  renderProgress() {
    const progressDiv = document.getElementById('progress-info');
    const data = this.progressData || {};
    
    progressDiv.innerHTML = `
      <div class="space-y-2">
        ${data.iteration !== undefined ? `
          <div>
            <span class="font-medium">Iteration:</span>
            <span>${data.iteration}</span>
          </div>
        ` : ''}
        ${data.energy !== undefined ? `
          <div>
            <span class="font-medium">Total Energy:</span>
            <span class="font-mono">${data.energy.toFixed(8)} Ry</span>
          </div>
        ` : ''}
        ${data.accuracy !== undefined ? `
          <div>
            <span class="font-medium">SCF Accuracy:</span>
            <span class="font-mono">${data.accuracy.toExponential(2)} Ry</span>
          </div>
        ` : ''}
        ${data.converged !== undefined ? `
          <div>
            <span class="font-medium">Converged:</span>
            <span class="${data.converged ? 'text-green-600' : 'text-orange-600'} font-medium">
              ${data.converged ? 'Yes' : 'Not yet'}
            </span>
          </div>
        ` : ''}
        ${data.cpuTime !== undefined ? `
          <div>
            <span class="font-medium">CPU Time:</span>
            <span>${data.cpuTime.toFixed(1)} seconds</span>
          </div>
        ` : ''}
      </div>
    `;
  }

  async runSimulation() {
    const runBtn = document.getElementById('run-btn');
    runBtn.disabled = true;
    runBtn.textContent = 'Starting...';

    try {
      await this.api.startSimulation(this.simulationId);
      this.simulation.status = 'running';
      this.updateUI();
      this.clearLogs();
      this.appendLog('[STARTED] Simulation is running...', 'status');
      
      // Start polling for status updates
      this.startPolling();
    } catch (error) {
      console.error('Failed to start simulation:', error);
      this.showError(error.message);
      runBtn.disabled = false;
      runBtn.textContent = 'Run Simulation';
    }
  }

  async resumeSimulation() {
    const runBtn = document.getElementById('run-btn');
    runBtn.disabled = true;
    runBtn.textContent = 'Resuming...';

    try {
      await this.api.resumeSimulation(this.simulationId);
      this.simulation.status = 'running';
      this.updateUI();
      this.appendLog('[RESUMED] Simulation resumed from checkpoint', 'status');
      
      // Start polling for status updates
      this.startPolling();
    } catch (error) {
      console.error('Failed to resume simulation:', error);
      this.showError(error.message);
      runBtn.disabled = false;
      runBtn.textContent = 'Resume from Checkpoint';
    }
  }

  async stopSimulation() {
    const stopBtn = document.getElementById('stop-btn');
    stopBtn.disabled = true;
    stopBtn.textContent = 'Stopping...';

    try {
      await this.api.stopSimulation(this.simulationId);
      this.simulation.status = 'stopped';
      this.updateUI();
    } catch (error) {
      console.error('Failed to stop simulation:', error);
      this.showError(error.message);
      stopBtn.disabled = false;
      stopBtn.textContent = 'Stop';
    }
  }

  async takeSnapshot() {
    const snapshotBtn = document.getElementById('snapshot-btn');
    snapshotBtn.disabled = true;
    snapshotBtn.textContent = 'Taking Snapshot...';

    try {
      await this.api.takeSnapshot(this.simulationId);
      this.appendLog('[INFO] Snapshot requested - sending SIGUSR2 signal to QE process');
    } catch (error) {
      console.error('Failed to take snapshot:', error);
      this.showError(error.message);
    } finally {
      snapshotBtn.disabled = false;
      snapshotBtn.textContent = 'Take Snapshot';
    }
  }

  async createCheckpoint() {
    const checkpointBtn = document.getElementById('checkpoint-btn');
    checkpointBtn.disabled = true;
    checkpointBtn.textContent = 'Creating Checkpoint...';

    try {
      await this.api.createCheckpoint(this.simulationId);
      this.appendLog('[INFO] Checkpoint requested - sending SIGUSR1 signal to QE process');
      // Update status after checkpoint
      this.simulation.status = 'checkpointed';
      this.updateUI();
    } catch (error) {
      console.error('Failed to create checkpoint:', error);
      this.showError(error.message);
      checkpointBtn.disabled = false;
      checkpointBtn.textContent = 'Create Checkpoint';
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  showError(message) {
    // Create a temporary error notification
    const errorDiv = document.createElement('div');
    errorDiv.className = 'fixed top-4 right-4 bg-red-50 border border-red-200 rounded-md p-4 shadow-lg z-50';
    errorDiv.innerHTML = `
      <p class="text-red-800">Error: ${message}</p>
    `;
    
    document.body.appendChild(errorDiv);
    
    // Remove after 5 seconds
    setTimeout(() => {
      errorDiv.remove();
    }, 5000);
  }

  escapeHtml(unsafe) {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
}