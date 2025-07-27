# Quantum ESPRESSO Web UI

A modern web-based interface for Quantum ESPRESSO that simplifies DFT calculations through an intuitive visual workflow.

## Features

### Phase 1 (Completed)
- ✅ Web-based dashboard for managing simulations
- ✅ Visual simulation creation with basic parameters
- ✅ Real-time output log streaming
- ✅ Process control (start/stop simulations)
- ✅ RESTful API with WebSocket support
- ✅ Docker containerization

### Upcoming Features
- 🚧 3D structure visualization with Three.js
- 🚧 Interactive parameter configuration
- 🚧 Automated visualization of results
- 🚧 Advanced simulation control (checkpoints, snapshots)

## Quick Start

### Using Docker (Recommended)

1. Clone the repository and navigate to the web-ui directory:
   ```bash
   cd web-ui
   ```

2. Build and start the containers:
   ```bash
   docker-compose up --build
   ```

3. Access the web interface at `http://localhost`

4. Access the API documentation at `http://localhost:8000/docs`

### Development Setup

#### Backend
```bash
cd backend
pip install -r requirements.txt
python run.py
```

#### Frontend
```bash
cd frontend
npm install
npm run dev
```

## Architecture

### Frontend
- **Framework**: Vite + Vanilla JS
- **Styling**: Tailwind CSS
- **Real-time**: WebSocket client
- **Build**: Static site with API proxy

### Backend
- **Framework**: FastAPI (Python)
- **Database**: SQLite
- **Process Management**: Python subprocess
- **Real-time**: WebSocket server
- **QE Integration**: Direct binary execution

### Docker
- **Frontend Container**: Nginx serving static files
- **Backend Container**: Ubuntu with QE binaries
- **Networking**: Bridge network for inter-container communication
- **Volumes**: Persistent storage for simulations and data

## API Endpoints

### Simulations
- `GET /api/simulations/` - List all simulations
- `POST /api/simulations/` - Create new simulation
- `GET /api/simulations/{id}` - Get simulation details
- `DELETE /api/simulations/{id}` - Delete simulation
- `POST /api/simulations/control` - Control simulation (start/stop)
- `WS /api/simulations/{id}/ws` - WebSocket for real-time updates

## Configuration

### Environment Variables
- `QE_BIN_PATH`: Path to QE executables (default: `/opt/qe/bin`)
- `QE_PSEUDO_PATH`: Path to pseudopotentials (default: `/opt/qe/pseudo`)
- `DATABASE_URL`: Database connection string
- `CORS_ORIGINS`: Allowed CORS origins

### Pseudopotentials
The Docker image includes common PBE pseudopotentials for H, C, N, O, and Si. Additional pseudopotentials can be added to the `QE_PSEUDO_PATH` directory.

## Development

### Adding New Features
1. Frontend changes go in `frontend/src/`
2. Backend changes go in `backend/app/`
3. Update Docker files if adding dependencies
4. Test locally before building containers

### Building for Production
```bash
docker-compose -f docker-compose.prod.yml up --build -d
```

## Troubleshooting

### Common Issues
1. **Port conflicts**: Ensure ports 80 and 8000 are available
2. **Permission errors**: Check Docker volume permissions
3. **QE errors**: Check simulation logs in the web interface
4. **WebSocket issues**: Ensure proxy configuration is correct

### Logs
- Frontend logs: `docker logs qe-web-frontend`
- Backend logs: `docker logs qe-web-backend`
- QE output: Available in the web interface

## Contributing

Please follow the project's contribution guidelines and ensure all tests pass before submitting pull requests.

## License

This project follows the same license as Quantum ESPRESSO.