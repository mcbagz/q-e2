"""Test script specifically for verifying stderr streaming."""

import requests
import json
import time
import asyncio
import websockets

BASE_URL = "http://localhost:8000"


async def monitor_simulation_websocket(simulation_id):
    """Monitor WebSocket for stderr messages."""
    uri = f"ws://localhost:8000/api/simulations/{simulation_id}/ws"
    
    print(f"Connecting to WebSocket for simulation {simulation_id}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("WebSocket connected! Monitoring for stdout and stderr messages...\n")
            
            # Listen for messages
            while True:
                try:
                    message = await websocket.recv()
                    data = json.loads(message)
                    
                    # Display log messages with stream info
                    if data['type'] == 'simulation_log':
                        stream = data['data'].get('stream', 'unknown')
                        msg = data['data'].get('message', '')
                        
                        if stream == 'stderr':
                            print(f"[STDERR] {msg}")
                        else:
                            print(f"[STDOUT] {msg}")
                    
                    elif data['type'] == 'simulation_progress':
                        print(f"\n[PROGRESS] Iteration: {data['data'].get('iteration')}, "
                              f"Energy: {data['data'].get('energy')}, "
                              f"Converged: {data['data'].get('converged')}")
                    
                    elif data['type'] == 'simulation_accuracy':
                        print(f"[ACCURACY] {data['data'].get('accuracy')}")
                    
                    elif data['type'] == 'simulation_cpu_time':
                        print(f"[CPU TIME] {data['data'].get('cpu_time')} seconds")
                    
                    elif data['type'] == 'simulation_status':
                        status = data['data'].get('status')
                        print(f"\n[STATUS] Simulation status changed to: {status}")
                        if status in ['completed', 'error', 'stopped', 'checkpointed']:
                            break
                            
                except websockets.exceptions.ConnectionClosed:
                    print("\nWebSocket connection closed")
                    break
                except Exception as e:
                    print(f"Error: {e}")
                    
    except Exception as e:
        print(f"WebSocket connection error: {e}")


def create_test_simulation():
    """Create a test simulation with silicon structure."""
    print("Creating test simulation with silicon structure...")
    
    data = {
        "prefix": "si_test",
        "outdir": "si_test_output",
        "calculation_type": "scf",
        "atoms": [
            {"element": "Si", "position": [0.0, 0.0, 0.0]},
            {"element": "Si", "position": [0.25, 0.25, 0.25]}
        ],
        "cell_parameters": [
            [5.43, 0.0, 0.0],
            [0.0, 5.43, 0.0],
            [0.0, 0.0, 5.43]
        ],
        "ecutwfc": 30.0,
        "k_points": {
            "type": "automatic",
            "grid": [4, 4, 4],
            "shift": [0, 0, 0]
        }
    }
    
    response = requests.post(f"{BASE_URL}/api/simulations/", json=data)
    if response.status_code == 200:
        sim_data = response.json()
        print(f"Created simulation with ID: {sim_data['id']}")
        return sim_data['id']
    else:
        print(f"Failed to create simulation: {response.text}")
        return None


def start_simulation(simulation_id):
    """Start the simulation."""
    print(f"\nStarting simulation {simulation_id}...")
    response = requests.post(f"{BASE_URL}/api/simulations/{simulation_id}/start")
    
    if response.status_code == 200:
        print("Simulation started successfully!")
        return True
    else:
        print(f"Failed to start simulation: {response.text}")
        return False


async def main():
    """Main test function."""
    print("=== Testing stderr Streaming for Quantum ESPRESSO Web UI ===\n")
    
    # Create a test simulation
    sim_id = create_test_simulation()
    if not sim_id:
        return
    
    # Start the simulation
    if not start_simulation(sim_id):
        return
    
    # Monitor via WebSocket
    print("\nMonitoring simulation output (stdout and stderr will be displayed differently)...\n")
    await monitor_simulation_websocket(sim_id)
    
    print("\nTest complete!")


if __name__ == "__main__":
    asyncio.run(main())