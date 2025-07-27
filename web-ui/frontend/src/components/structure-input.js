export class StructureInput {
  constructor(onStructureChange) {
    this.onStructureChange = onStructureChange;
    this.atoms = [];
    this.cellParameters = {
      a: 5.0,
      b: 5.0,
      c: 5.0,
      alpha: 90,
      beta: 90,
      gamma: 90
    };
  }
  
  render() {
    return `
      <div class="space-y-6">
        <!-- File Import -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="text-lg font-semibold mb-4">Import Structure</h3>
          <div class="flex items-center space-x-4">
            <input
              type="file"
              id="structure-file"
              accept=".cif,.xyz,.poscar"
              class="hidden"
            />
            <button
              type="button"
              id="import-structure-btn"
              class="btn btn-secondary"
            >
              Import from File
            </button>
            <span class="text-sm text-gray-600">
              Supports CIF, XYZ, POSCAR formats
            </span>
          </div>
        </div>
        
        <!-- Lattice Parameters -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="text-lg font-semibold mb-4">Lattice Parameters</h3>
          
          <div class="grid grid-cols-2 gap-4 mb-4">
            <div>
              <label for="cell-a" class="label">a (Å)</label>
              <input
                type="number"
                id="cell-a"
                value="5.0"
                step="0.1"
                min="0.1"
                class="input"
              />
            </div>
            <div>
              <label for="cell-b" class="label">b (Å)</label>
              <input
                type="number"
                id="cell-b"
                value="5.0"
                step="0.1"
                min="0.1"
                class="input"
              />
            </div>
            <div>
              <label for="cell-c" class="label">c (Å)</label>
              <input
                type="number"
                id="cell-c"
                value="5.0"
                step="0.1"
                min="0.1"
                class="input"
              />
            </div>
            <div>
              <label for="cell-alpha" class="label">α (°)</label>
              <input
                type="number"
                id="cell-alpha"
                value="90"
                step="0.1"
                min="0"
                max="180"
                class="input"
              />
            </div>
            <div>
              <label for="cell-beta" class="label">β (°)</label>
              <input
                type="number"
                id="cell-beta"
                value="90"
                step="0.1"
                min="0"
                max="180"
                class="input"
              />
            </div>
            <div>
              <label for="cell-gamma" class="label">γ (°)</label>
              <input
                type="number"
                id="cell-gamma"
                value="90"
                step="0.1"
                min="0"
                max="180"
                class="input"
              />
            </div>
          </div>
          
          <div class="flex space-x-4">
            <button
              type="button"
              id="preset-cubic"
              class="btn btn-sm btn-secondary"
            >
              Cubic
            </button>
            <button
              type="button"
              id="preset-fcc"
              class="btn btn-sm btn-secondary"
            >
              FCC
            </button>
            <button
              type="button"
              id="preset-bcc"
              class="btn btn-sm btn-secondary"
            >
              BCC
            </button>
            <button
              type="button"
              id="preset-hexagonal"
              class="btn btn-sm btn-secondary"
            >
              Hexagonal
            </button>
          </div>
        </div>
        
        <!-- Atomic Positions -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold">Atomic Positions</h3>
            <button
              type="button"
              id="add-atom-btn"
              class="btn btn-sm btn-primary"
            >
              Add Atom
            </button>
          </div>
          
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-100">
                <tr>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Element
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    X (Å)
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Y (Å)
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Z (Å)
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Coords
                  </th>
                  <th class="px-3 py-2"></th>
                </tr>
              </thead>
              <tbody id="atoms-tbody" class="bg-white divide-y divide-gray-200">
                <!-- Atoms will be added here dynamically -->
              </tbody>
            </table>
          </div>
          
          <div id="no-atoms-message" class="text-center py-8 text-gray-500">
            No atoms added yet. Click "Add Atom" to start building your structure.
          </div>
        </div>
        
        <!-- Common Structures -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="text-lg font-semibold mb-4">Example Structures</h3>
          <div class="grid grid-cols-2 gap-4">
            <button
              type="button"
              id="example-si"
              class="btn btn-secondary text-sm"
            >
              Silicon (Diamond)
            </button>
            <button
              type="button"
              id="example-graphene"
              class="btn btn-secondary text-sm"
            >
              Graphene
            </button>
            <button
              type="button"
              id="example-h2o"
              class="btn btn-secondary text-sm"
            >
              Water Molecule
            </button>
            <button
              type="button"
              id="example-nacl"
              class="btn btn-secondary text-sm"
            >
              NaCl (Rock Salt)
            </button>
          </div>
        </div>
      </div>
    `;
  }
  
  init() {
    // File import
    document.getElementById('import-structure-btn').addEventListener('click', () => {
      document.getElementById('structure-file').click();
    });
    
    document.getElementById('structure-file').addEventListener('change', (e) => {
      this.handleFileImport(e.target.files[0]);
    });
    
    // Lattice parameter inputs
    const latticeInputs = ['a', 'b', 'c', 'alpha', 'beta', 'gamma'];
    latticeInputs.forEach(param => {
      document.getElementById(`cell-${param}`).addEventListener('input', () => {
        this.updateCellParameters();
      });
    });
    
    // Preset buttons
    document.getElementById('preset-cubic').addEventListener('click', () => {
      this.setPresetLattice('cubic');
    });
    
    document.getElementById('preset-fcc').addEventListener('click', () => {
      this.setPresetLattice('fcc');
    });
    
    document.getElementById('preset-bcc').addEventListener('click', () => {
      this.setPresetLattice('bcc');
    });
    
    document.getElementById('preset-hexagonal').addEventListener('click', () => {
      this.setPresetLattice('hexagonal');
    });
    
    // Add atom button
    document.getElementById('add-atom-btn').addEventListener('click', () => {
      this.addAtom();
    });
    
    // Example structures
    document.getElementById('example-si').addEventListener('click', () => {
      this.loadExampleStructure('silicon');
    });
    
    document.getElementById('example-graphene').addEventListener('click', () => {
      this.loadExampleStructure('graphene');
    });
    
    document.getElementById('example-h2o').addEventListener('click', () => {
      this.loadExampleStructure('water');
    });
    
    document.getElementById('example-nacl').addEventListener('click', () => {
      this.loadExampleStructure('nacl');
    });
    
    // Update display
    this.updateAtomsDisplay();
  }
  
  updateCellParameters() {
    this.cellParameters = {
      a: parseFloat(document.getElementById('cell-a').value),
      b: parseFloat(document.getElementById('cell-b').value),
      c: parseFloat(document.getElementById('cell-c').value),
      alpha: parseFloat(document.getElementById('cell-alpha').value),
      beta: parseFloat(document.getElementById('cell-beta').value),
      gamma: parseFloat(document.getElementById('cell-gamma').value)
    };
    
    this.notifyStructureChange();
  }
  
  setPresetLattice(type) {
    const presets = {
      cubic: { a: 5.0, b: 5.0, c: 5.0, alpha: 90, beta: 90, gamma: 90 },
      fcc: { a: 5.0, b: 5.0, c: 5.0, alpha: 90, beta: 90, gamma: 90 },
      bcc: { a: 5.0, b: 5.0, c: 5.0, alpha: 90, beta: 90, gamma: 90 },
      hexagonal: { a: 5.0, b: 5.0, c: 8.0, alpha: 90, beta: 90, gamma: 120 }
    };
    
    const preset = presets[type];
    Object.keys(preset).forEach(param => {
      document.getElementById(`cell-${param}`).value = preset[param];
    });
    
    this.updateCellParameters();
  }
  
  addAtom(element = 'Si', x = 0, y = 0, z = 0, coordType = 'angstrom') {
    const atom = {
      id: Date.now(),
      element,
      x,
      y,
      z,
      coordType
    };
    
    this.atoms.push(atom);
    this.updateAtomsDisplay();
    this.notifyStructureChange();
  }
  
  removeAtom(id) {
    this.atoms = this.atoms.filter(atom => atom.id !== id);
    this.updateAtomsDisplay();
    this.notifyStructureChange();
  }
  
  updateAtomsDisplay() {
    const tbody = document.getElementById('atoms-tbody');
    const noAtomsMessage = document.getElementById('no-atoms-message');
    
    if (this.atoms.length === 0) {
      tbody.innerHTML = '';
      noAtomsMessage.style.display = 'block';
      return;
    }
    
    noAtomsMessage.style.display = 'none';
    
    tbody.innerHTML = this.atoms.map(atom => `
      <tr data-atom-id="${atom.id}">
        <td class="px-3 py-2">
          <input
            type="text"
            value="${atom.element}"
            class="w-16 px-2 py-1 border rounded atom-element"
            data-atom-id="${atom.id}"
          />
        </td>
        <td class="px-3 py-2">
          <input
            type="number"
            value="${atom.x}"
            step="0.01"
            class="w-20 px-2 py-1 border rounded atom-x"
            data-atom-id="${atom.id}"
          />
        </td>
        <td class="px-3 py-2">
          <input
            type="number"
            value="${atom.y}"
            step="0.01"
            class="w-20 px-2 py-1 border rounded atom-y"
            data-atom-id="${atom.id}"
          />
        </td>
        <td class="px-3 py-2">
          <input
            type="number"
            value="${atom.z}"
            step="0.01"
            class="w-20 px-2 py-1 border rounded atom-z"
            data-atom-id="${atom.id}"
          />
        </td>
        <td class="px-3 py-2">
          <select
            class="px-2 py-1 border rounded atom-coords"
            data-atom-id="${atom.id}"
          >
            <option value="angstrom" ${atom.coordType === 'angstrom' ? 'selected' : ''}>Å</option>
            <option value="crystal" ${atom.coordType === 'crystal' ? 'selected' : ''}>Crystal</option>
          </select>
        </td>
        <td class="px-3 py-2">
          <button
            type="button"
            class="text-red-600 hover:text-red-800 remove-atom-btn"
            data-atom-id="${atom.id}"
          >
            Remove
          </button>
        </td>
      </tr>
    `).join('');
    
    // Add event listeners
    tbody.querySelectorAll('.atom-element, .atom-x, .atom-y, .atom-z, .atom-coords').forEach(input => {
      input.addEventListener('input', (e) => {
        const atomId = parseInt(e.target.getAttribute('data-atom-id'));
        const atom = this.atoms.find(a => a.id === atomId);
        
        if (e.target.classList.contains('atom-element')) {
          atom.element = e.target.value;
        } else if (e.target.classList.contains('atom-x')) {
          atom.x = parseFloat(e.target.value);
        } else if (e.target.classList.contains('atom-y')) {
          atom.y = parseFloat(e.target.value);
        } else if (e.target.classList.contains('atom-z')) {
          atom.z = parseFloat(e.target.value);
        } else if (e.target.classList.contains('atom-coords')) {
          atom.coordType = e.target.value;
        }
        
        this.notifyStructureChange();
      });
    });
    
    tbody.querySelectorAll('.remove-atom-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const atomId = parseInt(e.target.getAttribute('data-atom-id'));
        this.removeAtom(atomId);
      });
    });
  }
  
  loadExampleStructure(type) {
    switch (type) {
      case 'silicon':
        // Silicon diamond structure
        this.cellParameters = { a: 5.43, b: 5.43, c: 5.43, alpha: 90, beta: 90, gamma: 90 };
        this.atoms = [
          { id: 1, element: 'Si', x: 0, y: 0, z: 0, coordType: 'crystal' },
          { id: 2, element: 'Si', x: 0.25, y: 0.25, z: 0.25, coordType: 'crystal' }
        ];
        break;
        
      case 'graphene':
        // Graphene
        this.cellParameters = { a: 2.46, b: 2.46, c: 20.0, alpha: 90, beta: 90, gamma: 120 };
        this.atoms = [
          { id: 1, element: 'C', x: 0, y: 0, z: 0.5, coordType: 'crystal' },
          { id: 2, element: 'C', x: 0.333, y: 0.667, z: 0.5, coordType: 'crystal' }
        ];
        break;
        
      case 'water':
        // Water molecule
        this.cellParameters = { a: 10, b: 10, c: 10, alpha: 90, beta: 90, gamma: 90 };
        this.atoms = [
          { id: 1, element: 'O', x: 5, y: 5, z: 5, coordType: 'angstrom' },
          { id: 2, element: 'H', x: 5.757, y: 5, z: 5.587, coordType: 'angstrom' },
          { id: 3, element: 'H', x: 4.243, y: 5, z: 5.587, coordType: 'angstrom' }
        ];
        break;
        
      case 'nacl':
        // NaCl rock salt structure
        this.cellParameters = { a: 5.64, b: 5.64, c: 5.64, alpha: 90, beta: 90, gamma: 90 };
        this.atoms = [
          { id: 1, element: 'Na', x: 0, y: 0, z: 0, coordType: 'crystal' },
          { id: 2, element: 'Cl', x: 0.5, y: 0.5, z: 0.5, coordType: 'crystal' }
        ];
        break;
    }
    
    // Update UI
    Object.keys(this.cellParameters).forEach(param => {
      document.getElementById(`cell-${param}`).value = this.cellParameters[param];
    });
    
    this.updateAtomsDisplay();
    this.notifyStructureChange();
  }
  
  handleFileImport(file) {
    // This is a placeholder - actual file parsing would be implemented here
    alert('File import functionality would parse the selected file and load the structure.');
  }
  
  notifyStructureChange() {
    if (this.onStructureChange) {
      const structure = this.getStructureData();
      this.onStructureChange(structure);
    }
  }
  
  getStructureData() {
    // Convert lattice parameters to cell vectors
    const cellVectors = this.latticeParametersToVectors(this.cellParameters);
    
    // Convert atoms to Cartesian coordinates if needed
    const cartesianAtoms = this.atoms.map(atom => {
      if (atom.coordType === 'crystal') {
        // Convert fractional to Cartesian
        const cart = this.crystalToCartesian(atom, cellVectors);
        return {
          element: atom.element,
          x: cart.x,
          y: cart.y,
          z: cart.z
        };
      }
      return {
        element: atom.element,
        x: atom.x,
        y: atom.y,
        z: atom.z
      };
    });
    
    return {
      atoms: cartesianAtoms,
      cellParameters: cellVectors,
      latticeParams: this.cellParameters
    };
  }
  
  latticeParametersToVectors(params) {
    const { a, b, c, alpha, beta, gamma } = params;
    
    // Convert angles to radians
    const alphaRad = alpha * Math.PI / 180;
    const betaRad = beta * Math.PI / 180;
    const gammaRad = gamma * Math.PI / 180;
    
    // Calculate cell vectors
    const ax = a;
    const ay = 0;
    const az = 0;
    
    const bx = b * Math.cos(gammaRad);
    const by = b * Math.sin(gammaRad);
    const bz = 0;
    
    const cx = c * Math.cos(betaRad);
    const cy = c * (Math.cos(alphaRad) - Math.cos(betaRad) * Math.cos(gammaRad)) / Math.sin(gammaRad);
    const cz = Math.sqrt(c * c - cx * cx - cy * cy);
    
    return [
      [ax, ay, az],
      [bx, by, bz],
      [cx, cy, cz]
    ];
  }
  
  crystalToCartesian(atom, cellVectors) {
    const x = atom.x * cellVectors[0][0] + atom.y * cellVectors[1][0] + atom.z * cellVectors[2][0];
    const y = atom.x * cellVectors[0][1] + atom.y * cellVectors[1][1] + atom.z * cellVectors[2][1];
    const z = atom.x * cellVectors[0][2] + atom.y * cellVectors[1][2] + atom.z * cellVectors[2][2];
    
    return { x, y, z };
  }
}