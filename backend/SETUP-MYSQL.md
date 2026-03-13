# MySQL Setup Guide

This app is configured to use **MySQL** as the primary database (instead of PostgreSQL).

## Prerequisites

1. **MySQL Server** installed and running on your PC (default port 3306)
2. **Redis** (optional for caching/queues - the app may fail to start without it)
3. **MongoDB** (optional for chat - the app may fail to start without it)

## Configuration

1. Copy `.env.example` to `.env` if you haven't already
2. Update these values in `.env`:

```
DB_DIALECT=mysql
DB_HOST=localhost
DB_PORT=3306
DB_NAME=rental_db
DB_USER=root
DB_PASSWORD=your_mysql_password
```

## Setup Steps

1. **Create the database** (the setup script does this automatically):

   ```bash
   npm run db:setup
   ```

   Or manually in MySQL:
   ```sql
   CREATE DATABASE rental_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. **Start the server**:

   ```bash
   npm run dev
   ```

## Troubleshooting

### Native module errors (bcrypt, sqlite3)

If you see errors like `"is not a valid Win32 application"`, rebuild native modules:

```bash
npm rebuild
# or
npm install
```

### Redis / MongoDB not running

When running locally without Docker:
- Set `REDIS_HOST=localhost` and `MONGO_URI=mongodb://localhost:27017/rental_db` in `.env`
- Ensure Redis and MongoDB are installed and running locally

### Switch back to PostgreSQL

Set in `.env`:
```
DB_DIALECT=postgres
DB_HOST=localhost
DB_PORT=5432
```

Install `pg` and `pg-hstore` if not present:
```bash
npm install pg pg-hstore
```
