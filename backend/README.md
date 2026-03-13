# Hantario API

A Node.js Express API with MongoDB, PostgreSQL (with PostGIS), Redis, Sequelize ORM, and BullMQ for job queuing.

## Features

- **Node.js Express**: Web framework for building the API
- **MongoDB**: NoSQL database for flexible data storage
- **PostgreSQL with PostGIS**: Relational database with geospatial capabilities
- **Redis**: In-memory data structure store for caching
- **Sequelize**: Promise-based Node.js ORM for PostgreSQL
- **BullMQ**: Fast and reliable queue system for background jobs

## Prerequisites

- Docker and Docker Compose installed on your system

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd hantario-api
   ```

2. Start the services using Docker Compose:
   ```bash
   docker-compose up --build
   ```

3. The API will be available at `http://localhost:3000`

## API Endpoints

### General
- `GET /`: Welcome message
- `GET /health`: Health check for all services

### Users
- `GET /api/users`: Get all users with pagination, filtering, sorting, and location-based search
- `GET /api/users/:id`: Get single user by ID
- `POST /api/users`: Create new user
- `PUT /api/users/:id`: Update user (authenticated)
- `DELETE /api/users/:id`: Delete user (authenticated)

#### Users Query Parameters
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)
- `search`: Search in name, email, and city fields
- `city`: Filter by city
- `looking_for`: Filter by looking_for (buy, sale, rent, monitor_my_property, just_look_around)
- `lat`, `lng`, `radius`: Location-based search (radius in km)
- `sortBy`: Sort field (id, name, email, city, createdAt, updatedAt, available_balance)
- `sortOrder`: Sort order (ASC, DESC)

#### Users Request Body (Create)
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "securepassword",
  "city": "Mogadishu",
  "lat": 2.0469,
  "lng": 45.3182,
  "looking_for": "buy",
  "profile_picture_url": "https://example.com/profile.jpg",
  "pending_balance": 0.00,
  "available_balance": 100.00,
  "looking_for_set": false,
  "category_set": false
}
```

#### Users Request Body (Update)
```json
{
  "name": "John Doe Updated",
  "city": "Hargeisa",
  "lat": 9.5624,
  "lng": 44.0770,
  "looking_for": "rent",
  "available_balance": 150.00
}
```

### State Categories
- `GET /api/state-categories`: Get all state categories with pagination, filtering, and sorting
- `GET /api/state-categories/:id`: Get single state category by ID
- `POST /api/state-categories`: Create new state category
- `PUT /api/state-categories/:id`: Update state category
- `DELETE /api/state-categories/:id`: Delete state category

#### State Categories Query Parameters
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)
- `search`: Search in name_en and name_so fields
- `sortBy`: Sort field (id, name_en, name_so, createdAt, updatedAt)
- `sortOrder`: Sort order (ASC, DESC)

#### State Categories Request Body
```json
{
  "name_en": "Category Name (English)",
  "name_so": "Magaca Qaybta (Somali)",
  "thumb_url": "https://example.com/thumbnail.jpg"
}
```

## Environment Variables

Configure the following environment variables in `.env`:

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (development/production)
- `MONGO_URI`: MongoDB connection string
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`: PostgreSQL configuration
- `REDIS_HOST`, `REDIS_PORT`: Redis configuration
- `JWT_SECRET`: Secret key for JWT tokens
- `FIREBASE_SERVICE_ACCOUNT_PATH`: Absolute path to Firebase Admin service-account JSON file (preferred)
- `FIREBASE_SERVICE_ACCOUNT_JSON`: Raw JSON content of Firebase Admin service-account (alternative to path)

### Firebase Push Notifications

Push delivery is triggered automatically whenever a notification is created via the API:
- in-app notification is saved to `notifications` table,
- FCM push is sent to all registered tokens in `user_devices` for that user,
- invalid/unregistered tokens are automatically removed from `user_devices`.

To enable push:
1. Add `FIREBASE_SERVICE_ACCOUNT_PATH` (or `FIREBASE_SERVICE_ACCOUNT_JSON`) to `.env`.
2. Register app tokens using `POST /api/user-devices`.
3. Create notifications using `POST /api/notifications` with `user_id`, `title`, `message`, and `type`.

Security:
- Never commit service-account JSON files.
- If a key is shared accidentally, rotate/revoke it immediately in Google Cloud IAM.

## Development

For development with hot reloading:

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

## Figma Sample Data Seed

Populate backend databases with sample data aligned to the current Figma-driven app flows:

```bash
cd backend
npm run db:seed:figma-sample
```

Validate the seeded data quickly:

```bash
cd backend
npm run db:verify:figma-sample
```

The script inserts or updates sample records for:
- users (agents + clients),
- locations,
- listings (featured/search/nearby style items),
- favourites,
- listing reviews,
- notifications,
- recent searches,
- rental and buying transactions,
- FAQs,
- and Mongo chat conversation/messages (when `MONGO_URI` is configured).

## Project Structure

```
hantario-api/
├── docker-compose.yml
├── Dockerfile
├── package.json
├── .env
├── README.md
└── src/
    ├── app.js
    ├── models/
    │   ├── index.js
    │   ├── User.js
    │   ├── Location.js
    │   └── StateCategory.js
    ├── routes/
    │   ├── index.js
    │   ├── users.js
    │   └── stateCategories.js
    ├── queues/
    │   └── index.js
    ├── middleware/
    │   └── auth.js
    └── config/
        └── database.js
```

## Services

- **app**: Node.js Express application
- **mongo**: MongoDB database
- **postgres**: PostgreSQL with PostGIS extension
- **redis**: Redis cache

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the ISC License.
