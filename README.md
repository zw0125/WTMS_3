# 🛠️ Worker Task Management System (WTMS)

WTMS is a Flutter-based mobile application designed for workers to register, log in, view assigned tasks, submit work reports, and manage their profiles. It features an intuitive UI, smooth navigation, and secure communication with a PHP-MySQL backend API.

## 📱 Features

### 🔐 Authentication
- Worker registration and login
- SHA1 password hashing for security
- Session persistence using SharedPreferences

### ✅ Task Management
- View list of tasks assigned to the logged-in worker
- Submit completion reports with descriptions
- Tasks include title, description, due date, and status

### 🕘 Submission History
- View past work submissions
- Edit existing reports with confirmation

### 👤 Profile Management
- View and update personal information (name, email, phone, etc.)
- Email remains non-editable

### 🔄 Seamless Navigation
- BottomNavigationBar with 3 main tabs:
  - Tasks
  - History
  - Profile

## 📦 Backend API (PHP + MySQL)

### 📁 Main Endpoints:
- `register_worker.php` – Register new workers
- `login_worker.php` – Authenticate login
- `get_works.php` – Fetch assigned tasks for worker
- `submit_work.php` – Submit completion report
- `get_submissions.php` – Retrieve submission history
- `edit_submission.php` – Update a past submission
- `update_profile.php` – Update worker profile details

### 🗄️ Database Tables:
- `workers` – Stores worker details
- `tbl_works` – Stores tasks assigned to workers
- `tbl_submissions` – Stores worker submission reports

### 🧑‍💻 Author
- Ng Zi Wei
- STIWK2114 Mobile Programming Assignment
- Submission Date: 20 June 2025
