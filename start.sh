#!/bin/bash
set -e

# Cleanup old containers (Including leftovers from previous phases)
echo "Stopping old containers..."
# Ensure permissions on maintenance directory
chmod -R 755 nginx/maintenance || true

docker rm -f learner_nginx admin_nginx maintenance_admin maintenance_redis backend_learner backend_admin_portal maintenance_nginx maintenance_backend 2>/dev/null || true
docker network rm maintenance_net 2>/dev/null || true

# Create Network
echo "Creating network..."
docker network create maintenance_net || true

# 1. Start Redis
echo "Starting Redis..."
docker run -d --name maintenance_redis \
  --network maintenance_net \
  --network-alias redis \
  -p 6379:6379 \
  redis:alpine

# 2. Start Learner Backend
echo "Starting Learner App..."
docker run -d --name backend_learner \
  --network maintenance_net \
  --network-alias backend_learner \
  -v $(pwd)/learner:/usr/share/nginx/html:ro \
  nginx:alpine

# 3. Start Admin Portal Backend
echo "Starting Admin Portal..."
docker run -d --name backend_admin_portal \
  --network maintenance_net \
  --network-alias backend_admin_portal \
  -v $(pwd)/admin_portal:/usr/share/nginx/html:ro \
  nginx:alpine

# 4. Maintenance Admin UI
echo "Starting Maintenance Interface..."
docker build -t maintenance_admin_img ./admin
docker run -d --name maintenance_admin \
  --network maintenance_net \
  -p 3000:3000 \
  -e REDIS_HOST=maintenance_redis \
  maintenance_admin_img

# 5. Start Nginx for LEARNER (Port 8086)
echo "Starting Learner Nginx (Port 8086)..."
docker run -d --name learner_nginx \
  --network maintenance_net \
  -p 8086:80 \
  -v $(pwd)/nginx/learner.conf:/usr/local/openresty/nginx/conf/nginx.conf:ro \
  -v $(pwd)/nginx/common:/etc/nginx/common:ro \
  -v $(pwd)/nginx/lua:/etc/nginx/lua:ro \
  -v $(pwd)/nginx/maintenance:/var/www/maintenance:ro \
  openresty/openresty:alpine

# 6. Start Nginx for ADMIN PORTAL (Port 8087)
echo "Starting Admin Nginx (Port 8087)..."
docker run -d --name admin_nginx \
  --network maintenance_net \
  -p 8087:80 \
  -v $(pwd)/nginx/admin.conf:/usr/local/openresty/nginx/conf/nginx.conf:ro \
  -v $(pwd)/nginx/common:/etc/nginx/common:ro \
  -v $(pwd)/nginx/lua:/etc/nginx/lua:ro \
  -v $(pwd)/nginx/maintenance:/var/www/maintenance:ro \
  openresty/openresty:alpine

echo "✅ Environment Started!"
echo "Learner App:      http://localhost:8086"
echo "Admin Portal:     http://localhost:8087"
echo "Maintenance UI:   http://localhost:3000"
