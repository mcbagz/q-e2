export class NewSimulationPage {
  constructor(api, router) {
    this.api = api;
    this.router = router;
  }

  render() {
    return `
      <div class="container mx-auto px-4 py-8 max-w-2xl">
        <div class="mb-8">
          <a href="/" data-link class="text-blue-600 hover:text-blue-800 mb-4 inline-block">
            ← Back to Dashboard
          </a>
          <h1 class="text-3xl font-bold">Create New Simulation</h1>
        </div>

        <form id="new-simulation-form" class="space-y-6">
          <div class="card">
            <h2 class="text-xl font-semibold mb-4">Basic Settings</h2>
            
            <div class="space-y-4">
              <div>
                <label for="prefix" class="label">
                  Prefix <span class="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  id="prefix"
                  name="prefix"
                  class="input"
                  placeholder="e.g., silicon_scf"
                  required
                />
                <p class="text-sm text-gray-500 mt-1">
                  A unique identifier for your simulation
                </p>
              </div>

              <div>
                <label for="outdir" class="label">
                  Output Directory <span class="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  id="outdir"
                  name="outdir"
                  class="input"
                  placeholder="e.g., ./output"
                  value="./output"
                  required
                />
                <p class="text-sm text-gray-500 mt-1">
                  Directory where output files will be saved
                </p>
              </div>

              <div>
                <label for="calculation" class="label">
                  Calculation Type
                </label>
                <select id="calculation" name="calculation" class="input">
                  <option value="scf">Self-Consistent Field (SCF)</option>
                  <option value="relax">Structure Relaxation</option>
                  <option value="vc-relax">Variable Cell Relaxation</option>
                  <option value="md">Molecular Dynamics</option>
                  <option value="nscf">Non-SCF</option>
                  <option value="bands">Band Structure</option>
                </select>
              </div>
            </div>
          </div>

          <div class="card">
            <h2 class="text-xl font-semibold mb-4">Advanced Options</h2>
            
            <div class="space-y-4">
              <div>
                <label for="input_content" class="label">
                  Custom Input File Content (Optional)
                </label>
                <textarea
                  id="input_content"
                  name="input_content"
                  class="input font-mono text-sm"
                  rows="10"
                  placeholder="Paste your QE input file content here..."
                ></textarea>
                <p class="text-sm text-gray-500 mt-1">
                  Leave empty to use default template
                </p>
              </div>
            </div>
          </div>

          <div class="flex justify-end space-x-4">
            <a href="/" data-link class="btn btn-secondary">
              Cancel
            </a>
            <button type="submit" class="btn btn-primary">
              Create Simulation
            </button>
          </div>
        </form>
      </div>
    `;
  }

  init() {
    const form = document.getElementById('new-simulation-form');
    form.addEventListener('submit', (e) => this.handleSubmit(e));
  }

  async handleSubmit(event) {
    event.preventDefault();
    
    const form = event.target;
    const submitButton = form.querySelector('button[type="submit"]');
    
    // Disable form while submitting
    submitButton.disabled = true;
    submitButton.textContent = 'Creating...';

    const formData = new FormData(form);
    const data = {
      prefix: formData.get('prefix'),
      outdir: formData.get('outdir'),
      calculation: formData.get('calculation'),
      input_content: formData.get('input_content') || null
    };

    try {
      const simulation = await this.api.createSimulation(data);
      // Navigate to the simulation detail page
      this.router.navigate(`/simulation/${simulation.id}`);
    } catch (error) {
      console.error('Failed to create simulation:', error);
      this.showError(error.message);
      
      // Re-enable form
      submitButton.disabled = false;
      submitButton.textContent = 'Create Simulation';
    }
  }

  showError(message) {
    // Remove any existing error message
    const existingError = document.querySelector('.error-message');
    if (existingError) {
      existingError.remove();
    }

    // Create and insert error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message bg-red-50 border border-red-200 rounded-md p-4 mb-6';
    errorDiv.innerHTML = `
      <p class="text-red-800">Error: ${message}</p>
    `;

    const form = document.getElementById('new-simulation-form');
    form.parentNode.insertBefore(errorDiv, form);

    // Scroll to error
    errorDiv.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
}