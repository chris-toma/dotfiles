#!/bin/bash

# Comprehensive script to start all services with dependency management
# This script will:
# 1. Check and start Docker if needed
# 2. Check and start RabbitMQ if needed
# 3. Start all microservices with retry mechanism

set -e

echo "Starting comprehensive microservices startup..."
echo "=================================================="

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_docker() {
    echo "Checking Docker status..."
    if ! docker info >/dev/null 2>&1; then
        echo "Docker is not running. Starting Docker..."
        sudo systemctl start docker
        echo "Waiting for Docker to start..."
        while ! docker info >/dev/null 2>&1; do
            sleep 2
            echo -n "."
        done
        echo ""
        echo "Docker is now running."
    else
        echo "Docker is already running."
    fi
}

check_rabbitmq() {
    echo "Checking RabbitMQ status..."
    if docker ps --format "table {{.Names}}" | grep -q "^rabbitmq$"; then
        echo "RabbitMQ container is already running."
    elif docker ps -a --format "table {{.Names}}" | grep -q "^rabbitmq$"; then
        echo "RabbitMQ container exists but is stopped. Starting it..."
        docker start rabbitmq
        echo "Waiting for RabbitMQ to be ready..."
        while ! docker exec rabbitmq rabbitmq-diagnostics -q ping >/dev/null 2>&1; do
            sleep 2
            echo -n "."
        done
        echo ""
        echo "RabbitMQ is now running."
    else
        echo "RabbitMQ container does not exist. Creating and starting it..."
        docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3.13-management
        echo "Waiting for RabbitMQ to be ready..."
        while ! docker exec rabbitmq rabbitmq-diagnostics -q ping >/dev/null 2>&1; do
            sleep 2
            echo -n "."
        done
        echo ""
        echo "RabbitMQ is now running."
    fi
}

check_tmuxp() {
    echo "Checking tmuxp installation..."
    if ! command_exists "tmuxp"; then
        echo "tmuxp is not installed. Installing it now..."
        if command_exists "pip3"; then
            pip3 install tmuxp
        elif command_exists "pip"; then
            pip install tmuxp
        else
            echo "Error: Neither pip nor pip3 found. Please install tmuxp manually:"
            echo "pip install tmuxp"
            exit 1
        fi
        echo "tmuxp installed successfully."
    else
        echo "tmuxp is already installed."
    fi
}

check_project_directory() {
    echo "Checking project directory..."
    if [ ! -d "$HOME/projects/captiv8/go-microservices" ]; then
        echo "Project directory not found: $HOME/projects/captiv8/go-microservices"
        echo "Please ensure the project directory exists and contains the 'fut' script."
        exit 1
    fi
    echo "Project directory found."
}

check_fut_script() {
    echo "Checking fut script..."
    if [ ! -f "$HOME/projects/captiv8/go-microservices/fut" ]; then
        echo "fut script not found in project directory."
        echo "Please ensure the fut script exists and is executable."
        exit 1
    fi
    if [ ! -x "$HOME/projects/captiv8/go-microservices/fut" ]; then
        echo "Making fut script executable..."
        chmod +x "$HOME/projects/captiv8/go-microservices/fut"
    fi
    echo "fut script is ready."
}

main() {
    echo "Starting comprehensive startup process..."
    echo ""

    check_tmuxp
    check_project_directory
    check_fut_script
    check_docker
    check_rabbitmq

    echo ""
    echo "All dependencies are ready! Starting microservices..."
    echo "=================================================="

    echo "Loading master tmuxp configuration..."
    tmuxp load "$HOME/.tmuxp/master.yaml"

    echo ""
    echo "All services started successfully!"
    echo "=================================================="
    echo "You can now use tmux to switch between windows:"
    echo "  - Use 'tmux list-windows' to see all available windows"
    echo "  - Use 'tmux attach' to attach to the session"
    echo "  - Use Ctrl+b then window number to switch windows"
    echo ""
    echo "Services are running with retry mechanism (5 retries with exponential backoff)"
    echo "Check individual windows for service status and logs."
}

main
