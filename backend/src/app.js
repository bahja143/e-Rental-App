require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const { createClient } = require('redis');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const http = require('http');
const socketIo = require('socket.io');

// Import configurations and modules
const { sequelize, redisClient } = require('./config/database');
const db = require('./models');
const routes = require('./routes');
const authService = require('./services/authService');
const { emailQueue, emailWorker } = require('./queues');

const app = express();
const server = http.createServer(app);

const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});
app.use(limiter);

let io;

if (process.env.NODE_ENV !== 'test') {
  // MongoDB connection
  mongoose.connect(process.env.MONGO_URI || 'mongodb://admin:password@mongo:27017/rental_db?authSource=admin', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

  // Test database connection (MySQL or PostgreSQL)
  const dbDialect = process.env.DB_DIALECT || 'mysql';
  sequelize.authenticate()
    .then(() => {
      console.log(`${dbDialect === 'mysql' ? 'MySQL' : 'PostgreSQL'} connected`);
    })
    .catch(err => console.error('Database connection error:', err));

  // Initialize Socket.IO after Redis is connected
  io = socketIo(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  // Socket.io connection handling
  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    // Join user room
    socket.on('join', (userId) => {
      socket.join(userId);
      console.log(`User ${userId} joined room`);
    });

    // Handle new message
    socket.on('send_message', async (data) => {
      // Emit to receiver
      const { receiverId, message } = data;
      io.to(receiverId).emit('new_message', message);
    });

    // Handle message edit
    socket.on('edit_message', async (data) => {
      const { conversationId, message } = data;
      // Emit to all participants except sender
      socket.to(conversationId).emit('message_edited', message);
    });

    // Handle reaction
    socket.on('add_reaction', async (data) => {
      const { conversationId, message } = data;
      socket.to(conversationId).emit('reaction_added', message);
    });

    // Handle disconnect
    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
    });
  });

}

// Routes
app.use('/api', routes);

// Auth routes
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

// Basic route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Hantario API' });
});

// Health check route
app.get('/health', async (req, res) => {
  const health = {
    status: 'OK',
    services: {},
    timestamp: new Date().toISOString(),
  };

  try {
    await sequelize.authenticate();
    health.services.postgres = 'connected';
  } catch (error) {
    health.services.postgres = 'disconnected';
    health.status = 'ERROR';
  }

  try {
    if (mongoose.connection.readyState === 1) {
      await mongoose.connection.db.admin().ping();
      health.services.mongo = 'connected';
    } else {
      health.services.mongo = 'disconnected';
      health.status = 'ERROR';
    }
  } catch (error) {
    health.services.mongo = 'disconnected';
    health.status = 'ERROR';
  }

  try {
    await redisClient.ping();
    health.services.redis = 'connected';
  } catch (error) {
    health.services.redis = 'disconnected';
    health.status = 'ERROR';
  }

  res.status(health.status === 'OK' ? 200 : 500).json(health);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  await sequelize.close();
  await mongoose.connection.close();
  await emailQueue.close();
  await emailWorker.close();
  if (redisClient.isOpen) {
    await redisClient.quit();
  }
  if (io) {
    io.close();
  }
  process.exit(0);
});

// Start server if this file is run directly
if (require.main === module) {
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
