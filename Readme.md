# MaintenanceModeNginx

## Overview
This project implements a flexible, centralized maintenance mode system using **Nginx (OpenResty)**, **Lua**, and **Redis**. It allows you to toggle maintenance pages dynamically for different parts of your application (e.g., Learner App, Admin Portal) without restarting services or redeploying code.

The system supports:
*   **Granular Control**: Toggle maintenance for specific scopes (`LEARNER`, `ADMIN_PORTAL`) or globally.
*   **Dynamic Content**: Serve custom maintenance messages injected via Redis.
*   **HTML Maintenance Pages**: User-friendly, branded maintenance screens.
*   **Zero Downtime**: Switch modes instantly via API or CLI.

## Architecture

The system consists of the following Dockerized components:

1.  **Nginx (OpenResty)**: The reverse proxy that routes traffic. It uses Lua scripts to check Redis for maintenance status before forwarding requests to the actual backend.
2.  **Redis**: Acts as the "source of truth" for maintenance state (active/inactive) and messages.
3.  **Maintenance Admin Service**: A Node.js/Express app that provides a REST API and a Web UI to view and update maintenance settings in Redis.
4.  **Backend Services**: Simulated Nginx instances representing the actual application backends (Learner App, Admin Portal).

## Prerequisites

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

## Getting Started

1.  **Start the Environment**:
    Use the provided helper script to clean up old containers and start the entire stack.
    ```bash
    ./start.sh
    ```
    This script will:
    *   Stop and remove existing containers.
    *   Create a dedicated Docker network.
    *   Start Redis, Backend services, Admin API, and Nginx proxies.
    *   Output the access URLs for all services.

2.  **Access the Services**:
    Once the startup script completes, you can access:

    *   **Learner App**: [http://localhost:8086](http://localhost:8086)
    *   **Admin Portal**: [http://localhost:8087](http://localhost:8087)
    *   **Maintenance Dashboard**: [http://localhost:3000](http://localhost:3000)

## Usage

### Toggling Maintenance Mode

You can control maintenance mode using the Web UI or the provided CLI script.

#### Option 1: Using the Web Dashboard
1.  Navigate to [http://localhost:3000](http://localhost:3000).
2.  Select the scope (e.g., `LEARNER` or `ADMIN_PORTAL`).
3.  Toggle the **Active** switch.
4.  (Optional) Enter a custom message (e.g., "Planned Upgrade in Progress").
5.  Click **Update**.

#### Option 2: Using the CLI Script (CI/CD)
Use `cicd_toggle.sh` to automate maintenance toggles, useful for deployment pipelines.

**Syntax**:
```bash
./cicd_toggle.sh <SCOPE> <ON|OFF>
```

**Examples**:
```bash
# Enable maintenance for Learner App
./cicd_toggle.sh LEARNER ON

# Disable maintenance for Learner App
./cicd_toggle.sh LEARNER OFF
```

## Project Structure

*   `admin/`: Node.js application for the Maintenance Admin API and Dashboard.
*   `nginx/`: Nginx configuration files and Lua scripts.
    *   `lua/`: Contains `maintenance.lua` which implements the logic.
    *   `common/`: Shared Nginx configuration snippets.
*   `learner/`: Static content for the simulated Learner App backend.
*   `admin_portal/`: Static content for the simulated Admin Portal backend.
*   `start.sh`: Main startup script.
*   `cicd_toggle.sh`: Helper script for API interactions.
*   `docker-compose.yml`: Definition of all services.
