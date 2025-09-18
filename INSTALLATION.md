# Observability Stack Installation Guide

This guide will help you install and configure the observability stack on your EC2 instance.

## Prerequisites

- Ubuntu 20.04+ or Amazon Linux 2
- Docker and Docker Compose installed
- At least 2GB RAM and 10GB disk space
- Ports 3001, 9090, 3100 available

## Installation Steps

### 1. Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again to apply docker group changes
```

### 2. Clone or Copy Observability Stack

```bash
# If using git
git clone <your-observability-repo>
cd observability-stack

# Or copy the observability-stack folder to your EC2 instance
```

### 3. Configure Environment

```bash
# Copy environment template
cp env.example .env

# Edit configuration
nano .env
```

Update the following variables in `.env`:
```bash
# Grafana Configuration
GRAFANA_ADMIN_PASSWORD=your_secure_password

# Log Collection (path where your backend writes logs)
LOG_PATH=/var/log/app

# Backend Application Endpoints
BACKEND_HOST=your-backend-ec2-ip
BACKEND_PORT=3000

# MongoDB Endpoints
MONGODB_HOST=your-mongodb-ec2-ip
MONGODB_PORT=27017
```

### 4. Start the Observability Stack

```bash
# Make script executable
chmod +x start.sh

# Start the stack
./start.sh
```

### 5. Verify Installation

Check if all services are running:
```bash
cd docker
docker-compose ps
```

Access the services:
- **Grafana**: http://your-ec2-ip:3001
- **Prometheus**: http://your-ec2-ip:9090
- **Loki**: http://your-ec2-ip:3100

## Backend Configuration

In your NestJS backend, add these environment variables:

```bash
# .env file in your backend
PROMETHEUS_ENDPOINT=http://your-observability-ec2-ip:9090
GRAFANA_ENDPOINT=http://your-observability-ec2-ip:3001
LOKI_ENDPOINT=http://your-observability-ec2-ip:3100
```

## Log Collection Setup

### Option 1: Mount Log Directory (Recommended)
If your backend runs on the same EC2 instance:
```bash
# Update LOG_PATH in .env to point to your backend logs
LOG_PATH=/path/to/your/backend/logs
```

### Option 2: Remote Log Collection
If your backend runs on a different EC2 instance:

1. **Install Promtail on Backend EC2**:
```bash
# Download Promtail
wget https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail
```

2. **Create Promtail Config**:
```bash
sudo mkdir -p /etc/promtail
sudo nano /etc/promtail/config.yml
```

Add this configuration:
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://your-observability-ec2-ip:3100/loki/api/v1/push

scrape_configs:
  - job_name: app-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: eb-nestjs
          __path__: /var/log/app/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            context: context
            requestId: requestId
            method: method
            url: url
            statusCode: statusCode
            duration: duration
      - timestamp:
          source: timestamp
          format: RFC3339
      - labels:
          level:
          context:
          requestId:
          method:
          statusCode:
```

3. **Create Systemd Service**:
```bash
sudo vi /etc/systemd/system/promtail.service
```

Add this content:
```ini
[Unit]
Description=Promtail
After=network.target

[Service]
Type=simple
User=promtail
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

4. **Start Promtail**:
```bash
sudo useradd -r promtail
sudo chown -R promtail:promtail /etc/promtail
sudo systemctl enable promtail
sudo systemctl start promtail
```

## Monitoring Setup

### 1. Configure Prometheus Targets
Edit `config/prometheus.yml` to add your backend and MongoDB targets:

```yaml
scrape_configs:
  - job_name: 'nestjs-app'
    static_configs:
      - targets: ['your-backend-ec2-ip:3000']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'mongodb'
    static_configs:
      - targets: ['your-mongodb-ec2-ip:27017']
    scrape_interval: 10s
```

### 2. Access Grafana Dashboards
1. Go to http://your-ec2-ip:3001
2. Login with admin/your_password
3. Import the NestJS dashboard
4. Configure data sources if needed

## Maintenance

### View Logs
```bash
cd docker
docker-compose logs -f [service-name]
```

### Restart Services
```bash
cd docker
docker-compose restart [service-name]
```

### Update Configuration
1. Edit config files
2. Restart affected services:
```bash
docker-compose restart [service-name]
```

### Backup Data
```bash
# Backup Grafana data
docker run --rm -v observability-stack_docker_grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz -C /data .

# Backup Prometheus data
docker run --rm -v observability-stack_docker_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz -C /data .
```

## Troubleshooting

### Check Service Status
```bash
cd docker
docker-compose ps
docker-compose logs [service-name]
```

### Check Port Availability
```bash
sudo netstat -tlnp | grep -E ':(3001|9090|3100)'
```

### Check Disk Space
```bash
df -h
docker system df
```

### Reset Everything
```bash
cd docker
docker-compose down -v
docker system prune -a
```

## Security Considerations

1. **Change default passwords**
2. **Use HTTPS in production**
3. **Configure firewall rules**
4. **Regular security updates**
5. **Monitor access logs**

## Scaling

For high-traffic applications:
1. Use external storage (S3, EBS) for Loki and Prometheus data
2. Configure Loki clustering
3. Use Grafana clustering
4. Implement log retention policies
