# Hantario API Documentation

## Overview

Hantario API is a comprehensive real estate platform built with Node.js, Express, MongoDB, PostgreSQL, Redis, and Sequelize. This documentation covers security features and detailed model specifications.

## Deployment & Docker Setup

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ (for local development)
- Git

### Docker Architecture
The application uses a multi-service Docker setup with the following components:

#### Services
- **app**: Node.js application (Express.js API)
- **mongo**: MongoDB 5.0 for chat messages and flexible schemas
- **postgres**: PostGIS-enabled PostgreSQL 15 for relational data and geospatial queries
- **redis**: Redis 7 Alpine for caching, sessions, and real-time features

#### Networks & Volumes
- **app-network**: Bridge network for inter-service communication
- **Persistent volumes**: mongo_data, postgres_data, redis_data for data persistence

### Quick Start with Docker

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hantario-api
   ```

2. **Environment Setup**
   Create a `.env` file in the root directory:
   ```env
   NODE_ENV=development
   PORT=3000
   MONGO_URI=mongodb://admin:password@mongo:27017/rental_db?authSource=admin
   DB_HOST=postgres
   DB_NAME=rental_db
   DB_USER=user
   DB_PASSWORD=password
   DB_PORT=5432
   REDIS_HOST=redis
   REDIS_PORT=6379
   JWT_SECRET=your-super-secret-jwt-key
   JWT_REFRESH_SECRET=your-refresh-token-secret
   ```

3. **Start the application**
   ```bash
   docker-compose up --build
   ```

4. **Access the application**
   - API: http://localhost:3000
   - Health check: http://localhost:3000/health

### Docker Commands

#### Development
```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up --build --force-recreate
```

#### Database Management
```bash
# Access PostgreSQL
docker-compose exec postgres psql -U user -d rental_db

# Access MongoDB
docker-compose exec mongo mongo -u admin -p password rental_db

# Access Redis
docker-compose exec redis redis-cli
```

#### Production Deployment
```bash
# Build for production
docker-compose -f docker-compose.yml up --build -d

# Scale services (if needed)
docker-compose up -d --scale app=3
```

### Dockerfile Details

The application uses a multi-stage Node.js Alpine image:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| NODE_ENV | Environment mode | development |
| PORT | Application port | 3000 |
| MONGO_URI | MongoDB connection string | mongodb://admin:password@mongo:27017/rental_db |
| DB_HOST | Database host | postgres |
| DB_NAME | Database name | rental_db |
| DB_USER | PostgreSQL user | user |
| DB_PASSWORD | PostgreSQL password | password |
| DB_PORT | PostgreSQL port | 5432 |
| REDIS_HOST | Redis host | redis |
| REDIS_PORT | Redis port | 6379 |
| JWT_SECRET | JWT signing secret | Required |
| JWT_REFRESH_SECRET | Refresh token secret | JWT_SECRET |

### Database Initialization

The application automatically:
1. Creates database tables via Sequelize migrations
2. Sets up indexes for optimal performance
3. Initializes MongoDB collections for chat functionality

### Troubleshooting

#### Common Issues
1. **Port conflicts**: Ensure ports 3000, 5432, 27017, 6379 are available
2. **Memory issues**: Increase Docker memory allocation
3. **Database connection**: Wait for services to fully start (check logs)

#### Logs and Monitoring
```bash
# View all service logs
docker-compose logs

# View specific service logs
docker-compose logs postgres
docker-compose logs mongo
docker-compose logs redis

