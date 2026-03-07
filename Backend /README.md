# SmartEd - School Management API

A modern, secure, role-based RESTful API for school management built with PHP 8.1+.

## Features

- Multi-school support (Superadmin manages multiple schools)
- Role-based access: `superadmin` → `admin` → `teacher` → `student`
- Classes, subjects, enrollments, results & report cards
- JWT authentication
- Secure file uploads (profile photos, school logos)
- Clean MVC-like architecture with PSR-4 autoloading

## Roles & Permissions

| Role        | Permissions |
|-------------|-------------|
| superadmin  | Manage all schools, view everything |
| admin       | Manage own school: classes, subjects, teachers, students |
| teacher     | View assigned classes, enter results |
| student     | View own results and report card |

## Quick Start

1. Clone the project
2. Run:
   ```bash
   composer install
   cp .env.example .envs
