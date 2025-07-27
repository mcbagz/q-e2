import { StructureViewer } from '../components/structure-viewer.js';
import { ParameterControls } from '../components/parameter-controls.js';
import { StructureInput } from '../components/structure-input.js';
import { PseudopotentialSelector } from '../components/pseudopotential-selector.js';

export class NewSimulationPage {
  constructor(api, router) {
    this.api = api;
    this.router = router;
    this.structureViewer = null;
    this.parameterControls = null;
    this.structureInput = null;
    this.pseudoSelector = null;
    this.currentStructure = null;
  }

  render() {
    return `
      <div class="container mx-auto px-4 py-8">
        <div class="mb-8">
          <a href="/" data-link class="text-blue-600 hover:text-blue-800 mb-4 inline-block">
            ← Back to Dashboard
          </a>
          <h1 class="text-3xl font-bold">Create New Simulation</h1>
        </div>

        <form id="new-simulation-form">
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Left Column -->
            <div class="space-y-6">
              <!-- Basic Settings -->
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

              <!-- Structure Input -->
              <div class="card">
                <h2 class="text-xl font-semibold mb-4">Structure Definition</h2>
                <div id="structure-input-container"></div>
              </div>

              <!-- Pseudopotentials -->
              <div class="card">
                <div id="pseudo-selector-container"></div>
              </div>
            </div>

            <!-- Right Column -->
            <div class="space-y-6">
              <!-- 3D Structure Viewer -->
              <div class="card">
                <h2 class="text-xl font-semibold mb-4">Structure Visualization</h2>
                <div id="structure-viewer" class="w-full h-96 bg-gray-100 rounded-lg relative">
                  <div class="absolute inset-0 flex items-center justify-center text-gray-500">
                    Add atoms to visualize structure
                  </div>
                </div>
                <div class="mt-2 flex justify-end space-x-2">
                  <button type="button" id="reset-view-btn" class="btn btn-sm btn-secondary">
                    Reset View
                  </button>
                </div>
              </div>

              <!-- Calculation Parameters -->
              <div class="card">
                <h2 class="text-xl font-semibold mb-4">Calculation Parameters</h2>
                <div id="parameter-controls-container"></div>
              </div>
            </div>
          </div>

          <!-- Submit Section -->
          <div class="mt-8 flex justify-end space-x-4">
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
    // Initialize components
    this.initializeComponents();
    
    // Form submission
    const form = document.getElementById('new-simulation-form');
    form.addEventListener('submit', (e) => this.handleSubmit(e));
    
    // Reset view button
    document.getElementById('reset-view-btn').addEventListener('click', () => {
      if (this.structureViewer) {
        this.structureViewer.centerCamera();
      }
    });
  }

  initializeComponents() {
    // Initialize structure input
    const structureInputContainer = document.getElementById('structure-input-container');
    this.structureInput = new StructureInput((structure) => this.handleStructureChange(structure));
    structureInputContainer.innerHTML = this.structureInput.render();
    this.structureInput.init();
    
    // Initialize parameter controls
    const parameterContainer = document.getElementById('parameter-controls-container');
    this.parameterControls = new ParameterControls();
    parameterContainer.innerHTML = this.parameterControls.render();
    this.parameterControls.init();
    
    // Initialize pseudopotential selector
    const pseudoContainer = document.getElementById('pseudo-selector-container');
    this.pseudoSelector = new PseudopotentialSelector(this.api);
    pseudoContainer.innerHTML = this.pseudoSelector.render();
    this.pseudoSelector.init();
    
    // Initialize 3D structure viewer
    const viewerContainer = document.getElementById('structure-viewer');
    // Clear the placeholder text
    viewerContainer.innerHTML = '';
    this.structureViewer = new StructureViewer(viewerContainer);
  }

  handleStructureChange(structure) {
    this.currentStructure = structure;
    
    // Update 3D viewer
    if (this.structureViewer && structure.atoms.length > 0) {
      this.structureViewer.updateStructure(structure);
    }
    
    // Update pseudopotential selector with elements
    const elements = structure.atoms.map(atom => atom.element);
    this.pseudoSelector.updateElementList(elements);
  }

  async handleSubmit(event) {
    event.preventDefault();
    
    const form = event.target;
    const submitButton = form.querySelector('button[type="submit"]');
    
    // Validate pseudopotentials
    const pseudoValidation = this.pseudoSelector.validateSelections();
    if (!pseudoValidation.valid) {
      this.showError(pseudoValidation.message);
      return;
    }
    
    // Disable form while submitting
    submitButton.disabled = true;
    submitButton.textContent = 'Creating...';

    // Gather all data
    const formData = new FormData(form);
    const parameters = this.parameterControls.getParameters();
    const pseudopotentials = this.pseudoSelector.getSelectedPseudopotentials();
    
    const data = {
      prefix: formData.get('prefix'),
      outdir: formData.get('outdir'),
      calculation_type: formData.get('calculation'),
      
      // Structure data
      atoms: this.currentStructure?.atoms || [],
      cell_parameters: this.currentStructure?.cellParameters || null,
      
      // Calculation parameters
      ecutwfc: parameters.ecutwfc,
      ecutrho: parameters.ecutrho,
      k_points: parameters.k_points,
      conv_thr: parameters.conv_thr,
      mixing_beta: parameters.mixing_beta,
      
      // Auto-optimize flags
      auto_optimize: parameters.auto_optimize,
      
      // Pseudopotentials
      pseudopotentials: pseudopotentials
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

  destroy() {
    // Clean up Three.js resources when leaving the page
    if (this.structureViewer) {
      this.structureViewer.destroy();
    }
  }
}