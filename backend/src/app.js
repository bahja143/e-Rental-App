require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const { createClient } = require('redis');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const http = require('http');
const path = require('path');
const socketIo = require('socket.io');

// Import configurations and modules
const { sequelize, redisClient } = require('./config/database');
const db = require('./models');
const routes = require('./routes');
const authService = require('./services/authService');
const { emailQueue, emailWorker } = require('./queues');
const { isMongoEnabled, isMongoConnected } = require('./services/mongoService');
const { getPublicBaseUrl, rewritePublicUploadUrlsDeep } = require('./utils/publicUrl');

const app = express();
const server = http.createServer(app);

const PORT = process.env.PORT || 3000;

// Middleware
app.set('trust proxy', true);
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API request/response logging (shows in backend terminal)
app.use((req, res, next) => {
  const start = Date.now();
  const reqBody = req.body && Object.keys(req.body).length ? JSON.stringify(req.body, null, 2) : null;
  let resBody = null;
  const origJson = res.json.bind(res);
  res.json = function (body) {
    const normalizedBody = rewritePublicUploadUrlsDeep(req, body);
    resBody = typeof normalizedBody === 'string' ? normalizedBody : JSON.stringify(normalizedBody, null, 2);
    return origJson(normalizedBody);
  };
  const origSend = res.send.bind(res);
  res.send = function (body) {
    if (body && !resBody) resBody = typeof body === 'object' ? JSON.stringify(body, null, 2) : String(body).slice(0, 500);
    return origSend(body);
  };
  console.log('\n' + '═'.repeat(50));
  console.log(`>>> ${req.method} ${req.originalUrl || req.url}`);
  if (reqBody) console.log('REQ BODY:\n' + reqBody);
  res.on('finish', () => {
    const ms = Date.now() - start;
    console.log(`<<< RESPONSE ${res.statusCode} (${ms}ms)`);
    if (resBody) console.log('RES BODY:\n' + (resBody.length > 600 ? resBody.slice(0, 600) + '...' : resBody));
    console.log('═'.repeat(50) + '\n');
  });
  next();
});
app.use(morgan('dev'));

const normalizeClientIp = (value) => {
  const ip = String(value || '').trim();
  if (!ip) return '';
  if (ip.startsWith('::ffff:')) return ip.substring(7);
  return ip;
};

const isPrivateClientIp = (value) => {
  const ip = normalizeClientIp(value);
  return ip === '127.0.0.1' ||
    ip === '::1' ||
    ip.startsWith('10.') ||
    ip.startsWith('192.168.') ||
    /^172\.(1[6-9]|2\d|3[0-1])\./.test(ip);
};

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 100 : 1000,
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  skip: (req) => process.env.NODE_ENV !== 'production' && isPrivateClientIp(req.ip),
});
app.use(limiter);

let io;

if (process.env.NODE_ENV !== 'test') {
  // MongoDB connection
  if (isMongoEnabled()) {
    mongoose.connect(process.env.MONGO_URI || 'mongodb://admin:password@mongo:27017/rental_db?authSource=admin', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    })
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));
  } else {
    console.log('MongoDB disabled via MONGO_ENABLED=false');
  }

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

// Serve uploaded files (e.g. profile images)
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// Routes
app.use('/api', routes);

