# Cara Update Aplikasi dari HP

## Update APK Baru

Setiap ada perubahan di mobile (Flutter), lakukan langkah berikut:

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

### 3. Set versi terbaru di backend

SSH ke server, lalu:

```bash
# Masuk ke direktori project (sesuai struktur deploy)
cd /home/deploy/apps/ganesha-project

# Update versi (ganti sesuai versi baru)
sed -i 's/APP_LATEST_VERSION=.*/APP_LATEST_VERSION=1.1.0/' .env.production
sed -i 's|APP_DOWNLOAD_URL=.*|APP_DOWNLOAD_URL=http://203.194.115.28/apk/app-release.apk|' .env.production

# Restart ulang container agar backend baca env baru
# (volume mount ./apk juga langsung kebaca tanpa restart)
docker compose restart backend
```

> File `.env.production` minimal:
> ```
> APP_LATEST_VERSION=1.1.0
> APP_DOWNLOAD_URL=http://203.194.115.28/apk/app-release.apk
> ```
>
> **Catatan:** APK diserve langsung oleh Docker Nginx (frontend container).
> APK diletakkan di folder `apk/` selevel dengan `docker-compose.yml`.
> Tidak perlu install Nginx terpisah atau config system Nginx.

### 4. User update dari HP

1. Buka menu **Pengaturan** di aplikasi
2. Lihat section **Aplikasi** → akan muncul badge **"Update Tersedia"**
3. Tap tombol **Perbarui Aplikasi**
4. APK akan terdownload dan install secara otomatis

---

## Update Backend (tanpa update APK)

Backend cukup di-deploy ulang tanpa perlu tindakan dari user:

```bash
cd /home/deploy/apps/ganesha-project/backend
git pull origin main
go build -o ganesha-backend .
sudo systemctl restart ganesha-backend
```

---

## Struktur Folder APK di Server

```
/home/deploy/apps/ganesha-project/
  ├── apk/
  │   └── app-release.apk    <-- APK disini, di-mount ke frontend container
  ├── docker-compose.yml
  ├── frontend/
  │   └── nginx.conf         <-- sudah ada location /apk/
  └── ...
```

Folder `apk/` di-mount ke frontend container (`docker-compose.yml`) dan diserve oleh Nginx internal Docker agar bisa diakses publik lewat `http://203.194.115.28/apk/app-release.apk` (digunakan untuk download dari HP).
