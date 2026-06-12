# Panduan Update Aplikasi & Backend

## Update APK (Fitur Perbarui Aplikasi dari HP)

Setiap ada perubahan di mobile (Flutter), lakukan langkah berikut agar user bisa update langsung dari HP.

### 1. Build APK di lokal (Windows)

```powershell
cd mobile
flutter build apk --release
```

Hasil: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### 2. Upload APK ke server

```powershell
scp mobile\build\app\outputs\flutter-apk\app-release.apk deploy@203.194.115.28:/home/deploy/apps/ganesha-project/apk/app-release.apk
```

### 3. Update versi di .env.production

SSH ke server, lalu:

```bash
cd /home/deploy/apps/ganesha-project

# Update versi (ganti 1.1.0 sesuai versi baru)
sed -i 's/APP_LATEST_VERSION=.*/APP_LATEST_VERSION=1.1.0/' .env.production
```

> URL download tidak perlu diubah, sudah tetap (`app-release.apk`).
> APK baru cukup ditimpa di folder yang sama.

### 4. Restart container backend

```bash
docker compose restart backend
```

> **Kenapa hanya backend?** Frontend container hanya serving file statis — APK yang diupload langsung terbaca tanpa restart karena di-mount sebagai volume.

### 5. User update dari HP

1. Buka menu **Pengaturan** di aplikasi
2. Lihat section **Aplikasi** → muncul badge **"Update Tersedia"**
3. Tap tombol **Perbarui Aplikasi**
4. APK download otomatis, install setelah selesai

> Jika tidak muncul badge, tarik refresh (swipe down) di halaman Pengaturan.

---

## Update Backend / Frontend (kode Go / React)

Untuk deploy perubahan backend atau frontend tanpa update APK:

```bash
cd /home/deploy/apps/ganesha-project

# 1. Pull kode terbaru
git pull origin main

# 2. Rebuild & restart semua container
docker compose up -d --build
```

> `--build` memaksa Docker rebuild image jika ada perubahan Dockerfile atau source code.
> Tidak perlu `docker compose down` — `up -d --build` akan restart container dengan image baru.

---

## Update Semua (APK + Backend + Frontend)

1. Build APK di lokal (langkah 1)
2. Upload APK ke server (langkah 2)
3. SSH ke server, update `.env.production` (langkah 3)
4. Git pull + rebuild container:

```bash
cd /home/deploy/apps/ganesha-project
git pull origin main
docker compose up -d --build
```

5. Selesai — user bisa update dari HP

---

## Struktur Folder di Server

```
/home/deploy/apps/ganesha-project/
  ├── apk/
  │   └── app-release.apk        <-- APK di-mount ke frontend container
  ├── docker-compose.yml
  ├── .env.production             <-- konfigurasi versi & env
  ├── frontend/
  │   ├── nginx.conf              <-- ada location /apk/
  │   └── Dockerfile
  ├── backend/
  │   ├── Dockerfile
  │   └── ...
  └── ...
```

APK diserve oleh Nginx di dalam frontend container (Docker) via `location /apk/`.
URL akses publik: `http://203.194.115.28/apk/app-release.apk`
Tidak perlu install Nginx terpisah di server.