// Auth inline routes (BEFORE auth router so they are always hit)
const authRoutes = require('./routes/auth');
const { User } = require('./models');
const firebaseService = require('./services/firebaseService');
app.post('/api/auth/google-preflight', async (req, res) => {
  try {
    const { idToken } = req.body || {};
    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({ error: 'idToken is required' });
    }
    if (!firebaseService.isEnabled) {
      return res.status(503).json({ error: 'Google Sign-In is temporarily unavailable' });
    }
    const decoded = await firebaseService.verifyIdToken(idToken);
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid Google credentials' });
    }
    const email = decoded.email;
    const name = decoded.name || decoded.email?.split('@')[0] || 'User';
    const photoUrl = decoded.picture || null;
    const phone = decoded.phone_number || null;
    if (!email) {
      return res.status(400).json({ error: 'Email not provided by Google' });
    }
    const user = await User.findOne({ where: { email } });
    if (user) {
      return res.json({ exists: true, name, email, photoUrl, phone });
    }
    return res.json({ exists: false, name, email, photoUrl, phone });
  } catch (error) {
    console.error('Google preflight error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Register with Google - also registered here to fix 404 when auth router fails
const crypto = require('crypto');
app.post('/api/auth/register-with-google', async (req, res) => {
  try {
    const { idToken, name, email, phone, profile_picture_url, preferred_property_types, looking_for_options, lat, lng } = req.body || {};
    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({ error: 'idToken is required' });
    }
    if (!firebaseService.isEnabled) {
      return res.status(503).json({ error: 'Google Sign-In is temporarily unavailable' });
    }
    const decoded = await firebaseService.verifyIdToken(idToken);
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid Google credentials' });
    }
    const tokenEmail = (decoded.email || '').trim().toLowerCase();
    if (!tokenEmail) {
      return res.status(400).json({ error: 'Email not provided by Google' });
    }
    const sanitizedName = (name && typeof name === 'string') ? name.trim() : decoded.name || tokenEmail.split('@')[0] || 'User';
    const sanitizedEmail = (email && typeof email === 'string') ? email.trim().toLowerCase() : tokenEmail;
    if (sanitizedEmail !== tokenEmail) {
      return res.status(400).json({ error: 'Email does not match Google account' });
    }
    let sanitizedPhone = null;
    if (phone && (typeof phone === 'string' || typeof phone === 'number')) {
      const phoneStr = phone.toString().replace(/[^\d+\-\s()]/g, '').trim();
      if (/^[\+]?[1-9][\d]{0,15}$/.test(phoneStr)) sanitizedPhone = phoneStr;
    }
    let sanitizedProfileUrl = null;
    if (profile_picture_url && typeof profile_picture_url === 'string' && /^https?:\/\/.+/.test(profile_picture_url.trim())) {
      sanitizedProfileUrl = profile_picture_url.trim();
    }
    if (!sanitizedProfileUrl && decoded.picture && typeof decoded.picture === 'string' && /^https?:\/\/.+/.test(decoded.picture.trim())) {
      sanitizedProfileUrl = decoded.picture.trim();
    }
    if (sanitizedProfileUrl) {
      console.log('[register-with-google] Using profile_picture_url:', sanitizedProfileUrl.substring(0, 80) + '...');
    }
    const validLookingFor = ['buy', 'sale', 'rent', 'monitor_my_property', 'just_look_around'];
    let sanitizedLookingForOptions = null;
    if (Array.isArray(looking_for_options) && looking_for_options.length > 0) {
      sanitizedLookingForOptions = looking_for_options
        .filter((v) => typeof v === 'string' && validLookingFor.includes(v))
        .filter((v, i, arr) => arr.indexOf(v) === i);
      if (sanitizedLookingForOptions.length === 0) sanitizedLookingForOptions = ['just_look_around'];
    }
    const sanitizedLookingFor = (sanitizedLookingForOptions?.[0]) ?? 'just_look_around';

    let user = await User.findOne({ where: { email: sanitizedEmail } });
    if (user) {
      const updates = {};
      if (sanitizedPhone && user.phone !== sanitizedPhone) {
        const existingByPhone = await User.findOne({ where: { phone: sanitizedPhone } });
        if (existingByPhone && existingByPhone.id !== user.id) {
          return res.status(409).json({ error: 'This mobile number is already linked to another account.' });
        }
        updates.phone = sanitizedPhone;
      }
      if (sanitizedProfileUrl && !user.profile_picture_url) {
        updates.profile_picture_url = sanitizedProfileUrl;
      }
      if (Object.keys(updates).length > 0) {
        await user.update(updates);
      }
    } else {
      const existingByPhone = sanitizedPhone ? await User.findOne({ where: { phone: sanitizedPhone } }) : null;
      if (existingByPhone) {
        return res.status(409).json({ error: 'This mobile number is already linked to another account.' });
      }
      const randomPassword = crypto.randomBytes(32).toString('hex');
      const userData = {
        name: sanitizedName,
        email: sanitizedEmail,
        password: randomPassword,
        phone: sanitizedPhone,
        profile_picture_url: sanitizedProfileUrl,
        preferred_property_types: Array.isArray(preferred_property_types) ? preferred_property_types : null,
        looking_for_options: sanitizedLookingForOptions,
        looking_for: sanitizedLookingFor,
        looking_for_set: true,
        category_set: true,
        role: 'user',
        user_type: 'buyer',
      };
      if (lat !== undefined && lng !== undefined) {
        const latFloat = parseFloat(lat);
        const lngFloat = parseFloat(lng);
        if (!isNaN(latFloat) && latFloat >= -90 && latFloat <= 90 && !isNaN(lngFloat) && lngFloat >= -180 && lngFloat <= 180) {
          userData.lat = parseFloat(latFloat.toFixed(8));
          userData.lng = parseFloat(lngFloat.toFixed(8));
        }
      }
      user = await User.create(userData);
    }

    const keepLoggedIn = true; // Mobile app: keep logged in until logout
    const accessToken = authService.generateAccessToken(user, keepLoggedIn);
    const refreshToken = authService.generateRefreshToken(user, keepLoggedIn);
    await authService.storeRefreshToken(user.id, refreshToken, keepLoggedIn);

    res.json({
      message: 'Registration successful',
      user: { id: user.id, name: user.name, email: user.email, profile_picture_url: user.profile_picture_url },
      tokens: { accessToken, refreshToken, accessTokenExpiresIn: '365d', refreshTokenExpiresIn: '365d' },
    });
  } catch (error) {
    console.error('Register with Google error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login with phone - verify Firebase ID token (from phone auth), find user by phone
app.post('/api/auth/login-with-phone', async (req, res) => {
  try {
    const { idToken, rememberMe } = req.body || {};
    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({ error: 'idToken is required' });
    }
    if (!firebaseService.isEnabled) {
      return res.status(503).json({ error: 'Phone sign-in is temporarily unavailable' });
    }
    const decoded = await firebaseService.verifyIdToken(idToken);
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const phone = decoded.phone_number || decoded.phone || null;
    if (!phone || typeof phone !== 'string') {
      return res.status(400).json({ error: 'Phone number not found in token' });
    }
    const phoneStr = phone.toString().replace(/[^\d+\-\s()]/g, '').trim();
    if (!/^[\+]?[1-9][\d]{0,15}$/.test(phoneStr)) {
      return res.status(400).json({ error: 'Invalid phone format' });
    }
    // Try exact format first, then alternate (+ prefix) to match check-availability
    let user = await User.findOne({ where: { phone: phoneStr } });
    if (!user && phoneStr.startsWith('+')) {
      user = await User.findOne({ where: { phone: phoneStr.slice(1) } });
    }
    if (!user && !phoneStr.startsWith('+')) {
      user = await User.findOne({ where: { phone: `+${phoneStr}` } });
    }
    if (!user) {
      return res.status(404).json({ error: 'No account found. Please register first.' });
    }
    const keepLoggedIn = Boolean(rememberMe);
    const accessToken = authService.generateAccessToken(user, keepLoggedIn);
    const refreshToken = authService.generateRefreshToken(user, keepLoggedIn);
    await authService.storeRefreshToken(user.id, refreshToken, keepLoggedIn);
    res.json({
      message: 'Login successful',
      user: { id: user.id, name: user.name, email: user.email },
      tokens: {
        accessToken,
        refreshToken,
        accessTokenExpiresIn: keepLoggedIn ? '365d' : '15m',
        refreshTokenExpiresIn: keepLoggedIn ? '365d' : '7d',
      },
    });
  } catch (error) {
    console.error('Login with phone error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.use('/api/auth', authRoutes);

// Upload routes
const uploadRoutes = require('./routes/upload');
app.use('/api/upload', uploadRoutes);

// Basic route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Hantario API' });
});

// Ping route - hit from Flutter or browser to verify backend is reachable
app.get('/api/ping', (req, res) => {
  res.json({
    ok: true,
    message: 'Backend reachable',
    ts: new Date().toISOString(),
    publicBaseUrl: getPublicBaseUrl(req),
    apiBaseUrl: `${getPublicBaseUrl(req)}/api`,
  });
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
    if (!isMongoEnabled()) {
      health.services.mongo = 'disabled';
    } else if (isMongoConnected()) {
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
  if (mongoose.connection.readyState !== 0) {
    await mongoose.connection.close();
  }
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
    console.log(`Public base URL: ${process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`}`);
    console.log('Accepting connections on 0.0.0.0 - use your public base URL or LAN IP for clients');
  });
}

module.exports = app;
