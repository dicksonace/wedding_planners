# WedPlan Ghana — Marriage Planning Service System

Mobile-based marriage planning platform for Ghanaian couples (GCTU BSc IT Project).

## Project Structure

```
marriage_planner/
├── backend/     # Laravel 13 + MySQL REST API
├── mobile/      # Flutter mobile app
└── README.md
```

## Features (Phase 1)

- Couple & vendor registration/login (Sanctum API tokens)
- Wedding plan creation with Ghanaian ceremony types (knocking, engagement, traditional, church, court, reception)
- Dashboard with stats (guests, tasks, budget)
- Guest list management & RSVP tracking
- Budget tracking with summaries
- Task scheduling by ceremony type
- Vendor directory & vendor request messaging
- In-app notifications

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile App | Flutter 3.x |
| Backend API | Laravel 13 |
| Database | MySQL (MariaDB via XAMPP) |
| Auth | Laravel Sanctum |

---

## Prerequisites

Install these on your computer before setup:

| Tool | Purpose | Download |
|------|---------|----------|
| **XAMPP** | MySQL database + optional Apache | https://www.apachefriends.org |
| **PHP 8.2+** | Laravel backend | Included with XAMPP, or https://windows.php.net |
| **Composer** | PHP dependencies | https://getcomposer.org |
| **Flutter SDK** | Mobile app | Install via command below or https://docs.flutter.dev/get-started/install |

**Install Flutter with a command (Windows):**

```powershell
# Option A — Chocolatey (run PowerShell as Administrator)
choco install flutter -y

# Option B — winget (Windows 10/11)
winget install Google.Flutter

# Option C — Git (if no package manager)
git clone https://github.com/flutter/flutter.git -b stable C:\dev\flutter
```

After install, **close and reopen** the terminal, then run:

```powershell
flutter --version
flutter doctor
```

If you used **Option C**, add `C:\dev\flutter\bin` to your system **PATH** manually.

| **Git** (optional) | Version control | https://git-scm.com |

Verify installations:

```bash
php -v
composer -V
flutter --version
flutter doctor
```

