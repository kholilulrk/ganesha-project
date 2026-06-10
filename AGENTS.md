# Gap Analysis: Web → Mobile Flutter

## ✅ Already in Mobile

| Fitur | Status |
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

## ❌ Belum Ada di Mobile

1. **To-Do List** — Halaman todo dengan assignee, filter All/Pending/Done, toggle selesai.
2. **Monitoring Aktif Surat** — CRUD SIK/SC, perhitungan kadaluarsa, warna baris. 🔜 Kerjakan nanti.
3. **Kelengkapan Dokumen** — 6 jenis dokumen per job, verifikasi 4 step, progress 14 tahap. 🔜 Kerjakan nanti.
4. **Pengguna (User Management)** — CRUD user oleh Super Admin.
5. **Atur Akses (Permissions)** — Granular permission per role per resource.
6. **Job CRUD (Create/Edit/Delete)** — Buat, edit, hapus pekerjaan via modal. 🔜 Kerjakan nanti.
7. **Document Management (Dokumen)** — Halaman dokumen dengan tipe badge, download, share.
8. **Selesaikan Pekerjaan** — Tombol complete saat semua checklist selesai.
9. **Quick Create Job dari Dashboard** — Modal langsung dari dashboard.
10. **Expiring Letters Warning** — Dashboard tampilkan surat kadaluarsa ≤7 hari.
11. **Recent Pending Jobs** — Dashboard tampilkan daftar recent pending.
12. **Share Link Generation** — Generate + copy link share.
13. **Filter Lanjutan Pekerjaan** — Filter by status + share role.
14. **SPEKTEK PDF Reference** — Attach PDF referensi saat create/edit job.
15. **Collapsible Sidebar** — Sidebar bisa collapse ke ikon saja. 🔜 Kerjakan nanti.

## ✅ Push Notification (New — Code selesai, butuh Firebase project)
- Backend: `models/notification.go`, `services/fcm.go`, `controllers/notification_controller.go`, routes untuk register/unregister token, get/mark-notifications
- Notifikasi dikirim saat: job baru dibuat (SendPushToAllUsers), checklist item baru (ke role terkait), dokumen baru diupload (SendPushToAllUsers)
- Mobile: `notification_service.dart` (FCM init + token register), `notification_api_service.dart`, `notification_model.dart`, `notification_screen.dart`
- `main_shell.dart`: tambah tab Notif dengan badge count
- `main.dart`: Firebase init, `pubspec.yaml`: firebase_core + firebase_messaging
- Android config: `settings.gradle.kts` + `app/build.gradle.kts` + placeholder `google-services.json`
- **Bloked**: butuh Firebase project (google-services.json asli + FCM_SERVER_KEY) untuk build release dan push nyata
