# Unified Observability Stack Setup

This is now a **single, unified setup** that works for both local development and production deployment! 🎉

## Quick Start

### 1. **Configure Environment**
```bash
# Copy the environment template
cp env.example .env

# Edit the configuration
nano .env
```

### 2. **For Local Development**
Set `ENVIRONMENT=local` in your `.env` file:
```bash
ENVIRONMENT=local
GRAFANA_PORT=3002
PROMETHEUS_PORT=9091
LOKI_PORT=3101
LOG_PATH=../../logs
BACKEND_HOST=host.docker.internal
```

### 3. **For Production**
Set `ENVIRONMENT=production` in your `.env` file:
```bash
ENVIRONMENT=production
GRAFANA_PORT=3001
PROMETHEUS_PORT=9090
LOKI_PORT=3100
LOG_PATH=/var/log/app
BACKEND_HOST=your-backend-ip
```

### 4. **Start the Stack**
```bash
# Make the script executable
chmod +x start.sh

# Start the observability stack
./start.sh
```

## What's Different Now?

✅ **Single Docker Compose file** - No more `docker-compose.local.yml` vs `docker-compose.yml`  
✅ **Single Prometheus config** - No more `prometheus.local.yml` vs `prometheus.yml`  
✅ **Single startup script** - No more `start-local.sh` vs `start.sh`  
✅ **Environment-based configuration** - One `.env` file for both environments  
✅ **Automatic port detection** - Local development uses different ports to avoid conflicts  

## Ports

| Service | Local Development | Production |
|---------|------------------|------------|
| Grafana | 3002 | 3001 |
| Prometheus | 9091 | 9090 |
| Loki | 3101 | 3100 |

## Access URLs

### Local Development
- **Grafana**: http://localhost:3002 (admin/admin)
- **Prometheus**: http://localhost:9091
- **Loki**: http://localhost:3101

### Production
- **Grafana**: http://your-server-ip:3001 (admin/your-password)
- **Prometheus**: http://your-server-ip:9090
- **Loki**: http://your-server-ip:3100

## Environment Variables

| Variable | Description | Default | Local Override |
|----------|-------------|---------|----------------|
| `ENVIRONMENT` | Environment mode | `production` | `local` |
| `GRAFANA_PORT` | Grafana port | `3001` | `3002` |
| `PROMETHEUS_PORT` | Prometheus port | `9090` | `9091` |
| `LOKI_PORT` | Loki port | `3100` | `3101` |
| `LOG_PATH` | Log directory path | `/var/log/app` | `../../logs` |
| `BACKEND_HOST` | Backend host | `localhost` | `host.docker.internal` |
| `BACKEND_PORT` | Backend port | `3000` | `3000` |

## Commands

```bash
# Start the stack
./start.sh

# View logs
cd docker && docker-compose logs -f

# Stop the stack
cd docker && docker-compose down

# Restart a service
cd docker && docker-compose restart [service-name]
```

## Troubleshooting

### Port Conflicts
If you have port conflicts, edit your `.env` file and change the port numbers.

### Backend Not Being Scraped
1. Make sure your backend is running
2. Check the `BACKEND_HOST` and `BACKEND_PORT` in `.env`
3. For local development, use `host.docker.internal` as the host

### Logs Not Appearing
1. Check the `LOG_PATH` in your `.env` file
2. Make sure the log directory exists and has proper permissions
3. Check Promtail logs: `docker-compose logs promtail`

## Migration from Old Setup

If you were using the old separate setup:

1. **Delete old files** (optional):
   ```bash
   rm docker-compose.local.yml
   rm config/prometheus.local.yml
   rm env.local
   rm start-local.sh
   ```

2. **Update your `.env` file** to use the new unified format

3. **Use the single `start.sh` script** for both local and production

That's it! The confusion is now gone - one setup for everything! 🚀
