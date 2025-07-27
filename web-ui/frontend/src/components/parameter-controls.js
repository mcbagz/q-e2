export class ParameterControls {
  constructor() {
    this.parameters = {
      ecutwfc: 50.0,
      ecutrho: null,
      kpoints: { nx: 4, ny: 4, nz: 4 },
      autoOptimize: {
        ecutwfc: false,
        ecutrho: false,
        kpoints: false
      }
    };
  }
  
  render() {
    return `
      <div class="space-y-6">
        <!-- Energy Cutoffs Section -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="text-lg font-semibold mb-4">Energy Cutoffs</h3>
          
          <!-- Ecutwfc -->
          <div class="mb-4">
            <div class="flex items-center justify-between mb-2">
              <label for="ecutwfc" class="label">
                Kinetic Energy Cutoff (ecutwfc)
              </label>
              <div class="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="auto-ecutwfc"
                  class="form-checkbox h-4 w-4 text-blue-600"
                />
                <label for="auto-ecutwfc" class="text-sm text-gray-600">
                  AUTO_OPTIMIZE
                </label>
              </div>
            </div>
            <div class="flex items-center space-x-4">
              <input
                type="range"
                id="ecutwfc-slider"
                min="20"
                max="150"
                step="5"
                value="50"
                class="flex-1"
              />
              <input
                type="number"
                id="ecutwfc"
                name="ecutwfc"
                value="50"
                min="20"
                max="150"
                step="5"
                class="w-20 input"
              />
              <span class="text-sm text-gray-600">Ry</span>
            </div>
            <p class="text-xs text-gray-500 mt-1">
              Recommended: 50-80 Ry for most calculations
            </p>
          </div>
          
          <!-- Ecutrho -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <label for="ecutrho" class="label">
                Charge Density Cutoff (ecutrho)
              </label>
              <div class="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="auto-ecutrho"
                  class="form-checkbox h-4 w-4 text-blue-600"
                />
                <label for="auto-ecutrho" class="text-sm text-gray-600">
                  AUTO_OPTIMIZE
                </label>
              </div>
            </div>
            <div class="flex items-center space-x-4">
              <input
                type="range"
                id="ecutrho-slider"
                min="80"
                max="800"
                step="20"
                value="400"
                class="flex-1"
              />
              <input
                type="number"
                id="ecutrho"
                name="ecutrho"
                value="400"
                min="80"
                max="800"
                step="20"
                class="w-20 input"
              />
              <span class="text-sm text-gray-600">Ry</span>
            </div>
            <p class="text-xs text-gray-500 mt-1">
              Default: 4 × ecutwfc (auto-calculated if not specified)
            </p>
          </div>
        </div>
        
        <!-- K-points Section -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="text-lg font-semibold mb-4">K-points Grid</h3>
          
          <div class="flex items-center justify-between mb-4">
            <label class="label">Monkhorst-Pack Grid</label>
            <div class="flex items-center space-x-2">
              <input
                type="checkbox"
                id="auto-kpoints"
                class="form-checkbox h-4 w-4 text-blue-600"
              />
              <label for="auto-kpoints" class="text-sm text-gray-600">
                AUTO_OPTIMIZE
              </label>
            </div>
          </div>
          
          <div class="grid grid-cols-3 gap-4">
            <div>
              <label for="kpoints-nx" class="block text-sm font-medium text-gray-700 mb-1">
                Nx
              </label>
              <input
                type="number"
                id="kpoints-nx"
                name="kpoints-nx"
                value="4"
                min="1"
                max="20"
                class="input"
              />
            </div>
            <div>
              <label for="kpoints-ny" class="block text-sm font-medium text-gray-700 mb-1">
                Ny
              </label>
              <input
                type="number"
                id="kpoints-ny"
                name="kpoints-ny"
                value="4"
                min="1"
                max="20"
                class="input"
              />
            </div>
            <div>
              <label for="kpoints-nz" class="block text-sm font-medium text-gray-700 mb-1">
                Nz
              </label>
              <input
                type="number"
                id="kpoints-nz"
                name="kpoints-nz"
                value="4"
                min="1"
                max="20"
                class="input"
              />
            </div>
          </div>
          
          <p class="text-xs text-gray-500 mt-2">
            Higher values give more accurate results but increase computation time
          </p>
        </div>
        
        <!-- Convergence Parameters -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="text-lg font-semibold mb-4">Convergence Parameters</h3>
          
          <div class="space-y-4">
            <div>
              <label for="conv-thr" class="label">
                Convergence Threshold
              </label>
              <div class="flex items-center space-x-4">
                <select id="conv-thr" name="conv-thr" class="input flex-1">
                  <option value="1e-4">1×10⁻⁴ (Fast, less accurate)</option>
                  <option value="1e-6" selected>1×10⁻⁶ (Default)</option>
                  <option value="1e-8">1×10⁻⁸ (Accurate)</option>
                  <option value="1e-10">1×10⁻¹⁰ (Very accurate)</option>
                </select>
              </div>
            </div>
            
            <div>
              <label for="mixing-beta" class="label">
                Mixing Beta
              </label>
              <div class="flex items-center space-x-4">
                <input
                  type="range"
                  id="mixing-beta-slider"
                  min="0.1"
                  max="0.9"
                  step="0.1"
                  value="0.7"
                  class="flex-1"
                />
                <input
                  type="number"
                  id="mixing-beta"
                  name="mixing-beta"
                  value="0.7"
                  min="0.1"
                  max="0.9"
                  step="0.1"
                  class="w-20 input"
                />
              </div>
              <p class="text-xs text-gray-500 mt-1">
                Lower values for difficult convergence, higher for faster convergence
              </p>
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  init() {
    // Sync sliders with number inputs
    this.syncSliderInput('ecutwfc');
    this.syncSliderInput('ecutrho');
    this.syncSliderInput('mixing-beta');
    
    // Handle AUTO_OPTIMIZE checkboxes
    this.handleAutoOptimize('ecutwfc');
    this.handleAutoOptimize('ecutrho');
    this.handleAutoOptimize('kpoints');
  }
  
  syncSliderInput(paramName) {
    const slider = document.getElementById(`${paramName}-slider`);
    const input = document.getElementById(paramName);
    
    if (slider && input) {
      slider.addEventListener('input', (e) => {
        input.value = e.target.value;
      });
      
      input.addEventListener('input', (e) => {
        slider.value = e.target.value;
      });
    }
  }
  
  handleAutoOptimize(param) {
    const checkbox = document.getElementById(`auto-${param}`);
    if (!checkbox) return;
    
    checkbox.addEventListener('change', (e) => {
      const isChecked = e.target.checked;
      
      if (param === 'ecutwfc') {
        const slider = document.getElementById('ecutwfc-slider');
        const input = document.getElementById('ecutwfc');
        slider.disabled = isChecked;
        input.disabled = isChecked;
        if (isChecked) {
          slider.classList.add('opacity-50');
          input.classList.add('opacity-50');
        } else {
          slider.classList.remove('opacity-50');
          input.classList.remove('opacity-50');
        }
      } else if (param === 'ecutrho') {
        const slider = document.getElementById('ecutrho-slider');
        const input = document.getElementById('ecutrho');
        slider.disabled = isChecked;
        input.disabled = isChecked;
        if (isChecked) {
          slider.classList.add('opacity-50');
          input.classList.add('opacity-50');
        } else {
          slider.classList.remove('opacity-50');
          input.classList.remove('opacity-50');
        }
      } else if (param === 'kpoints') {
        const inputs = ['kpoints-nx', 'kpoints-ny', 'kpoints-nz'];
        inputs.forEach(id => {
          const input = document.getElementById(id);
          input.disabled = isChecked;
          if (isChecked) {
            input.classList.add('opacity-50');
          } else {
            input.classList.remove('opacity-50');
          }
        });
      }
      
      this.parameters.autoOptimize[param] = isChecked;
    });
  }
  
  getParameters() {
    const params = {
      ecutwfc: parseFloat(document.getElementById('ecutwfc').value),
      ecutrho: parseFloat(document.getElementById('ecutrho').value),
      k_points: {
        type: 'automatic',
        grid: [
          parseInt(document.getElementById('kpoints-nx').value),
          parseInt(document.getElementById('kpoints-ny').value),
          parseInt(document.getElementById('kpoints-nz').value)
        ],
        shift: [0, 0, 0]
      },
      conv_thr: parseFloat(document.getElementById('conv-thr').value),
      mixing_beta: parseFloat(document.getElementById('mixing-beta').value),
      auto_optimize: {
        ecutwfc: document.getElementById('auto-ecutwfc').checked,
        ecutrho: document.getElementById('auto-ecutrho').checked,
        kpoints: document.getElementById('auto-kpoints').checked
      }
    };
    
    // If ecutrho AUTO_OPTIMIZE is checked, set it to null
    if (params.auto_optimize.ecutrho) {
      params.ecutrho = null;
    }
    
    return params;
  }
}