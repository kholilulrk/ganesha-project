#!/bin/bash
set -e

echo "===== Ganesha Energi Deploy Script ====="
echo ""

IP="${1:-203.194.115.28}"
USER="${2:-root}"
DOCKER_DIR="/opt/ganesha"

echo "Target: $USER@$IP"
echo "Remote dir: $DOCKER_DIR"
echo ""

# 1. Sync project files to VPS (exclude node_modules, .git, etc.)
echo ">>> Copying project files to VPS..."
rsync -avz --delete \
  --exclude '.git' \
  --exclude 'node_modules' \
  --exclude 'backend/ganesha-backend.exe' \
  --exclude 'backend/uploads' \
  --exclude 'mobile' \
  --exclude '*.log' \
  -e ssh \
  ./ "$USER@$IP:$DOCKER_DIR"

# 2. SSH into VPS and deploy
echo ""
echo ">>> Deploying on VPS..."
ssh "$USER@$IP" << EOF
  set -e
  cd $DOCKER_DIR

  # Load production env if exists
  if [ -f .env.production ]; then
    export \$(grep -v '^#' .env.production | xargs)
  fi

  # Pull latest images
  docker compose pull

  # Build and start containers
  docker compose up -d --build

  # Clean up old images
  docker image prune -f

  echo ""
  echo "===== Deploy complete! ====="
  echo "Frontend: http://$IP"
  echo "Backend:  http://$IP/api"
  echo "Health:   http://$IP/health"
EOF
