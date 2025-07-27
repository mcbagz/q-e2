# Backend API Fixes Summary

## Issues Fixed

### 1. Missing API Endpoints
**Problem**: Frontend was calling endpoints that didn't exist.
**Fix**: Added the following endpoints:
- `POST /api/simulations/{id}/start` - Start a specific simulation
- `POST /api/simulations/{id}/stop` - Stop a running simulation  
- `GET /api/simulations/{id}/logs` - Retrieve simulation logs

### 2. Restructured Control Endpoints
**Problem**: The control endpoint used a single endpoint with action parameter.
**Fix**: 
- Split into separate RESTful endpoints for each action
- Each endpoint now takes simulation ID from the URL path
- Cleaner API design following REST conventions

### 3. Pseudopotentials Endpoint
**Problem**: Was on the wrong router path.
**Fix**: Moved to the pseudo_router so it's accessible at `/api/pseudopotentials/`

## API Endpoints Summary

### Simulations
- `GET /api/simulations/` - List all simulations
- `POST /api/simulations/` - Create new simulation
- `GET /api/simulations/{id}` - Get simulation details
- `DELETE /api/simulations/{id}` - Delete simulation
- `POST /api/simulations/{id}/start` - Start simulation
- `POST /api/simulations/{id}/stop` - Stop simulation
- `GET /api/simulations/{id}/logs` - Get simulation logs
- `WS /api/simulations/{id}/ws` - WebSocket for real-time updates

### Pseudopotentials
- `GET /api/pseudopotentials/` - List available pseudopotentials

### Structure Import
- `POST /api/simulations/import-structure` - Import structure from file

## Testing the Fixes

1. Rebuild the backend:
   ```bash
   cd web-ui
   docker-compose build backend
   docker-compose up -d
   ```

2. Or restart in development mode:
   ```bash
   cd web-ui/backend
   python run.py
   ```

The backend API should now work correctly with all frontend features!