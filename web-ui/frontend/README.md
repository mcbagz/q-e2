# Quantum ESPRESSO Web UI - Frontend

This is the frontend application for the Quantum ESPRESSO Web UI, built with Vite, vanilla JavaScript, and Tailwind CSS.

## Features

- **Dashboard**: View and manage all simulations
- **New Simulation**: Create new QE simulations with basic parameters
- **Real-time Monitoring**: Stream simulation logs via WebSocket
- **Simulation Control**: Run, stop, snapshot, and checkpoint simulations
- **Responsive Design**: Mobile-friendly interface using Tailwind CSS

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

The application will be available at http://localhost:3000

## Development

The frontend expects the backend API to be running on http://localhost:8000. The Vite dev server is configured to proxy API requests and WebSocket connections to the backend.

## Project Structure

```
frontend/
├── index.html          # Main HTML entry point
├── src/
│   ├── main.js        # Application entry point
│   ├── styles/
│   │   └── main.css   # Tailwind CSS and custom styles
│   ├── js/
│   │   ├── api.js     # API client for backend communication
│   │   ├── router.js  # Client-side routing
│   │   └── websocket.js # WebSocket client for real-time updates
│   └── pages/
│       ├── dashboard.js    # Dashboard page component
│       ├── new-simulation.js # New simulation form page
│       └── simulation-detail.js # Simulation detail and monitoring page
├── package.json       # NPM dependencies and scripts
├── vite.config.js    # Vite configuration
├── tailwind.config.js # Tailwind CSS configuration
└── postcss.config.js # PostCSS configuration
```

## Build for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

## API Endpoints Used

- `GET /api/simulations` - List all simulations
- `POST /api/simulations` - Create a new simulation
- `GET /api/simulations/{id}` - Get simulation details
- `POST /api/simulations/{id}/start` - Start a simulation
- `POST /api/simulations/{id}/stop` - Stop a simulation
- `GET /api/simulations/{id}/logs` - Get simulation logs

## WebSocket Events

- `simulation_log` - Real-time log output from running simulations
- `simulation_status` - Status updates for simulations
- `simulation_progress` - Progress information (iteration, energy, convergence)

## Phase 1 Implementation

This MVP implementation includes:

- ✅ Vite application setup with HTML/CSS/JS
- ✅ Tailwind CSS for styling
- ✅ Dashboard page to list simulations
- ✅ "New Simulation" form with basic inputs (prefix, outdir)
- ✅ Text area to display QE output logs
- ✅ Run/Stop buttons
- ✅ WebSocket client for real-time log streaming

## Next Steps (Phase 2)

- Three.js integration for 3D structure visualization
- Advanced parameter controls (sliders, dropdowns)
- Pseudopotential selection UI
- File upload for structure import