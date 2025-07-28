# Quantum ESPRESSO with Web UI

This project combines Quantum ESPRESSO with a web-based user interface, all runnable within a single Docker container.

## Changes Made

This repository now includes a unified Docker setup that integrates:

-   **Quantum ESPRESSO:** The core simulation engine.
-   **Web UI Backend:** A Python-based backend for managing simulations and interacting with Quantum ESPRESSO.
-   **Web UI Frontend:** A modern web interface for users to interact with the system.

Previously, Quantum ESPRESSO and the web UI components were intended to run in separate containers. This setup consolidates them into a single, self-contained Docker image, simplifying deployment and management.

## How to Launch the Docker Container

To build and run the combined Docker container, follow these steps:

1.  **Ensure Docker is installed:** If you don't have Docker installed, follow the instructions on the [official Docker website](https://docs.docker.com/get-docker/).

2.  **Navigate to the project root:** Open your terminal or command prompt and change your directory to the root of this project (where this `README.md` file is located):

    ```bash
    cd /path/to/your/q-e2
    ```

3.  **Build the Docker image:** This command will build the Docker image. It might take some time as it compiles Quantum ESPRESSO and builds the web UI components.

    ```bash
    docker build -t qe-web-ui .
    ```

    -   `-t qe-web-ui`: Tags the image with the name `qe-web-ui`. You can choose a different name if you prefer.
    -   `.`: Specifies that the Dockerfile is in the current directory.

4.  **Run the Docker container:** Once the image is built, you can run the container using the following command:

    ```bash
    docker run -d -p 80:80 -p 8000:8000 --name qe-web-app qe-web-ui
    ```

    -   `-d`: Runs the container in detached mode (in the background).
    -   `-p 80:80`: Maps port 80 of your host machine to port 80 inside the container (for the web UI frontend).
    -   `-p 8000:8000`: Maps port 8000 of your host machine to port 8000 inside the container (for the web UI backend API).
    -   `--name qe-web-app`: Assigns a name to your container (`qe-web-app`). You can choose a different name.
    -   `qe-web-ui`: Specifies the name of the Docker image to run.

5.  **Access the Web UI:** After the container is running, you can access the web interface by opening your web browser and navigating to:

    ```
    http://localhost/
    ```

    The backend API will be accessible at `http://localhost:8000/`.

## Stopping and Removing the Container

To stop the running container:

```bash
docker stop qe-web-app
```

To remove the container (after stopping it):

```bash
docker rm qe-web-app
```

To remove the Docker image (if you no longer need it):

```bash
docker rmi qe-web-ui
```
