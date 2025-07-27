# Frontend Setup Instructions

## Prerequisites

- Node.js (version 16 or higher)
- npm (comes with Node.js)

## Quick Start

1. Navigate to the frontend directory:
```bash
cd C:\Users\mcbag\gauntlet\q-e2\web-ui\frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Open your browser and navigate to http://localhost:3000

## Important Notes

- Make sure the backend API is running on http://localhost:8000 before starting the frontend
- The frontend will automatically proxy API requests to the backend
- WebSocket connections will be established for real-time log streaming

## Troubleshooting

If you encounter issues:

1. Check that all dependencies are installed: `npm install`
2. Ensure the backend is running on port 8000
3. Check the browser console for any error messages
4. Verify that no other application is using port 3000

## Building for Production

To create a production build:

```bash
npm run build
```

The optimized files will be in the `dist/` directory.