> **Important:** If you see `bash: flutter: command not found`, Flutter is **not installed** (or not on PATH). The mobile app will **not run** until Flutter is installed. See [Fix: flutter command not found](#fix-flutter-command-not-found) below.

---

## 1. Backend Setup (Laravel + MySQL)

### Step 1 — Start MySQL

1. Open **XAMPP Control Panel**
2. Click **Start** next to **MySQL**
3. (Optional) Start **Apache** if you want to serve Laravel through XAMPP instead of `php artisan serve`

### Step 2 — Create the database

Open phpMyAdmin (`http://localhost/phpmyadmin`) or MySQL command line and run:

```sql
CREATE DATABASE wedplan_ghana CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Step 3 — Configure environment

Go to the backend folder and copy the environment file if needed:

```bash
cd backend
copy .env.example .env    # Windows
# cp .env.example .env    # Mac/Linux
```

Edit `backend/.env` and set your database details (XAMPP defaults):

```env
APP_NAME="WedPlan Ghana"
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=wedplan_ghana
DB_USERNAME=root
DB_PASSWORD=
```

> If your MySQL has a password, set `DB_PASSWORD` accordingly.

### Step 4 — Install dependencies and set up the database

```bash
cd backend
composer install
php artisan key:generate
php artisan migrate:fresh --seed
```

This creates all tables and loads **demo data**. See [After seed — all credentials & demo data](#after-seed--all-credentials--demo-data) below for login details and seeded records.

### Step 5 — Start the API server

```bash
php artisan serve
```

The API will be available at:

```
http://127.0.0.1:8000/api
```

Test it in your browser or terminal:

```bash
# PowerShell
Invoke-RestMethod http://127.0.0.1:8000/api/health

# Or open in browser
http://127.0.0.1:8000/api/health
```

Expected response:

```json
{
  "status": "ok",
  "app": "WedPlan Ghana API",
  "version": "1.0.0"
}
```

Keep this terminal open while using the app.

---

## 2. Mobile App Setup (Flutter)

### Step 1 — Install dependencies

Open a **new terminal** (keep the backend running in the first one):

```bash
cd mobile
flutter pub get
```

### Step 2 — Configure the API URL

The app connects to the backend through `mobile/lib/config/api_config.dart`.

Default URLs by platform:

| Platform | Default API URL |
|----------|-----------------|
| Chrome / Web | `http://127.0.0.1:8000/api` |
| Windows desktop | `http://127.0.0.1:8000/api` |
| Android emulator | `http://10.0.2.2:8000/api` |
| Physical phone (same Wi‑Fi) | `http://YOUR_PC_IP:8000/api` |

If testing on a **physical phone**, replace `YOUR_PC_IP` with your computer's local IP:

```bash
# Windows PowerShell
ipconfig
# Look for "IPv4 Address" under your Wi‑Fi adapter, e.g. 192.168.1.10
```

Then update `mobile/lib/config/api_config.dart`:

```dart
static const String _localIp = '192.168.1.10'; // your PC IP

static String get baseUrl {
  if (kIsWeb) {
    return 'http://$_localIp:8000/api';
  }
  // ...
}
```

When using a phone, start the backend so it accepts network connections:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

---

## 3. Running the Application Locally

Make sure **both** the backend (`php artisan serve`) and the Flutter app are running.

### Option A — Chrome (recommended for Windows)

Easiest way to preview during development:

```bash
cd mobile
flutter run -d chrome
```

Chrome opens automatically with the WedPlan Ghana app.

### Option B — Windows desktop

```bash
cd mobile
flutter run -d windows
```

> Requires Visual Studio Build Tools with **Windows 10 SDK** installed.

### Option C — Android emulator or phone

1. Install **Android Studio**: https://developer.android.com/studio
2. Open Android Studio → **SDK Manager** → install Android SDK
3. Create an emulator: **Device Manager** → **Create Virtual Device**
4. Run:

```bash
cd mobile
flutter devices          # confirm emulator/phone is listed
flutter run              # or: flutter run -d <device-id>
```

For a **physical Android phone**:
- Enable **Developer Options** and **USB Debugging**
- Connect via USB
- Update `api_config.dart` with your PC's IP (see Step 2 above)
- Start backend with `php artisan serve --host=0.0.0.0 --port=8000`

### Option D — iPhone (via Safari browser on Windows)

You **cannot** build a native iOS app on Windows (requires Mac + Xcode).  
You **can** preview the app in **Safari on your iPhone** using the web version:

1. Connect iPhone and PC to the **same Wi‑Fi network**
2. Find your PC IP (`ipconfig` → e.g. `192.168.1.10`)
3. Update `api_config.dart` to use that IP
4. Start backend for network access:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

5. Start Flutter web server:

```bash
cd mobile
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

6. On iPhone **Safari**, open:

```
http://YOUR_PC_IP:8080
```

Example: `http://192.168.1.10:8080`

> Allow through Windows Firewall if prompted.

### Option E — Native iPhone app (Mac only)

Requires a **Mac** with **Xcode** installed:

```bash
cd mobile
flutter run    # with iPhone connected via USB
```

---

## After seed — all credentials & demo data

Run this once to load demo data:

```bash
cd backend
php artisan migrate:fresh --seed
```

### Database (XAMPP defaults)

| Setting | Value |
|---------|-------|
| Host | `127.0.0.1` |
| Port | `3306` |
| Database | `wedplan_ghana` |
| Username | `root` |
| Password | *(empty)* |

### App login accounts

| Role | Email | Password | What you see after login |
|------|-------|----------|--------------------------|
| **Couple** | `couple@wedplan.test` | `password` | Dashboard, Guests, Budget, Tasks, Vendors |
| **Vendor** | `vendor@wedplan.test` | `password` | Vendor Portal (requests, accept/decline) |

### API endpoints (local)

| Service | URL |
|---------|-----|
| API base | `http://127.0.0.1:8000/api` |
| Health check | `http://127.0.0.1:8000/api/health` |
| Guest RSVP page | `http://127.0.0.1:8000/rsvp/{token}` |

### Seeded couple profile

| Field | Value |
|-------|-------|
| Name | Ernestina & Partner |
| Email | `couple@wedplan.test` |
| Phone | 0244123456 |
| Partner | Kwame Mensah |
| Region | Greater Accra |

### Seeded wedding plan

| Field | Value |
|-------|-------|
| Title | Our Accra Wedding 2026 |
| Bride | Ernestina Blankson |
| Groom | Kwame Mensah |
| Date | 2026-08-15 |
| Venue | Accra Conference Centre |
| Total budget | GHS 50,000 |
| Ceremonies | knocking, engagement, traditional, church, reception |

### Seeded guests

| Name | Phone | Side | RSVP |
|------|-------|------|------|
| Akosua Panford | 0244000111 | bride | confirmed |
| Yaw Appiah | 0244000222 | groom | pending |

### Seeded budget items

| Category | Description | Planned | Actual | Paid |
|----------|-------------|---------|--------|------|
| Venue | Venue booking deposit | GHS 12,000 | GHS 5,000 | Yes |
| Photography | Photography package | GHS 6,000 | GHS 0 | No |

### Seeded vendor profile

| Field | Value |
|-------|-------|
| Business | Golden Events Ghana |
| Login email | `vendor@wedplan.test` |
| Category | Decoration |
| Location | Accra |
| Phone | 0209876543 |
| Service | Full Venue Decoration (GHS 8,000 – 25,000) |

### Seeded vendor request (pending)

The couple has already sent a **pending** decoration request to Golden Events Ghana. Log in as `vendor@wedplan.test` to accept or decline it.

### Email invitations (guest RSVP)

- Default mail driver: `log` (emails saved to `backend/storage/logs/laravel.log`, not sent externally).
- To send real emails, configure SMTP in `backend/.env`:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your_username
MAIL_PASSWORD=your_password
MAIL_FROM_ADDRESS=hello@wedplan.test
MAIL_FROM_NAME="WedPlan Ghana"
```

- Guest invite emails include **Accept** and **Decline** links that update RSVP on the web page.

---

## Demo Login Accounts (quick reference)

| Role | Email | Password |
|------|-------|----------|
| Couple | `couple@wedplan.test` | `password` |
| Vendor | `vendor@wedplan.test` | `password` |

---

## Quick Start (Full Local Run)

Use **two terminals**. Run commands **in this order**:

**Terminal 1 — Backend (Laravel):**
```bash
cd C:/xampp/htdocs/marriage_planner/backend
composer install
php artisan migrate:fresh --seed
php artisan serve
```

**Terminal 2 — Mobile (Flutter):**

First check Flutter is installed:
```bash
flutter --version
```

If that works, run:
```bash
cd C:/xampp/htdocs/marriage_planner/mobile
flutter pub get
flutter run -d chrome
```

Login with `couple@wedplan.test` / `password` and explore Dashboard, Guests, Budget, Tasks, and Vendors.

> Use **PowerShell** or **Command Prompt** for Flutter on Windows. Git Bash often does not see Flutter if PATH was set only for Windows.

---

## Troubleshooting

### Fix: `flutter: command not found`

This means **Flutter SDK is not installed** on that PC (or the terminal cannot see it).

**Step 1 — Install Flutter (one time only)**

1. Download Flutter for Windows: https://docs.flutter.dev/get-started/install/windows
2. Extract the zip to a folder, e.g. `C:\dev\flutter` (do **not** put it in `C:\Program Files`)
3. Add Flutter to PATH:
   - Press `Win + S` → search **Environment Variables**
   - Edit **Path** under User variables → **New** → add: `C:\dev\flutter\bin`
   - Click OK on all windows
4. **Close and reopen** the terminal (or restart VS Code)

**Step 2 — Verify Flutter works**

Open **PowerShell** (recommended, not Git Bash) and run:

```powershell
flutter --version
flutter doctor
```

**Step 3 — Run the mobile app**

Make sure the **backend is already running** in another terminal (`php artisan serve`), then:

```powershell
cd C:\xampp\htdocs\marriage_planner\mobile
flutter pub get
flutter run -d chrome
```

**If Git Bash still says command not found** but PowerShell works, use PowerShell for Flutter commands, or add this to Git Bash temporarily:

```bash
export PATH="$PATH:/c/dev/flutter/bin"
flutter --version
```

(Change `/c/dev/flutter/bin` to match where Flutter was extracted.)

---

### MySQL connection failed
- Ensure **MySQL is running** in XAMPP
- Confirm database `wedplan_ghana` exists
- Check `DB_USERNAME` and `DB_PASSWORD` in `backend/.env`

### `flutter` command not found
- Add Flutter to your PATH: `C:\dev\flutter\bin` (or your install path)
- Restart the terminal after installing Flutter

### App shows login error / cannot connect to API
- Confirm backend is running: open `http://127.0.0.1:8000/api/health`
- Check `mobile/lib/config/api_config.dart` matches your setup
- On phone/emulator, use PC IP — not `127.0.0.1`

### Budget screen error (type String vs num)
- Pull latest code — amounts are parsed safely in the app
- Restart Flutter with hot restart: press **`R`** in the Flutter terminal

### Android SDK not found
- Install Android Studio and SDK via SDK Manager
- Set `ANDROID_HOME` to your SDK path (e.g. `C:\Users\YourName\AppData\Local\Android\Sdk`)

### iPhone not detected by Flutter
- Native iOS builds require **macOS + Xcode**
- Use **Option D** (Safari web preview) on Windows instead

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | API health check |
| POST | `/api/register` | Register couple or vendor |
| POST | `/api/login` | Login |
| POST | `/api/logout` | Logout (auth required) |
| GET | `/api/profile` | Current user profile |
| GET | `/api/dashboard` | Dashboard summary |
| CRUD | `/api/wedding-plans` | Wedding plans |
| CRUD | `/api/wedding-plans/{id}/guests` | Guest management |
| CRUD | `/api/wedding-plans/{id}/budget-items` | Budget items |
| CRUD | `/api/wedding-plans/{id}/tasks` | Planning tasks |
| GET | `/api/vendors` | Browse vendors |
| POST | `/api/wedding-plans/{id}/vendor-requests` | Request vendor |

---

## Team

- Ernestina Blankson (4211231092)
- Nadia Comfort Panford (4211231413)
- Pamela Akosua Konadu Appiah (4211230015)

**Supervisor:** Dr. Fred Amankwah-Sarfo  
**Institution:** Ghana Communication Technology University (GCTU)  
**Department:** Information Technology
