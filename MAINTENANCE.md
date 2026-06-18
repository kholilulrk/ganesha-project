# Panduan Update Aplikasi & Backend

## Update APK (Fitur Perbarui Aplikasi dari HP)

Setiap ada perubahan di mobile (Flutter), lakukan langkah berikut agar user bisa update langsung dari HP.

### 1. Naikkan versi di pubspec.yaml

Buka `mobile/pubspec.yaml`, ubah `version:`:

```yaml
version: 1.0.0+1    # → ganti jadi 1.1.0+1 (atau sesuai kebutuhan)
```

> Angka sebelum `+` adalah versi yang ditampilkan ke user.
> Angka setelah `+` (build number) naikkan 1 setiap build.

### 2. Build APK di lokal (Windows)

```powershell
cd mobile
flutter build apk --release
```

Hasil: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### 3. Upload APK ke server

```powershell
scp F:\Website\mobile\ganesha-mobile\build\app\outputs\flutter-apk\app-release.apk rzl@203.194.115.28:/home/deploy/apps/ganesha-project/apk/app-release.apk
```

### 4. Update versi di .env.production

SSH ke server, lalu:

```bash
cd /home/deploy/apps/ganesha-project

# Isi versi SAMA dengan yang di pubspec.yaml (angka sebelum +)
# Contoh: pubspec.yaml version: 1.1.0+1 → maka 1.1.0
sed -i 's/APP_LATEST_VERSION=.*/APP_LATEST_VERSION=1.1.0/' .env.production
```

> URL download tidak perlu diubah, sudah tetap (`app-release.apk`).
> APK baru cukup ditimpa di folder yang sama.

### 5. Restart container backend

```bash
docker compose restart backend
```

> **Kenapa hanya backend?** Frontend container hanya serving file statis — APK yang diupload langsung terbaca tanpa restart karena di-mount sebagai volume.

### 6. User update dari HP

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

1. Naikkan versi di `pubspec.yaml`
2. Build APK di lokal
3. Upload APK ke server
4. SSH ke server, update `APP_LATEST_VERSION` di `.env.production`
5. Git pull + rebuild container:

```bash
cd /home/deploy/apps/ganesha-project
git pull origin main
docker compose up -d --build
```

6. Selesai — user bisa update dari HP

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
URL akses publik: `https://ganesha-energy.my.id/apk/app-release.apk`
Tidak perlu install Nginx terpisah di server.