# Health check
curl http://localhost:3000/health
```

## Security Features

### Authentication & Authorization

#### JWT Token System
- **Access Tokens**: Short-lived (15 minutes) JWT tokens for API access
- **Refresh Tokens**: Long-lived (7 days) tokens stored in Redis for token rotation
- **Token Rotation**: Automatic refresh token invalidation on use to prevent replay attacks

#### Two-Factor Authentication (2FA)
- OTP-based 2FA sent via email
- 10-minute OTP expiration
- Secure OTP storage in database (cleared after verification)

#### Password Security
- Bcrypt hashing with 12 salt rounds
- Minimum 6-character password requirement
- Automatic password hashing on create/update

### Middleware Security

#### Authentication Middleware (`src/middleware/authMiddleware.js`)
- Bearer token validation
- Optional authentication for public routes
- Test environment bypass for development

#### Security Headers (Helmet)
- Content Security Policy (CSP)
- X-Frame-Options, X-Content-Type-Options
- HSTS headers
- XSS protection

#### Rate Limiting
- 100 requests per 15-minute window per IP
- Standard rate limit headers returned

#### CORS Configuration
- Configurable origin policies
- Credential support for authenticated requests

### Data Validation & Sanitization

#### Input Validation
- Sequelize model-level validation
- Email format validation
- Phone number regex validation
- Coordinate bounds checking
- File upload restrictions

#### Database Security
- Parameterized queries via Sequelize
- Foreign key constraints
- Unique constraints on sensitive fields
- Index optimization for performance

### Infrastructure Security

#### Redis Integration
- Secure token storage
- Session management
- Rate limiting data
- Socket.io adapter for real-time features

#### Database Connections
- PostgreSQL with connection pooling
- MongoDB with authentication
- Environment-based configuration

## Model Documentation

### User Model (`src/models/User.js`)

**Purpose**: Core user management with authentication and profile data.

**Fields**:
- `id`: Primary key, auto-increment
- `name`: String (2-100 chars), required
- `email`: Unique string, required, email validation
- `phone`: Unique string, optional, phone regex validation
- `password`: String (6-255 chars), required, auto-hashed
- `city`: String, optional
- `location`: PostGIS Point (WGS84), optional
- `lat/lng`: Decimal coordinates, optional
- `two_factor_code/expire`: OTP fields, optional
- `looking_for`: Enum (buy/sale/rent/monitor/just_look), default 'just_look_around'
- `profile_picture_url`: URL string, optional
- `pending_balance/available_balance`: Integers, default 0
- `looking_for_set/category_set`: Booleans, default false
- `role`: Enum (admin/user), default 'user'
- `user_type`: Enum (buyer/seller), default 'buyer'
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Has many: ListingReviews, WithdrawBalances, ListingRentals, ListingBuyings, Favourites, Notifications, UserDevices
- Belongs to many: StateCategories (through UserStateCategory)
- Has many: UserBankAccounts

**Indexes**: Email, phone, location (GIST), city, looking_for, balance, composite filters

**Hooks**: Password hashing, JSON serialization (excludes password/OTP)

**Usage**: User registration, authentication, profile management, balance tracking

---

### Listing Model (`src/models/Listing.js`)

**Purpose**: Property listings with geospatial data and media.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign key to User, required
- `title`: String (1-255 chars), required
- `location`: PostGIS Point, required (auto-generated from lat/lng)
- `lat/lng`: Decimal coordinates, required
- `address`: Text, required
- `images`: JSON array, optional
- `sell_price/rent_price`: Integers, optional
- `rent_type`: Enum (daily/monthly/yearly), optional
- `description`: Text, optional
- `availability`: Enum ('1'/'2'), default '1'
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User
- Belongs to many: ListingTypes (through TypeListing)
- Belongs to many: PropertyCategories (through ListingCategory)
- Has many: ListingFeatures, ListingFacilities, ListingPlaces, ListingReviews, ListingVisits, ListingRentals, ListingBuyings, Favourites

**Indexes**: user_id, location (GIST), lat/lng, prices, availability, dates, composite queries

**Hooks**: Auto-generate PostGIS point from coordinates

**Usage**: Property creation, search, filtering, geospatial queries

---

### Conversation Model (`src/models/Conversation.js`) - MongoDB

**Purpose**: Chat conversations between users.

**Fields**:
- `participants`: Array of User ObjectIds, required
- `listing_id`: String, optional
- `last_message`: Object with text, type, created_at
- `unread_counts`: Map of user counts
- `created_at/updated_at`: Timestamps

**Indexes**: participants, listing_id

**Usage**: Real-time messaging, conversation management

---

### Message Model (`src/models/Message.js`) - MongoDB

**Purpose**: Individual chat messages.

**Fields**:
- `conversation_id`: ObjectId ref to Conversation, required
- `sender_id`: ObjectId ref to User, required
- `type`: Enum (text/image/video), required
- `text`: String, optional
- `media_url`: String, optional
- `listing_snapshot`: Object with listing data
- `reply_to`: ObjectId ref to Message, optional
- `reactions`: Array of user reactions
- `edited_at`: Date, optional
- `created_at`: Timestamp

**Indexes**: conversation_id + created_at

**Usage**: Message storage, reactions, replies, media sharing

---

### RecentSearch Model (`src/models/RecentSearch.js`)

**Purpose**: Track user search history for personalization.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign key to User, optional
- `device_id`: UUID, optional
- `search_text`: String (1-255 chars), required
- `category_id`: Foreign key to PropertyCategory, optional
- `latitude/longitude`: Doubles, required
- `radius`: Integer, default 0
- `created_at`: Timestamp

**Associations**:
- Belongs to: User, PropertyCategory

**Indexes**: user_id, device_id, category_id, dates, search_text, coordinates

**Usage**: Search history, personalized recommendations

---

### Company Model (`src/models/Company.js`)

**Purpose**: Company information for business listings.

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Strings, required/optional
- `address_en/address_so`: Texts, required/optional
- `emails/phones`: JSON arrays with validation
- `createdAt/updatedAt`: Timestamps

**Indexes**: Names, dates

**Usage**: Business directory, contact information

---

### Coupon Model (`src/models/Coupon.js`)

**Purpose**: Discount system for purchases.

**Fields**:
- `id`: Primary key, auto-increment
- `code`: Unique uppercase string (3-50 chars), required
- `type`: Enum (percentage/fixed), required
- `value`: Decimal, required
- `use_case`: Enum (listing_package/promotion_package/etc), required
- `min_purchase`: Integer, optional
- `start_date/expire_date`: Dates, optional
- `usage_limit/per_user_limit`: Integers, optional
- `is_active`: Boolean, default true
- `used`: Integer, default 0
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Has many: ListingRentals, ListingBuyings

**Indexes**: code (unique), type, use_case, active, expire_date, composite queries

**Hooks**: Code uppercasing, date validation, percentage limits

**Methods**: isExpired(), isStarted(), isValid(), canApplyToPurchase()

**Usage**: Discount application, promotional campaigns

---

### Facility Model (`src/models/Facility.js`)

**Purpose**: Property facilities/amenities.

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Unique strings, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Has many: ListingFacilities

**Indexes**: name_en (unique), dates

**Usage**: Amenity tagging, property features

---

### Faq Model (`src/models/Faq.js`)

**Purpose**: Frequently asked questions by user type.

**Fields**:
- `id`: Primary key, auto-increment
- `title_en/title_so`: Strings, required/optional
- `description_en/description_so`: Texts, optional
- `type`: Enum (buyer/seller), required
- `createdAt/updatedAt`: Timestamps

**Indexes**: titles, type, dates, composite

**Usage**: User support, onboarding

---

### Favourite Model (`src/models/Favourite.js`)

**Purpose**: User property favorites.

**Fields**:
- `user_id`: Composite primary key, foreign to User
- `listing_id`: Composite primary key, foreign to Listing
- `add_date`: Date, default NOW
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User, Listing

**Indexes**: user_id, listing_id, add_date, unique composite

**Usage**: Wishlist functionality, saved properties

---

### Language Model (`src/models/Language.js`)

**Purpose**: Multilingual content support.

**Fields**:
- `id`: Primary key, auto-increment
- `key`: Unique string, required
- `en/so`: Texts, required
- `createdAt/updatedAt`: Timestamps

**Indexes**: key (unique), dates

**Usage**: Internationalization, translations

---

### ListingBuying Model (`src/models/ListingBuying.js`)

**Purpose**: Property purchase transactions.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `buyer_id`: Foreign to User, required
- `subtotal/coupon_id/discount/total`: Decimals
- `status`: Enum (pending/paid/confirmed/cancelled/completed)
- `commission/sellers_value`: Decimals
- `bank_*`: Banking details, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, User, Coupon

**Indexes**: Foreign keys, status, dates, composite queries

**Usage**: Purchase workflow, transaction tracking

---

### ListingCategory Model (`src/models/ListingCategory.js`)

**Purpose**: Many-to-many relationship between listings and property categories.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `property_category_id`: Foreign to PropertyCategory, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, PropertyCategory

**Indexes**: Foreign keys, unique composite, dates

**Usage**: Property categorization, search filtering

---

### ListingFacility Model (`src/models/ListingFacility.js`)

**Purpose**: Facilities associated with specific listings.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `facility_id`: Foreign to Facility, required
- `value`: Text, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, Facility

**Indexes**: Foreign keys, unique composite, dates

**Usage**: Property amenity details

---

### ListingFeature Model (`src/models/ListingFeature.js`)

**Purpose**: Property features with values.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `property_feature_id`: Foreign to PropertyFeatures, required
- `value`: Text, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, PropertyFeatures

**Indexes**: Foreign keys, unique composite, dates

**Usage**: Property specifications, search filters

---

### ListingNotificationsMap Model (`src/models/ListingNotificationsMap.js`)

**Purpose**: Track notification delivery for listings.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `user_id`: Foreign to User, required
- `sent_at`: Date, default NOW
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, User

**Indexes**: Foreign keys, sent_at, unique composite, dates

**Usage**: Notification tracking, delivery confirmation

---

### ListingPack Model (`src/models/ListingPack.js`)

**Purpose**: Subscription packages for listings.

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Strings, required
- `price`: Integer, required
- `duration`: Integer (days), required
- `features`: JSON, optional
- `listing_amount`: Integer, required
- `display`: TinyInt (0/1), default 1
- `createdAt/updatedAt`: Timestamps

**Indexes**: Names, price, duration, listing_amount, display, dates

**Usage**: Subscription management, feature access control

---

### ListingPlace Model (`src/models/ListingPlace.js`)

**Purpose**: Nearby places associated with listings.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `nearby_place_id`: Foreign to NearbyPlace, required
- `value`: Text, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, NearbyPlace

**Indexes**: Foreign keys, unique composite, dates

**Usage**: Location context, nearby amenities

---

### ListingRental Model (`src/models/ListingRental.js`)

**Purpose**: Property rental transactions.

**Fields**:
- `id`: Primary key, auto-increment
- `list_id`: Foreign to Listing, required
- `renter_id`: Foreign to User, required
- `start_date/end_date`: Dates, required
- `rent_type`: Enum (daily/monthly/yearly), required
- `status`: Enum (pending/confirmed/cancelled/completed)
- `date`: Date, default NOW
- `subtotal/coupon_id/discount/total`: Decimals
- `commission/sellers_value`: Decimals
- `bank_*`: Banking details, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, User, Coupon

**Indexes**: Foreign keys, status, dates, composite queries

**Hooks**: Date validation, total calculation

**Usage**: Rental booking, payment processing

---

### ListingReview Model (`src/models/ListingReview.js`)

**Purpose**: User reviews for properties.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `user_id`: Foreign to User, required
- `rating`: Integer (1-5), required
- `comment`: Text (1-1000 chars), required
- `images`: JSON array, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, User

**Indexes**: Foreign keys, rating, dates, composite

**Usage**: Review system, property ratings

---

### ListingType Model (`src/models/ListingType.js`)

**Purpose**: Property types (apartment, house, etc.).

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Unique strings, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to many: Listings (through TypeListing)

**Indexes**: name_en (unique), dates

**Usage**: Property type classification

---

### ListingVisit Model (`src/models/ListingVisit.js`)

**Purpose**: Analytics for property views and interactions.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `total_impression/app_impression/ad_impression`: Integers
- `total_visit/app_visit/ad_visit/share_visit`: Integers
- `conversion`: Integer
- `date`: DateOnly, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing

**Indexes**: listing_id, date, metrics, unique composite, dates

**Usage**: Performance analytics, marketing insights

---

### Location Model (`src/models/Location.js`)

**Purpose**: Geographic locations.

**Fields**:
- `id`: Primary key, auto-increment
- `name`: String, required
- `latitude/longitude`: Decimals, required
- `address`: Text, optional
- `createdAt/updatedAt`: Timestamps

**Indexes**: coordinates

**Usage**: Location services, mapping

---

### NearbyPlace Model (`src/models/NearbyPlace.js`)

**Purpose**: Types of nearby places (schools, hospitals, etc.).

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Unique strings, required
- `createdAt/updatedAt`: Timestamps

**Indexes**: name_en (unique), dates

**Usage**: Location context, amenity categorization

---

### Notification Model (`src/models/Notification.js`)

**Purpose**: User notifications.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign to User, required
- `type`: String, required
- `title/message`: Strings, required
- `data`: JSONB, optional
- `is_read`: Boolean, default false
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User

**Indexes**: user_id, type, is_read, dates, composite

**Usage**: Push notifications, in-app alerts

---

### Promotion Model (`src/models/Promotion.js`)

**Purpose**: Property promotion campaigns.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `subtotal/coupon_id/discount/total`: Decimals
- `start_date/end_date`: Dates, required
- `promotion_package_id`: Foreign to PromotionPack, optional
- `status`: Enum (active/expired), default active
- `bank_*`: Banking details, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, Coupon, PromotionPack

**Indexes**: Foreign keys, status, dates, composite

**Hooks**: Date validation, status auto-update, total calculation

**Methods**: isActive(), isExpired(), getDuration()

**Usage**: Marketing campaigns, property visibility

---

### PromotionPack Model (`src/models/PromotionPack.js`)

**Purpose**: Promotion subscription packages.

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Strings, required
- `duration`: Integer (days), required
- `price`: Decimal, required
- `availability`: TinyInt (0/1), default 1
- `createdAt/updatedAt`: Timestamps

**Indexes**: Names, duration, price, availability, dates

**Usage**: Promotion subscriptions, feature access

---

### PropertyCategory Model (`src/models/PropertyCategory.js`)

**Purpose**: Property categories (residential, commercial, etc.).

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Unique strings, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to many: Listings (through ListingCategory)

**Indexes**: name_en (unique), dates

**Usage**: Property classification, search filtering

---

### PropertyFeatures Model (`src/models/PropertyFeatures.js`)

**Purpose**: Property feature types (bedrooms, bathrooms, etc.).

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Unique strings, required
- `type`: Enum (number/string), default string
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Has many: ListingFeatures

**Indexes**: name_en (unique), dates

**Usage**: Property specifications, dynamic attributes

---

### StateCategory Model (`src/models/StateCategory.js`)

**Purpose**: Geographic states/regions.

**Fields**:
- `id`: Primary key, auto-increment
- `name_en/name_so`: Strings, required
- `thumb_url`: String, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to many: Users (through UserStateCategory)

**Usage**: Regional filtering, user preferences

---

### TypeListing Model (`src/models/TypeListing.js`)

**Purpose**: Many-to-many relationship between listings and listing types.

**Fields**:
- `id`: Primary key, auto-increment
- `listing_id`: Foreign to Listing, required
- `listing_type_id`: Foreign to ListingType, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: Listing, ListingType

**Indexes**: Foreign keys, unique composite, dates

**Usage**: Property type assignment

---

### UserBankAccount Model (`src/models/UserBankAccount.js`)

**Purpose**: User banking information for transactions.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign to User, required
- `bank_name/branch`: Strings, required
- `account_no`: Unique string (8-20 chars), required
- `account_holder_name`: String, required
- `swift_code`: String (8-11 chars), optional
- `is_default`: Boolean, default false
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User

**Indexes**: user_id, account_no (unique), is_default, dates

**Usage**: Payment processing, withdrawals

---

### UserDevice Model (`src/models/UserDevice.js`)

**Purpose**: User device tracking for notifications.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign to User, required
- `device_type`: String (1-20 chars), required
- `fcm_token`: Text, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User

**Indexes**: user_id, device_type, dates, composite

**Usage**: Push notification delivery

---

### UserListingPack Model (`src/models/UserListingPack.js`)

**Purpose**: User subscription management.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign to User, required
- `listing_pack_id`: Foreign to ListingPack, required
- `start/end`: Dates, required
- `status`: Enum (active/expired/cancelled/upgraded/downgraded)
- `total_paid/remain_balance`: Decimals
- `upgrade_from_pack_id/downgrade_to_pack_id`: Foreign keys, optional
- `date`: Date, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User, ListingPack (multiple)

**Indexes**: Foreign keys, status, dates, composite

**Usage**: Subscription lifecycle, feature access

---

### UserListingPackTransaction Model (`src/models/UserListingPackTransaction.js`)

**Purpose**: Subscription transaction history.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign to User, required
- `listing_pack_id`: Foreign to ListingPack, required
- `type`: Enum (buy/upgrade/downgrade/renew/refund/adjustment)
- `subtotal/coupon_id/discount/total`: Decimals
- `coupon_code/previous_pack_id/adjusted_amount`: Various
- `payment_method`: Enum (bank/card/wallet/admin)
- `transaction_ref`: Unique string, required
- `status`: Enum (pending/success/failed)
- `note`: Text, optional
- `bank_*`: Banking details, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User, ListingPack, Coupon, ListingPack (previous)

**Indexes**: Foreign keys, status, type, dates

**Usage**: Transaction history, billing

---

### UserStateCategory Model (`src/models/UserStateCategory.js`)

**Purpose**: User regional preferences.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign to User, required
- `state_categories_id`: Foreign to StateCategory, required
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User, StateCategory

**Indexes**: Unique composite, foreign keys, dates

**Usage**: Location-based preferences

---

### WithdrawBalance Model (`src/models/WithdrawBalance.js`)

**Purpose**: User withdrawal requests.

**Fields**:
- `id`: Primary key, auto-increment
- `user_id`: Foreign to User, required
- `amount`: Decimal, required
- `status`: Enum (requested/success/failed/cancelled)
- `date`: Date, default NOW
- `before_balance/after_balance`: Decimals
- `bank_*`: Banking details, optional
- `createdAt/updatedAt`: Timestamps

**Associations**:
- Belongs to: User

**Indexes**: user_id, status, date, composite, dates

**Usage**: Withdrawal workflow, balance management

---

### CompanyEarning Model (`src/models/CompanyEarning.js`)

**Purpose**: Daily company earnings tracking.

**Fields**:
- `id`: Primary key, auto-increment
- `date`: DateOnly, required
- `commission/listing/promotion`: Decimals, default 0
- `createdAt/updatedAt`: Timestamps

**Indexes**: date, dates, composite

**Methods**: getTotalEarnings()

**Usage**: Financial reporting, revenue tracking

---

### ListingConversation Model (`src/models/ListingConversation.js`) - MongoDB

**Purpose**: Link conversations to specific listings.

**Fields**:
- `listing_id`: String, required
- `conversation_id`: ObjectId ref to Conversation, required
- `participants`: Array of User ObjectIds, required
- `created_at`: Timestamp

**Indexes**: listing_id

**Usage**: Property-specific chat rooms

---

## API Usage Examples

### Authentication Flow
```
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

Response: { accessToken, refreshToken }

POST /api/auth/refresh
Authorization: Bearer <refreshToken>

Response: { accessToken, refreshToken }
```

### Creating a Listing
```
POST /api/listings
Authorization: Bearer <accessToken>
{
  "title": "Beautiful Apartment",
  "lat": 40.7128,
  "lng": -74.0060,
  "address": "123 Main St, New York, NY",
  "sell_price": 500000,
  "images": ["url1.jpg", "url2.jpg"]
}
```

### Chat System
```
Socket.io events:
- join: Join user room
- send_message: Send message to conversation
- edit_message: Edit existing message
- add_reaction: Add emoji reaction
```

## Database Architecture

- **PostgreSQL**: Relational data, transactions, complex queries
- **MongoDB**: Chat messages, flexible schemas
- **Redis**: Caching, sessions, real-time data

## Performance Optimizations

- Database indexing on frequently queried fields
- PostGIS for geospatial queries
- Redis caching for hot data
- Rate limiting to prevent abuse
- Connection pooling for databases

## Monitoring & Health Checks

- `/health` endpoint for service status
- Database connection monitoring
- Redis connectivity checks
- Automatic graceful shutdown handling
