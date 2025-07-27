export class PseudopotentialSelector {
  constructor(api) {
    this.api = api;
    this.availablePseudos = {};
    this.selectedPseudos = {};
  }
  
  async loadAvailablePseudopotentials() {
    try {
      const response = await this.api.getPseudopotentials();
      
      // The API returns an object with element keys containing 'default' and 'available' arrays
      // We need to convert this to our expected format
      this.availablePseudos = {};
      
      if (response && typeof response === 'object') {
        for (const [element, data] of Object.entries(response)) {
          if (data && data.available && Array.isArray(data.available)) {
            // Convert from filename strings to our expected format
            this.availablePseudos[element] = data.available.map(filename => {
              // Parse the filename to extract type and functional
              let functional = "PBE"; // default
              let pseudo_type = "USPP"; // default
              
              if (filename.toLowerCase().includes('pbe')) functional = "PBE";
              else if (filename.toLowerCase().includes('pbesol')) functional = "PBEsol";
              else if (filename.toLowerCase().includes('lda')) functional = "LDA";
              else if (filename.toLowerCase().includes('pw91')) functional = "PW91";
              
              if (filename.toLowerCase().includes('paw') || filename.toLowerCase().includes('kjpaw')) pseudo_type = "PAW";
              else if (filename.toLowerCase().includes('uspp') || filename.toLowerCase().includes('rrkjus')) pseudo_type = "USPP";
              else if (filename.toLowerCase().includes('nc')) pseudo_type = "NC";
              
              return {
                file: filename,
                type: pseudo_type,
                functional: functional
              };
            });
          }
        }
      }
      
      // If no pseudopotentials from API, use fallback data
      if (Object.keys(this.availablePseudos).length === 0) {
        this.availablePseudos = {
          'Si': [
            { file: 'Si.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' },
            { file: 'Si.pbe-n-kjpaw_psl.1.0.0.UPF', type: 'PAW', functional: 'PBE' },
            { file: 'Si.pbesol-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBEsol' }
          ],
          'C': [
            { file: 'C.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' },
            { file: 'C.pbe-n-kjpaw_psl.1.0.0.UPF', type: 'PAW', functional: 'PBE' }
          ],
          'H': [
            { file: 'H.pbe-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' },
            { file: 'H.pbe-kjpaw_psl.1.0.0.UPF', type: 'PAW', functional: 'PBE' }
          ],
          'O': [
            { file: 'O.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' },
            { file: 'O.pbe-n-kjpaw_psl.1.0.0.UPF', type: 'PAW', functional: 'PBE' }
          ],
          'N': [
            { file: 'N.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' },
            { file: 'N.pbe-n-kjpaw_psl.1.0.0.UPF', type: 'PAW', functional: 'PBE' }
          ],
          'Na': [
            { file: 'Na.pbe-spn-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' }
          ],
          'Cl': [
            { file: 'Cl.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' }
          ]
        };
      }
    } catch (error) {
      console.error('Failed to load pseudopotentials:', error);
      // Use fallback data on error
      this.availablePseudos = {
        'Si': [
          { file: 'Si.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' }
        ],
        'C': [
          { file: 'C.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' }
        ],
        'H': [
          { file: 'H.pbe-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' }
        ],
        'O': [
          { file: 'O.pbe-n-rrkjus_psl.1.0.0.UPF', type: 'USPP', functional: 'PBE' }
        ]
      };
    }
  }
  
  render() {
    return `
      <div class="space-y-4">
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="text-lg font-semibold mb-4">Pseudopotential Selection</h3>
          
          <div class="mb-4">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">Exchange-Correlation Functional</span>
              <select id="xc-functional" class="input w-48">
                <option value="PBE" selected>PBE</option>
                <option value="PBEsol">PBEsol</option>
                <option value="LDA">LDA</option>
                <option value="PW91">PW91</option>
              </select>
            </div>
            <p class="text-xs text-gray-500">
              All selected pseudopotentials should use the same functional
            </p>
          </div>
          
          <div id="pseudo-selections" class="space-y-3">
            <!-- Pseudopotential selections will be added here dynamically -->
          </div>
          
          <div id="no-elements-message" class="text-center py-4 text-gray-500">
            Add atoms to your structure to select pseudopotentials
          </div>
          
          <div class="mt-4 p-3 bg-blue-50 rounded-md">
            <p class="text-sm text-blue-800">
              <strong>Tip:</strong> PAW pseudopotentials are generally more accurate but computationally expensive.
              USPP provides a good balance between accuracy and efficiency.
            </p>
          </div>
        </div>
      </div>
    `;
  }
  
  init() {
    this.loadAvailablePseudopotentials();
    
    document.getElementById('xc-functional').addEventListener('change', (e) => {
      this.updatePseudopotentialOptions();
    });
  }
  
  updateElementList(elements) {
    const container = document.getElementById('pseudo-selections');
    const noElementsMessage = document.getElementById('no-elements-message');
    
    if (elements.length === 0) {
      container.innerHTML = '';
      noElementsMessage.style.display = 'block';
      return;
    }
    
    noElementsMessage.style.display = 'none';
    
    // Get unique elements
    const uniqueElements = [...new Set(elements)];
    
    container.innerHTML = uniqueElements.map(element => {
      const pseudos = this.availablePseudos[element] || [];
      const selectedFunctional = document.getElementById('xc-functional').value;
      const filteredPseudos = pseudos.filter(p => p.functional === selectedFunctional);
      
      return `
        <div class="flex items-center space-x-4 p-3 bg-white rounded border">
          <span class="font-medium text-gray-700 w-12">${element}</span>
          <select
            id="pseudo-${element}"
            class="flex-1 input pseudo-select"
            data-element="${element}"
          >
            ${filteredPseudos.length > 0 ? 
              filteredPseudos.map(pseudo => `
                <option value="${pseudo.file}">
                  ${pseudo.file} (${pseudo.type})
                </option>
              `).join('') :
              '<option value="">No pseudopotentials available for this functional</option>'
            }
          </select>
          <span class="text-sm text-gray-500">
            ${filteredPseudos.length > 0 ? filteredPseudos[0].type : 'N/A'}
          </span>
        </div>
      `;
    }).join('');
    
    // Add change listeners
    container.querySelectorAll('.pseudo-select').forEach(select => {
      select.addEventListener('change', (e) => {
        const element = e.target.getAttribute('data-element');
        this.selectedPseudos[element] = e.target.value;
      });
      
      // Set initial selection
      const element = select.getAttribute('data-element');
      if (select.options.length > 0 && select.value) {
        this.selectedPseudos[element] = select.value;
      }
    });
  }
  
  updatePseudopotentialOptions() {
    // Re-render with new functional filter
    const elements = Object.keys(this.selectedPseudos);
    this.updateElementList(elements);
  }
  
  getSelectedPseudopotentials() {
    return this.selectedPseudos;
  }
  
  validateSelections() {
    const elements = Object.keys(this.selectedPseudos);
    const missing = elements.filter(el => !this.selectedPseudos[el]);
    
    if (missing.length > 0) {
      return {
        valid: false,
        message: `Please select pseudopotentials for: ${missing.join(', ')}`
      };
    }
    
    return { valid: true };
  }
}