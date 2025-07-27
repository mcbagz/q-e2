"""Simple test script for the QE Web UI API."""

import requests
import json
import time
import asyncio
import websockets

BASE_URL = "http://localhost:8000"


def test_health():
    """Test health endpoint."""
    print("Testing health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print()


def test_create_simulation():
    """Test creating a simulation."""
    print("Creating a new simulation...")
    
    data = {
        "prefix": "test_si",
        "outdir": "test_output",
        "calculation_type": "scf"
    }
    
    response = requests.post(f"{BASE_URL}/api/simulations/", json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        return response.json()["id"]
    return None


def test_list_simulations():
    """Test listing simulations."""
    print("Listing simulations...")
    response = requests.get(f"{BASE_URL}/api/simulations/")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print()


def test_start_simulation(simulation_id):
    """Test starting a simulation."""
    print(f"Starting simulation {simulation_id}...")
    
    data = {
        "action": "start",
        "simulation_id": simulation_id
    }
    
    response = requests.post(f"{BASE_URL}/api/simulations/control", json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print()


async def test_websocket(simulation_id):
    """Test WebSocket connection."""
    print(f"Connecting to WebSocket for simulation {simulation_id}...")
    
    uri = f"ws://localhost:8000/api/simulations/{simulation_id}/ws"
    
    try:
        async with websockets.connect(uri) as websocket:
            print("WebSocket connected!")
            
            # Listen for messages for 30 seconds
            timeout = time.time() + 30
            while time.time() < timeout:
                try:
                    message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                    data = json.loads(message)
                    print(f"Received: {data['type']} - {data.get('data', {})}")
                except asyncio.TimeoutError:
                    continue
                except websockets.exceptions.ConnectionClosed:
                    print("WebSocket closed")
                    break
                    
    except Exception as e:
        print(f"WebSocket error: {e}")


def main():
    """Run tests."""
    print("=== Quantum ESPRESSO Web UI API Test ===\n")
    
    # Test health
    test_health()
    
    # Test list simulations
    test_list_simulations()
    
    # Create a simulation
    sim_id = test_create_simulation()
    
    if sim_id:
        # Start the simulation
        test_start_simulation(sim_id)
        
        # Monitor via WebSocket
        print("\nMonitoring simulation output via WebSocket...")
        print("(This will run for 30 seconds or until the calculation completes)\n")
        asyncio.run(test_websocket(sim_id))
    
    print("\nTest complete!")


if __name__ == "__main__":
    main()