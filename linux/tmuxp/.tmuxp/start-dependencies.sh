#!/bin/bash

# Script to start Docker and RabbitMQ dependencies for tmuxp configurations

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Docker is not running. Starting Docker..."
        sudo systemctl start docker
        echo "Waiting for Docker to start..."
        while ! docker info >/dev/null 2>&1; do
            sleep 2
        done
        echo "Docker is now running."
    else
        echo "Docker is already running."
    fi
}

check_rabbitmq() {
    if docker ps --format "table {{.Names}}" | grep -q "^rabbitmq$"; then
        echo "RabbitMQ container is already running."
    elif docker ps -a --format "table {{.Names}}" | grep -q "^rabbitmq$"; then
        echo "RabbitMQ container exists but is stopped. Starting it..."
        docker start rabbitmq
        echo "Waiting for RabbitMQ to be ready..."
        while ! docker exec rabbitmq rabbitmq-diagnostics -q ping >/dev/null 2>&1; do
            sleep 2
        done
        echo "RabbitMQ is now running."
    else
        echo "RabbitMQ container does not exist. Creating and starting it..."
        docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3.13-management
        echo "Waiting for RabbitMQ to be ready..."
        while ! docker exec rabbitmq rabbitmq-diagnostics -q ping >/dev/null 2>&1; do
            sleep 2
        done
        echo "RabbitMQ is now running."
    fi
}

echo "Checking dependencies..."
check_docker
check_rabbitmq
echo "All dependencies are ready!"
