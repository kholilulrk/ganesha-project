# Status Fitur Mobile Android

Semua fitur sudah diimplementasi di mobile. Tidak ada gap dengan web.

## ✅ Selesai

| Fitur | Keterangan |
|---|---|
| Login/Register | ✅ |
| Dashboard stat cards | ✅ |
| Data Pekerjaan (list + detail) | ✅ |
| Checklist Teknisi (CRUD, progress, image upload) | ✅ |
| Checklist Logistic (CRUD, qty/price, image upload) | ✅ |
| Komentar (threaded, replies) | ✅ |
| Upload Dokumen ke job | ✅ |
| Halaman Shared (public, no auth) | ✅ |
| Profil + foto | ✅ |
| WhatsApp contact buttons | ✅ |
| Dark/Light mode | ✅ |
| Role-based navigation | ✅ |
| To-Do List (assignee, filter, toggle) | ✅ |
| Monitoring Aktif Surat (CRUD SIK/SC, expiring) | ✅ |
| Kelengkapan Dokumen (6 jenis, 4 step, 14 tahap) | ✅ |
| Pengguna (User Management) | ✅ |
| Atur Akses (Permissions) | ✅ |
| Job CRUD (Create/Edit/Delete) | ✅ |
| Document Management (tipe badge, download, share) | ✅ |
| Selesaikan Pekerjaan | ✅ |
| Quick Create Job dari Dashboard | ✅ |
| Expiring Letters Warning di Dashboard | ✅ |
| Recent Pending Jobs di Dashboard | ✅ |
| Share Link Generation | ✅ |
| Filter Lanjutan Pekerjaan (status + role) | ✅ |
| SPEKTEK PDF Reference | ✅ |
| App Icon + Splash Screen (branded) | ✅ |

## ⏳ Push Notification (kode siap, butuh Firebase config)

- **Mobile**: `notification_service.dart` (FCM init, token register, local notif)
- **Mobile**: `notification_screen.dart` (list notif, badge count)
- **Backend**: `services/fcm.go` (FCM v1 API via OAuth2 JWT)
- **Backend**: `controllers/notification_controller.go` (register, list, mark read)
- **Backend**: Routes `/fcm/*` dan `/notifications/*` sudah terdaftar

**To do untuk enable push notification:**
1. Download Firebase Service Account JSON dari Firebase Console
2. Simpan di server, set `FCM_SERVICE_ACCOUNT_PATH` di `.env.production`
3. Build APK release (debug FCM mungkin terbatas)
