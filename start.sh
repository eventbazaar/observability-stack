#!/bin/bash

# Unified Observability Stack Startup Script
# This script starts the observability stack for both local and production environments

set -e

echo "🚀 Starting Observability Stack..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "📝 Please edit .env file with your configuration before running again."
    exit 1
fi

# Load environment variables
source .env

# Detect environment
if [ "${ENVIRONMENT:-production}" = "local" ]; then
    echo "🏠 Running in LOCAL development mode"
    # Override ports for local development to avoid conflicts
    export GRAFANA_PORT=${GRAFANA_PORT:-3002}
    export PROMETHEUS_PORT=${PROMETHEUS_PORT:-9091}
    export LOKI_PORT=${LOKI_PORT:-3101}
    export BACKEND_HOST=${BACKEND_HOST:-host.docker.internal}
    export LOG_PATH=${LOG_PATH:-../../logs}
else
    echo "🌐 Running in PRODUCTION mode"
fi

# Create log directory if it doesn't exist
mkdir -p ${LOG_PATH}

# Set proper permissions for log directory
chmod 755 ${LOG_PATH}

# Export all environment variables for docker-compose
export ENVIRONMENT
export GRAFANA_ADMIN_PASSWORD
export GRAFANA_PORT
export PROMETHEUS_PORT
export LOKI_PORT
export LOG_PATH
export BACKEND_HOST
export BACKEND_PORT
export MONGODB_HOST
export MONGODB_PORT

# Start the observability stack
echo "🐳 Starting Docker containers..."
cd docker
# Use sudo if user is not in docker group
if groups $USER | grep -q '\bdocker\b'; then
    docker-compose up -d
else
    echo "⚠️  User not in docker group, using sudo..."
    sudo docker-compose up -d
fi

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service status
echo "🔍 Checking service status..."
if groups $USER | grep -q '\bdocker\b'; then
    docker-compose ps
else
    sudo docker-compose ps
fi

echo ""
echo "✅ Observability Stack is running!"

# Get the appropriate host for URLs
if [ "${ENVIRONMENT:-production}" = "local" ]; then
    HOST="localhost"
else
    HOST=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")
fi

echo ""
echo "📊 Access URLs:"
echo "   Grafana:    http://${HOST}:${GRAFANA_PORT:-3001} (admin/${GRAFANA_ADMIN_PASSWORD:-admin})"
echo "   Prometheus: http://${HOST}:${PROMETHEUS_PORT:-9090}"
echo "   Loki:       http://${HOST}:${LOKI_PORT:-3100}"
echo ""
echo "📝 To view logs: docker-compose logs -f"
echo "🛑 To stop: docker-compose down"
echo ""
if [ "${ENVIRONMENT:-production}" = "local" ]; then
    echo "🔧 Make sure your backend is running on http://localhost:3000"
    echo "📁 Logs will be collected from: ${LOG_PATH}"
fi
