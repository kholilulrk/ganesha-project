# Fitur Lupa Password / Username — via SMTP + OTP

## Ringkasan
User lupa password → input email → terima kode OTP 6 digit di email → verifikasi OTP → ganti password.

---

## Yang Perlu Disiapkan

### 1. SMTP Credentials
Ambil App Password Gmail:
2. Aktifkan **2-Step Verification** di akun Gmail
3. Buka https://myaccount.google.com/apppasswords
4. Pilih **Other** → ketik "Ganesha" → **Generate**
5. Copy password 16 huruf

### 2. Tambah `.env` (backend)
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_EMAIL=emailkamu@gmail.com
SMTP_PASSWORD=xxxx xxxx xxxx xxxx
```

---

## Perubahan Backend

### `backend/config/config.go`
- Tambah field: `SMTPHost`, `SMTPPort`, `SMTPEmail`, `SMTPPassword`
- Load dari env

### `backend/models/user.go`
- Tambah field:
  - `Email string json:"email"`
  - `ResetToken string json:"-"`
  - `ResetTokenExpiry time.Time json:"-"`

### `backend/models/setup.go`
- Hapus baris: `db.Exec("DROP INDEX uni_users_email ON users")` dan `db.Exec("ALTER TABLE users DROP COLUMN email")`
- Hapus semua referensi DROP email

### `backend/services/mailer.go` (baru)
- Fungsi `SendOTP(to, code string)`
- Konek SMTP via `net/smtp` (stdlib, tanpa library tambahan)
- Template email: "Kode OTP kamu: XXXXXX, berlaku 5 menit."

### `backend/controllers/auth_controller.go`
- `POST /api/auth/forgot-password`: cari user by email → generate random 6 digit → simpan `ResetToken` + expiry (5 menit) → kirim email via SMTP
- `POST /api/auth/reset-password`: validasi email + kode OTP + password baru → hash password baru → update

### `backend/routes/routes.go`
- Tambah 2 route tanpa middleware auth: `POST /api/auth/forgot-password` dan `POST /api/auth/reset-password`

---

## Perubahan Mobile

### `lib/screens/login_screen.dart`
- Tambah link `TextButton` "Lupa Password?" di bawah tombol login
- Navigasi ke `ForgotPasswordScreen`

### `lib/screens/forgot_password_screen.dart` (baru)
- Input email
- Tombol "Kirim Kode OTP"
- Hitung mundur 60 detik sebelum kirim ulang
- Navigasi ke `ResetPasswordScreen` setelah sukses

### `lib/screens/reset_password_screen.dart` (baru)
- Input email (read-only, dari parameter)
- Input kode OTP 6 digit (dipisah per kotak atau single input)
- Input password baru + konfirmasi
- Tombol "Reset Password"
- Navigasi ke halaman login setelah sukses

---

## Catatan
- OTP berlaku **5 menit**
- Setiap kirim ulang OTP, token lama dihapus dan generate baru
- Setelah reset sukses, OTP dihapus dari database
- Email user ditambahkan via halaman **Edit User** di Pengguna (Super Admin/Administrasi)
- Tidak perlu instalasi software tambahan di VPS/server
