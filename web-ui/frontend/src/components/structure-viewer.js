import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

export class StructureViewer {
  constructor(container) {
    this.container = container;
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.controls = null;
    this.atoms = [];
    this.bonds = [];
    this.unitCell = null;
    
    // Atomic colors (CPK coloring)
    this.atomColors = {
      H: 0xFFFFFF,
      C: 0x909090,
      N: 0x3050F8,
      O: 0xFF0D0D,
      F: 0x90E050,
      Si: 0xF0C8A0,
      P: 0xFF8000,
      S: 0xFFFF30,
      Cl: 0x1FF01F,
      Fe: 0xE06633,
      Cu: 0xC88033,
      Zn: 0x7D80B0,
      // Default color for unknown elements
      default: 0xFF1493
    };
    
    // Atomic radii (in Angstroms)
    this.atomRadii = {
      H: 0.25,
      C: 0.7,
      N: 0.65,
      O: 0.6,
      F: 0.5,
      Si: 1.1,
      P: 1.0,
      S: 1.0,
      Cl: 1.0,
      Fe: 1.25,
      Cu: 1.35,
      Zn: 1.35,
      // Default radius
      default: 0.8
    };
    
    this.init();
  }
  
  init() {
    // Scene setup
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xf8f9fa);
    
    // Camera setup
    const aspect = this.container.clientWidth / this.container.clientHeight;
    this.camera = new THREE.PerspectiveCamera(50, aspect, 0.1, 1000);
    this.camera.position.set(10, 10, 10);
    
    // Renderer setup
    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    this.renderer.setPixelRatio(window.devicePixelRatio);
    this.container.appendChild(this.renderer.domElement);
    
    // Controls
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    
    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.4);
    directionalLight.position.set(10, 10, 5);
    this.scene.add(directionalLight);
    
    // Handle resize
    window.addEventListener('resize', () => this.onWindowResize());
    
    // Start animation loop
    this.animate();
  }
  
  onWindowResize() {
    const aspect = this.container.clientWidth / this.container.clientHeight;
    this.camera.aspect = aspect;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
  }
  
  animate() {
    requestAnimationFrame(() => this.animate());
    this.controls.update();
    this.renderer.render(this.scene, this.camera);
  }
  
  // Clear the scene
  clear() {
    // Remove atoms
    this.atoms.forEach(atom => {
      this.scene.remove(atom);
    });
    this.atoms = [];
    
    // Remove bonds
    this.bonds.forEach(bond => {
      this.scene.remove(bond);
    });
    this.bonds = [];
    
    // Remove unit cell
    if (this.unitCell) {
      this.scene.remove(this.unitCell);
      this.unitCell = null;
    }
  }
  
  // Update structure with new data
  updateStructure(structureData) {
    this.clear();
    
    if (structureData.atoms) {
      this.addAtoms(structureData.atoms);
    }
    
    if (structureData.cellParameters) {
      this.addUnitCell(structureData.cellParameters);
    }
    
    // Center camera on structure
    this.centerCamera();
  }
  
  // Add atoms to the scene
  addAtoms(atoms) {
    atoms.forEach(atom => {
      const geometry = new THREE.SphereGeometry(
        this.atomRadii[atom.element] || this.atomRadii.default,
        32,
        16
      );
      
      const material = new THREE.MeshPhongMaterial({
        color: this.atomColors[atom.element] || this.atomColors.default,
        shininess: 100
      });
      
      const mesh = new THREE.Mesh(geometry, material);
      mesh.position.set(atom.x, atom.y, atom.z);
      
      // Store atom info for later use
      mesh.userData = {
        element: atom.element,
        position: new THREE.Vector3(atom.x, atom.y, atom.z)
      };
      
      this.atoms.push(mesh);
      this.scene.add(mesh);
    });
  }
  
  // Add unit cell visualization
  addUnitCell(cellParameters) {
    // cellParameters is a 3x3 matrix
    const a = new THREE.Vector3(...cellParameters[0]);
    const b = new THREE.Vector3(...cellParameters[1]);
    const c = new THREE.Vector3(...cellParameters[2]);
    
    const vertices = [
      new THREE.Vector3(0, 0, 0),
      a.clone(),
      a.clone().add(b),
      b.clone(),
      b.clone().add(c),
      c.clone(),
      a.clone().add(c),
      a.clone().add(b).add(c)
    ];
    
    const edges = [
      [0, 1], [1, 2], [2, 3], [3, 0], // Bottom face
      [4, 5], [5, 6], [6, 7], [7, 4], // Top face
      [0, 5], [1, 6], [2, 7], [3, 4]  // Vertical edges
    ];
    
    const geometry = new THREE.BufferGeometry();
    const positions = [];
    
    edges.forEach(edge => {
      positions.push(...vertices[edge[0]].toArray());
      positions.push(...vertices[edge[1]].toArray());
    });
    
    geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    
    const material = new THREE.LineBasicMaterial({
      color: 0x333333,
      linewidth: 2
    });
    
    this.unitCell = new THREE.LineSegments(geometry, material);
    this.scene.add(this.unitCell);
  }
  
  // Center camera on the structure
  centerCamera() {
    if (this.atoms.length === 0) return;
    
    // Calculate bounding box
    const box = new THREE.Box3();
    this.atoms.forEach(atom => {
      box.expandByObject(atom);
    });
    
    const center = box.getCenter(new THREE.Vector3());
    const size = box.getSize(new THREE.Vector3());
    const maxDim = Math.max(size.x, size.y, size.z);
    
    // Position camera
    const distance = maxDim * 2.5;
    this.camera.position.set(
      center.x + distance,
      center.y + distance * 0.5,
      center.z + distance
    );
    
    // Update controls target
    this.controls.target.copy(center);
    this.controls.update();
  }
  
  // Export structure data
  exportStructure() {
    const data = {
      atoms: this.atoms.map(atom => ({
        element: atom.userData.element,
        x: atom.position.x,
        y: atom.position.y,
        z: atom.position.z
      }))
    };
    
    return data;
  }
  
  // Destroy the viewer
  destroy() {
    window.removeEventListener('resize', () => this.onWindowResize());
    if (this.controls) {
      this.controls.dispose();
    }
    if (this.renderer) {
      this.renderer.dispose();
      if (this.renderer.domElement && this.renderer.domElement.parentNode === this.container) {
        this.container.removeChild(this.renderer.domElement);
      }
    }
  }
}