# Local Development Guide

This guide will help you run the observability stack locally on your laptop for development and testing.

## Prerequisites

- Docker and Docker Compose installed
- Your NestJS backend running locally
- At least 2GB RAM available

## Quick Start

### 1. **Start Your Backend First**
Make sure your NestJS backend is running locally:
```bash
# In your backend directory
npm run start:dev
# or
npm run start
```

### 2. **Start the Observability Stack**
```bash
cd observability-stack

# Copy local environment template
cp env.local .env.local

# Start the observability stack
./start-local.sh
```

### 3. **Access the Services**
- **Grafana**: http://localhost:3002 (admin/admin)
- **Prometheus**: http://localhost:9091
- **Loki**: http://localhost:3101

## Configuration

### Environment Variables (`.env.local`)

| Variable | Description | Default |
|----------|-------------|---------|
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | `admin` |
| `LOG_PATH` | Path to your backend logs | `../logs` |
| `BACKEND_HOST` | Your local backend host | `localhost` |
| `BACKEND_PORT` | Your local backend port | `3000` |
| `MONGODB_HOST` | Your local MongoDB host | `localhost` |
| `MONGODB_PORT` | Your local MongoDB port | `27017` |

### Backend Configuration

Make sure your backend has these environment variables in `.env`:

```bash
# Observability endpoints (local)
PROMETHEUS_ENABLED=true
PROMETHEUS_ENDPOINT=http://localhost:9091

GRAFANA_ENABLED=true
GRAFANA_ENDPOINT=http://localhost:3002

LOKI_ENABLED=true
LOKI_ENDPOINT=http://localhost:3101
```

## Testing the Setup

### 1. **Generate Some Logs**
```bash
# Test your backend endpoints
curl http://localhost:3000/health
curl http://localhost:3000/health/database
curl http://localhost:3000/metrics
```

### 2. **Check Prometheus Metrics**
- Go to http://localhost:9091
- Check "Targets" to see if your backend is being scraped
- Look for `eb_nestjs_` metrics

### 3. **Check Loki Logs**
- Go to http://localhost:3101/loki/api/v1/labels
- Should see labels: `job`, `level`, `context`, `requestId`, etc.

### 4. **Check Grafana**
- Go to http://localhost:3002
- Login with admin/admin
- Go to "Explore" → "Loki"
- Try this query: `{job="eb-nestjs"}`

## Log Queries for Local Development

### Health API Logs
```logql
{job="eb-nestjs"} | json | url=~"/health.*"
```

### All HTTP Requests
```logql
{job="eb-nestjs"} | json | context="HTTP"
```

### Error Logs
```logql
{job="eb-nestjs"} | json | level="error"
```

### Specific Request ID
```logql
{job="eb-nestjs"} | json | requestId="your-request-id-here"
```

## Troubleshooting

### Services Not Starting
```bash
cd observability-stack/docker
docker-compose logs -f
```

### Backend Not Being Scraped
1. Check if your backend is running on http://localhost:3000
2. Check if `/metrics` endpoint is accessible: http://localhost:3000/metrics
3. Check Prometheus targets: http://localhost:9090/targets

### Logs Not Appearing
1. Check if logs directory exists: `ls -la ../logs/`
2. Check Promtail logs: `docker-compose logs promtail`
3. Check Loki logs: `docker-compose logs loki`

### Port Conflicts
If you have port conflicts, you can modify the ports in `docker/docker-compose.yml`:
```yaml
ports:
  - "3002:3000"  # Grafana on 3002 instead of 3001
  - "9091:9090"  # Prometheus on 9091 instead of 9090
  - "3101:3100"  # Loki on 3101 instead of 3100
```

## Development Workflow

### 1. **Start Everything**
```bash
# Terminal 1: Start backend
cd your-backend-directory
npm run start:dev

# Terminal 2: Start observability
cd observability-stack
./start-local.sh
```

### 2. **Monitor Your Application**
- Use Grafana to visualize metrics and logs
- Use Prometheus to query metrics directly
- Use Loki to search through logs

### 3. **Stop Everything**
```bash
# Stop observability stack
cd observability-stack/docker
docker-compose down

# Stop backend (Ctrl+C in terminal)
```

## Useful Commands

### View Logs
```bash
cd observability-stack/docker
docker-compose logs -f [service-name]
```

### Restart Services
```bash
docker-compose restart [service-name]
```

### Check Service Status
```bash
docker-compose ps
```

### Clean Up
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: This will delete all data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## Customization

### Add Custom Dashboards
1. Create dashboard JSON files in `grafana/dashboards/`
2. Restart Grafana: `docker-compose restart grafana`

### Modify Prometheus Configuration
1. Edit `config/prometheus.yml`
2. Restart Prometheus: `docker-compose restart prometheus`

### Modify Loki Configuration
1. Edit `config/loki-config.yml`
2. Restart Loki: `docker-compose restart loki`

## Performance Tips

### For Better Performance
1. **Increase Docker resources** in Docker Desktop settings
2. **Use SSD storage** for better I/O performance
3. **Close unnecessary applications** to free up RAM

### For Development
1. **Use shorter retention periods** in Prometheus config
2. **Disable unnecessary metrics** in your backend
3. **Use log rotation** to prevent disk space issues

## Next Steps

Once you're comfortable with the local setup:
1. Deploy to your EC2 instances
2. Configure production environment variables
3. Set up monitoring alerts
4. Create custom dashboards for your specific needs

## Support

If you encounter issues:
1. Check the logs: `docker-compose logs -f`
2. Verify your backend is running and accessible
3. Check port availability: `netstat -tlnp | grep -E ':(3000|3001|9090|3100)'`
4. Review the configuration files
