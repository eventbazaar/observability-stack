# Observability Stack

A **unified** production-ready observability stack for monitoring NestJS applications with Prometheus, Grafana, and Loki. Works for both local development and production deployment! 🎉

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backend EC2   │    │  MongoDB EC2    │    │Observability EC2│
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │  NestJS   │  │    │  │  MongoDB  │  │    │  │ Prometheus│  │
│  │  App      │  │    │  │           │  │    │  │           │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│        │        │    │                 │    │        │        │
│  ┌───────────┐  │    │                 │    │  ┌───────────┐  │
│  │   Logs    │  │    │                 │    │  │   Grafana │  │
│  │  Files    │  │    │                 │    │  │           │  │
│  └───────────┘  │    │                 │    │  └───────────┘  │
│        │        │    │                 │    │        │        │
│  ┌───────────┐  │    │                 │    │  ┌───────────┐  │
│  │ Promtail  │  │    │                 │    │  │    Loki   │  │
│  │(Optional) │  │    │                 │    │  │           │  │
│  └───────────┘  │    │                 │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Components

### 1. Prometheus
- **Purpose**: Metrics collection and storage
- **Port**: 9090 (production) / 9091 (local)
- **Data**: HTTP request metrics, system metrics, custom business metrics

### 2. Grafana
- **Purpose**: Visualization and dashboards
- **Port**: 3001 (production) / 3002 (local)
- **Features**: Pre-built dashboards, alerting, data source management

### 3. Loki
- **Purpose**: Log aggregation and storage
- **Port**: 3100 (production) / 3101 (local)
- **Data**: Application logs, structured JSON logs

### 4. Promtail
- **Purpose**: Log collection and forwarding
- **Deployment**: Can run on backend EC2 or observability EC2
- **Data Source**: Log files from NestJS application

## Quick Start

1. **Clone the observability stack**:
```bash
git clone <your-observability-repo>
cd observability-stack
```

2. **Configure environment**:
```bash
cp env.example .env
nano .env
```

3. **Start the stack**:
```bash
./start.sh
```

4. **Access services**:

**Local Development:**
- Grafana: http://localhost:3002
- Prometheus: http://localhost:9091
- Loki: http://localhost:3101

**Production:**
- Grafana: http://your-ec2-ip:3001
- Prometheus: http://your-ec2-ip:9090
- Loki: http://your-ec2-ip:3100

## Configuration

### Environment Variables

| Variable | Description | Default | Local Override |
|----------|-------------|---------|----------------|
| `ENVIRONMENT` | Environment mode | `production` | `local` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | `admin` | `admin` |
| `GRAFANA_PORT` | Grafana port | `3001` | `3002` |
| `PROMETHEUS_PORT` | Prometheus port | `9090` | `9091` |
| `LOKI_PORT` | Loki port | `3100` | `3101` |
| `LOG_PATH` | Path to application logs | `/var/log/app` | `../../logs` |
| `BACKEND_HOST` | Backend host | `localhost` | `host.docker.internal` |
| `BACKEND_PORT` | Backend application port | `3000` | `3000` |
| `MONGODB_HOST` | MongoDB host | `localhost` | `localhost` |
| `MONGODB_PORT` | MongoDB port | `27017` | `27017` |

### Backend Configuration

Add these environment variables to your NestJS backend:

**Local Development:**
```bash
PROMETHEUS_ENABLED=true
PROMETHEUS_ENDPOINT=http://localhost:9091
GRAFANA_ENABLED=true
GRAFANA_ENDPOINT=http://localhost:3002
LOKI_ENABLED=true
LOKI_ENDPOINT=http://localhost:3101
```

**Production:**
```bash
PROMETHEUS_ENABLED=true
PROMETHEUS_ENDPOINT=http://your-observability-ec2-ip:9090
GRAFANA_ENABLED=true
GRAFANA_ENDPOINT=http://your-observability-ec2-ip:3001
LOKI_ENABLED=true
LOKI_ENDPOINT=http://your-observability-ec2-ip:3100
```

## Log Collection

### Option 1: Mount Log Directory (Same EC2)
If your backend runs on the same EC2 as observability:

```bash
# Update LOG_PATH in .env
LOG_PATH=/path/to/your/backend/logs
```

### Option 2: Remote Log Collection (Different EC2)
If your backend runs on a different EC2:

1. Install Promtail on backend EC2
2. Configure Promtail to send logs to observability EC2
3. See `INSTALLATION.md` for detailed steps

## Monitoring Setup

### 1. Prometheus Targets
Configure targets in `config/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'nestjs-app'
    static_configs:
      - targets: ['your-backend-ec2-ip:3000']
    metrics_path: '/metrics'
    scrape_interval: 5s
```

### 2. Grafana Dashboards
- Pre-built NestJS dashboard included
- Custom dashboards can be added to `grafana/dashboards/`
- Data sources auto-configured

### 3. Log Queries
Use LogQL queries in Grafana to filter logs:

```logql
# All health API logs
{job="eb-nestjs"} | json | url=~"/health.*"

# Error logs only
{job="eb-nestjs"} | json | level="error"

# Specific request ID
{job="eb-nestjs"} | json | requestId="your-request-id"
```

## File Structure

```
observability-stack/
├── docker/
│   └── docker-compose.yml          # Main Docker Compose file
├── config/
│   ├── prometheus.yml              # Prometheus configuration
│   ├── loki-config.yml             # Loki configuration
│   └── promtail-config.yml         # Promtail configuration
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── datasources.yml     # Grafana data sources
│   │   └── dashboards/
│   │       └── dashboards.yml      # Dashboard provisioning
│   └── dashboards/
│       └── nestjs-dashboard.json   # Pre-built NestJS dashboard
├── start.sh                        # Startup script
├── env.example                     # Environment template
├── README.md                       # This file
└── INSTALLATION.md                 # Detailed installation guide
```

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
2. Restart affected services

### Backup Data
```bash
# Backup Grafana
docker run --rm -v observability-stack_docker_grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz -C /data .

# Backup Prometheus
docker run --rm -v observability-stack_docker_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz -C /data .
```

## Security

- Change default passwords
- Use HTTPS in production
- Configure firewall rules
- Regular security updates
- Monitor access logs

## Scaling

For high-traffic applications:
- Use external storage (S3, EBS)
- Configure Loki clustering
- Use Grafana clustering
- Implement log retention policies

## Troubleshooting

See `INSTALLATION.md` for detailed troubleshooting steps.

## Support

For issues and questions:
1. Check the logs: `docker-compose logs -f`
2. Verify configuration files
3. Check network connectivity
4. Review the installation guide
