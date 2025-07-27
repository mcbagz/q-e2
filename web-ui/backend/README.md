# Quantum ESPRESSO Web UI Backend

This is the FastAPI backend for the Quantum ESPRESSO Web UI, providing REST API endpoints and WebSocket support for managing QE simulations.

## Features

### Phase 1 Features (Complete)
- **REST API** for simulation management
- **WebSocket support** for real-time output streaming
- **Process management** for QE executables
- **SQLite database** for simulation metadata
- **Input file generation** for SCF calculations
- **Signal support** for snapshots and checkpoints (Unix/Linux/Mac only)

### Phase 2 Features (Complete)
- **Enhanced input generation** supporting all QE calculation types (scf, relax, vc-relax, md, nscf, bands)
- **Pseudopotential management** with automatic scanning and listing
- **AUTO_OPTIMIZE namelist** support for automatic parameter optimization
- **Structure import** from common formats (CIF, XYZ)
- **Advanced parameters** support through flexible `qe_params` field
- **Fixed atoms** support for relaxation calculations
- **Custom pseudopotentials** selection per element

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env to set your paths
   ```

3. **Run the server:**
   ```bash
   python run.py
   ```

   The server will start at `http://localhost:8009`

## API Documentation

Once running, visit:
- API docs: `http://localhost:8009/docs`
- ReDoc: `http://localhost:8009/redoc`

## API Endpoints

### Simulations

- `GET /api/simulations/` - List all simulations
- `GET /api/simulations/{id}` - Get simulation details
- `POST /api/simulations/` - Create new simulation (enhanced in Phase 2)
- `DELETE /api/simulations/{id}` - Delete simulation
- `POST /api/simulations/control` - Control simulation (start/stop/snapshot/checkpoint)
- `POST /api/simulations/import-structure` - Import structure from file (Phase 2)
- `WS /api/simulations/{id}/ws` - WebSocket for real-time updates

### Pseudopotentials (Phase 2)

- `GET /api/pseudopotentials/` - List all available pseudopotentials by element

### Process Control Actions

- `start` - Start the calculation
- `stop` - Gracefully stop (SIGTERM)
- `kill` - Force stop (SIGKILL)
- `snapshot` - Request status snapshot (SIGUSR2)
- `checkpoint` - Request checkpoint and stop (SIGUSR1)

## WebSocket Messages

The WebSocket endpoint streams real-time updates:

```json
{
  "type": "log|status|progress|error",
  "simulation_id": 1,
  "timestamp": "2024-01-01T00:00:00",
  "data": {
    // Message-specific data
  }
}
```

## Directory Structure

```
backend/
├── app/
│   ├── api/          # API endpoints
│   ├── config.py     # Configuration
│   ├── database.py   # Database models
│   ├── models.py     # Pydantic models
│   ├── qe_input.py   # Input file generation
│   ├── process_manager.py  # Process management
│   ├── websocket.py  # WebSocket handling
│   └── main.py       # FastAPI app
├── simulations/      # Simulation data (auto-created)
├── requirements.txt  # Python dependencies
├── run.py           # Run script
└── README.md        # This file
```

## Phase 2 Usage Examples

### Creating a simulation with AUTO_OPTIMIZE:
```json
POST /api/simulations/
{
  "prefix": "si_optimize",
  "outdir": "/tmp/si_optimize",
  "calculation_type": "scf",
  "atoms": [
    {"element": "Si", "position": [0.0, 0.0, 0.0]},
    {"element": "Si", "position": [1.3575, 1.3575, 1.3575]}
  ],
  "cell_parameters": [
    [2.715, 2.715, 0.0],
    [2.715, 0.0, 2.715],
    [0.0, 2.715, 2.715]
  ],
  "auto_optimize": {
    "k_points": true,
    "k_min": 2,
    "k_max": 8,
    "ecutwfc": true,
    "ecutwfc_min": 20,
    "ecutwfc_max": 50
  }
}
```

### Importing a structure:
```bash
curl -X POST http://localhost:8009/api/simulations/import-structure \
  -F "file=@structure.cif" \
  -F "file_format=cif"
```

### Creating a relaxation with fixed atoms:
```json
POST /api/simulations/
{
  "prefix": "co_relax",
  "outdir": "/tmp/co_relax",
  "calculation_type": "relax",
  "atoms": [
    {"element": "C", "position": [0.0, 0.0, 0.0]},
    {"element": "O", "position": [1.2, 0.0, 0.0], "fixed": [false, true, true]}
  ],
  "cell_parameters": [[10.0, 0.0, 0.0], [0.0, 10.0, 0.0], [0.0, 0.0, 10.0]],
  "qe_params": {
    "forc_conv_thr": 1e-3,
    "ion_dynamics": "bfgs"
  }
}
```

## Development

The backend is designed to be extended with additional features:

- Result parsing and visualization (Phase 4)
- User authentication
- Multi-user support
- Workflow automation
- Integration with visualization tools

## Notes

- Signal-based features (snapshot/checkpoint) only work on Unix/Linux/Mac
- The QE executables must be built and available in the configured path
- SQLite is used for simplicity but can be replaced with PostgreSQL for production