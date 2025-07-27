"""WebSocket connection management."""

from typing import Dict, Set
from fastapi import WebSocket
import asyncio
import json
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manage WebSocket connections."""
    
    def __init__(self):
        # Map simulation_id to set of connected websockets
        self.connections: Dict[int, Set[WebSocket]] = {}
        self.active_connections: Set[WebSocket] = set()
        
    async def connect(self, websocket: WebSocket, simulation_id: int):
        """Accept a new connection."""
        await websocket.accept()
        self.active_connections.add(websocket)
        
        if simulation_id not in self.connections:
            self.connections[simulation_id] = set()
        self.connections[simulation_id].add(websocket)
        
        logger.info(f"WebSocket connected for simulation {simulation_id}")
        
    def disconnect(self, websocket: WebSocket, simulation_id: int):
        """Remove a connection."""
        self.active_connections.discard(websocket)
        
        if simulation_id in self.connections:
            self.connections[simulation_id].discard(websocket)
            if not self.connections[simulation_id]:
                del self.connections[simulation_id]
                
        logger.info(f"WebSocket disconnected for simulation {simulation_id}")
        
    async def send_message(self, simulation_id: int, message_type: str, data: dict):
        """Send message to all connections for a simulation."""
        
        if simulation_id not in self.connections:
            return
            
        message = {
            "type": message_type,
            "simulation_id": simulation_id,
            "timestamp": datetime.utcnow().isoformat(),
            "data": data
        }
        
        disconnected = set()
        
        for websocket in self.connections[simulation_id]:
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(f"Error sending message to websocket: {e}")
                disconnected.add(websocket)
                
        # Clean up disconnected websockets
        for ws in disconnected:
            self.disconnect(ws, simulation_id)
            
    async def send_log(self, simulation_id: int, stream: str, line: str):
        """Send log output."""
        await self.send_message(simulation_id, "log", {
            "stream": stream,
            "line": line
        })
        
    async def send_status(self, simulation_id: int, status: str, details: dict = None):
        """Send status update."""
        data = {"status": status}
        if details:
            data.update(details)
        await self.send_message(simulation_id, "status", data)
        
    async def send_progress(self, simulation_id: int, iteration: int, energy: float, converged: bool):
        """Send progress update."""
        await self.send_message(simulation_id, "progress", {
            "iteration": iteration,
            "energy": energy,
            "converged": converged
        })
        
    async def broadcast_to_all(self, message_type: str, data: dict):
        """Broadcast to all connected clients."""
        
        message = {
            "type": message_type,
            "timestamp": datetime.utcnow().isoformat(),
            "data": data
        }
        
        disconnected = set()
        
        for websocket in self.active_connections:
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting to websocket: {e}")
                disconnected.add(websocket)
                
        # Clean up disconnected websockets
        for ws in disconnected:
            self.active_connections.discard(ws)
            # Also remove from simulation connections
            for sim_id, connections in list(self.connections.items()):
                connections.discard(ws)
                if not connections:
                    del self.connections[sim_id]


# Global connection manager instance
connection_manager = ConnectionManager()