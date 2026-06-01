# Dokumentasi Ganesha Project

## Informasi Aplikasi

| Item | Detail |
|------|--------|
| Nama | Ganesha Project |
| Framework | Laravel 12 |
| Database | PostgreSQL |
| Domain/IP | http://203.194.115.28:8081 |
| Server | VPS (Linux Ubuntu) |
| Direktori | `/var/www/ganesha` |

## Akun Login

| Role | Email | Password |
|------|-------|----------|
| Super Admin | `superadmin@ganesha.test` | `password` |

Seeder ada di `database/seeders/RolePermissionSeeder.php`. Jalankan:

```bash
php artisan db:seed --force
```

## Deployment ke VPS

### Requirements

- PHP 8.2+
- Composer
- PostgreSQL
- Nginx
- Node.js & npm
- Supervisor (untuk queue worker)

### Langkah Deployment

```bash
# 1. Clone / Upload project
cd /var/www
git clone <repo-url> ganesha

# 2. Setup environment
cd ganesha
cp .env.example .env
nano .env   # sesuaikan DB_PASSWORD, APP_URL, dll

# 3. Install dependencies
composer install --no-dev --optimize-autoloader

# 4. Generate key
php artisan key:generate

# 5. Storage link
php artisan storage:link

# 6. Build frontend
npm install
npm run build

# 7. Migrate & seed database
php artisan migrate --force
php artisan db:seed --force

# 8. Cache
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 9. Permission
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# 10. Nginx config
ln -sf /etc/nginx/sites-available/ganesha /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

### Nginx Config (`/etc/nginx/sites-available/ganesha`)

```nginx
server {
    listen 8081;
    server_name 203.194.115.28;
    root /var/www/ganesha/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

### Supervisor Queue Worker (`/etc/supervisor/conf.d/ganesha-queue.conf`)

```ini
[program:ganesha-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/ganesha/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/ganesha/storage/logs/queue.log
```

```bash
supervisorctl reread && supervisorctl update && supervisorctl start all
```

## Migrasi Database (MySQL -> PostgreSQL)

### Perubahan yang dilakukan:

1. **`.env.example`** - default connection dari `mysql` ke `pgsql`
2. **5 migration files** - `enum()` diganti `string()` karena PostgreSQL tidak mendukung enum Laravel:
   - `2026_05_12_072054_create_tasks_table.php`
   - `2026_05_12_072846_create_work_reports_table.php`
   - `2026_05_13_100000_create_todo_items_table.php`
   - `2026_05_22_000001_create_letter_active_periods_table.php`
   - `2026_05_29_000002_add_status_to_teknisi_task_items_table.php`

### Catatan:
- `->after('column')` di migration tidak berfungsi di PostgreSQL (diabaikan)
- Config PostgreSQL sudah tersedia di `config/database.php`
- Testing tetap pakai SQLite in-memory (`phpunit.xml`)

## Perintah Berguna

```bash
# Melihat log
tail -f storage/logs/laravel.log
tail -f /var/log/nginx/error.log

# Restart queue
supervisorctl restart ganesha-queue:*

# Mantenance mode
php artisan down
php artisan up

# Clear cache
php artisan optimize:clear

# Backup database
pg_dump -U postgres ganesha > backup_$(date +%Y%m%d).sql
```
