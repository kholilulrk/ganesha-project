# Maintenance Guide — Ganesha Project

## Prasyarat

| Tools | Versi Minimal |
|---|---|
| Go | 1.25+ |
| Node.js | 20+ |
| Flutter | (sesuai project) |
| Docker & Docker Compose | latest |

---

## Struktur Proyek

```
├── backend/          # Go API (Gin + GORM + PostgreSQL)
├── frontend/         # Vue 3 + Vite + Pinia
├── mobile/           # Flutter app
├── docker-compose.yml
├── deploy.sh         # Deploy ke VPS via rsync + SSH
└── .env.production   # Environment production
```

---

## Development (Local)

### Backend

```bash
cd backend
# pastikan .env sudah terisi (copy dari .env.production)
go run main.go
```

Default port: `8080`

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Default port: `5173`

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

> Catatan: Build APK release dilakukan dari lokal, bukan dari server.

---

## Production (Docker)

### Deploy

```bash
# Deploy ke VPS (otomatis rsync + compose up)
./deploy.sh <ip> <user>

# Atau manual di server
docker compose up -d --build
```

### Service

| Service | Port | URL |
|---|---|---|
| Frontend | 80 | `http://<ip>` |
| Backend API | 8080 | `http://<ip>/api` |
| Health Check | 8080 | `http://<ip>/health` |
| PostgreSQL | 5432 | internal |

### Logs

```bash
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db
```

### Restart Service Tertentu

```bash
docker compose restart backend
docker compose restart frontend
docker compose restart db
```

### Update Dependensi + Rebuild

```bash
# Backend (update Go modules)
cd backend
go get -u ./...
go mod tidy
cd ..

# Frontend (update npm packages)
cd frontend
npm update
cd ..

# Rebuild & deploy
docker compose up -d --build
```

---

## Database

### Backup Manual

```bash
docker exec -t ganesha-project-db-1 pg_dump -U postgres ganesha > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore

```bash
docker exec -i ganesha-project-db-1 psql -U postgres ganesha < backup_FILE.sql
```

### Masuk ke DB

```bash
docker exec -it ganesha-project-db-1 psql -U postgres -d ganesha
```

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| **Port 80/8080 sudah dipakai** | Cek `netstat -tulpn` atau ganti port di `docker-compose.yml` |
| **DB connection refused** | Pastikan container `db` sudah healthy: `docker compose ps` |
| **Upload file gagal** | Cek volume `uploads_data`: `docker volume ls` |
| **Frontend blank** | Cek console browser, pastikan `VITE_API_URL` benar di build |
| **JWT error** | Generate ulang `JWT_SECRET` di `.env.production` |
| **Image size membesar** | `docker image prune -a` hapus image tidak terpakai |

---

## Periodic Maintenance

| Frekuensi | Tugas | Command |
|---|---|---|
| Harian | Cek log error | `docker compose logs --tail=50 backend` |
| Mingguan | Backup database | `docker exec ... pg_dump > backup.sql` |
| Bulanan | Update dependensi | `go get -u`, `npm update` |
| Bulanan | Prune Docker | `docker system prune -f` |
| 3 Bulan | Update image base | rebuild ulang `docker compose build --no-cache` |
