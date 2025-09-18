#!/bin/bash

# Production Deployment Script for AWS EC2
# This script sets up the observability stack on an EC2 instance

set -e

echo "🚀 Deploying Observability Stack to Production..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root. Use a regular user with sudo privileges."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please logout and login again, then run this script again."
    exit 0
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from production template..."
    cp env.production .env
    echo "📝 Please edit .env file with your production configuration:"
    echo "   - GRAFANA_ADMIN_PASSWORD"
    echo "   - BACKEND_HOST (your backend EC2 IP)"
    echo "   - MONGODB_HOST (your MongoDB EC2 IP)"
    echo "   - LOG_PATH (path to your backend logs)"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Load environment variables
source .env

# Create log directory
echo "📁 Creating log directory..."
sudo mkdir -p ${LOG_PATH}
sudo chown $USER:$USER ${LOG_PATH}
chmod 755 ${LOG_PATH}

# Create systemd service for auto-start
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/observability-stack.service > /dev/null <<EOF
[Unit]
Description=Observability Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose -f docker/docker-compose.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker/docker-compose.yml down
TimeoutStartSec=0
User=$USER

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable observability-stack.service

# Start the observability stack
echo "🐳 Starting observability stack..."
./start.sh

# Check if services are running
echo "🔍 Checking service status..."
sleep 10
cd docker
docker-compose ps

echo ""
echo "✅ Observability Stack deployed successfully!"
echo ""
echo "📊 Access URLs:"
echo "   Grafana:    http://$(curl -s ifconfig.me):${GRAFANA_PORT:-3001}"
echo "   Prometheus: http://$(curl -s ifconfig.me):${PROMETHEUS_PORT:-9090}"
echo "   Loki:       http://$(curl -s ifconfig.me):${LOKI_PORT:-3100}"
echo ""
echo "🔧 Management commands:"
echo "   Start:   sudo systemctl start observability-stack"
echo "   Stop:    sudo systemctl stop observability-stack"
echo "   Status:  sudo systemctl status observability-stack"
echo "   Logs:    cd docker && docker-compose logs -f"
echo ""
echo "🔒 Security recommendations:"
echo "   1. Change the default Grafana password"
echo "   2. Configure firewall rules"
echo "   3. Use HTTPS in production"
echo "   4. Regular security updates"
