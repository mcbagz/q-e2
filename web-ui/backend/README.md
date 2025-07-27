# Quantum ESPRESSO Web UI Backend

This is the FastAPI backend for the Quantum ESPRESSO Web UI, providing REST API endpoints and WebSocket support for managing QE simulations.

## Features

- **REST API** for simulation management
- **WebSocket support** for real-time output streaming
- **Process management** for QE executables
- **SQLite database** for simulation metadata
- **Input file generation** for SCF calculations
- **Signal support** for snapshots and checkpoints (Unix/Linux/Mac only)

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

   The server will start at `http://localhost:8000`

## API Documentation

Once running, visit:
- API docs: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Simulations

- `GET /api/simulations/` - List all simulations
- `GET /api/simulations/{id}` - Get simulation details
- `POST /api/simulations/` - Create new simulation
- `DELETE /api/simulations/{id}` - Delete simulation
- `POST /api/simulations/control` - Control simulation (start/stop/snapshot/checkpoint)
- `WS /api/simulations/{id}/ws` - WebSocket for real-time updates

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

## Development

The backend is designed to be extended with additional features:

- More calculation types (NSCF, optimization, MD, etc.)
- Advanced input parameters
- Pseudopotential management
- Result parsing and visualization
- User authentication
- Multi-user support

## Notes

- Signal-based features (snapshot/checkpoint) only work on Unix/Linux/Mac
- The QE executables must be built and available in the configured path
- SQLite is used for simplicity but can be replaced with PostgreSQL for production