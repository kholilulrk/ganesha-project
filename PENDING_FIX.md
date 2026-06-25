# PENDING FIX — 24 Juni 2026

## Masalah
Aplikasi mobile/web error `broken pipe` — koneksi terputus.

## Root Cause
Nameserver domain `ganesha-energy.my.id` balik ke **Rumahweb** (`nsid1.rumahweb.com`), bukan **Cloudflare** (`karsyn.ns.cloudflare.com`, `lewis.ns.cloudflare.com`). DNS tidak sampai ke Cloudflare → tunnel tidak bisa routing traffic dari luar.

## Fix yang harus dilakukan (besok)

### 1. Ganti Nameserver di Panel Rumahweb
- Login ke https://member.rumahweb.com/
- Domain → Manage Nameservers
- Ubah ke:
  ```
  karsyn.ns.cloudflare.com
  lewis.ns.cloudflare.com
  ```
- Tunggu propagasi 1-24 jam

### 2. Test setelah propagasi
```bash
dig ganesha-energy.my.id A @8.8.8.8 +short
# Harusnya keluar IP Cloudflare (104.x.x.x), bukan 203.194.115.28
```

### 3. Deploy code fix FCM Token
```bash
cd /home/deploy/apps/ganesha-project
git pull
docker compose down && docker compose up -d --build
```

## Status sekarang
- [x] Cloudflared dipaksa pakai HTTP/2 (--protocol http2)
- [x] FCM token duplicate key error di-notification_controller.go sudah di-fix (tinggal push)
- [ ] Nameserver domain masih Rumahweb — **HARUS DIUBAH**
- [ ] Tunnel tidak bisa akses dari luar sampai nameserver fix
