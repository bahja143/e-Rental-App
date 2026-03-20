const express = require('express');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { User } = require('../models');
const authService = require('../services/authService');
const { authenticateToken } = require('../middleware/authMiddleware');
const firebaseService = require('../services/firebaseService');

const router = express.Router();

// Check if email or phone already exists (for registration)
router.post('/check-availability', async (req, res) => {
  try {
    const { email, phone } = req.body;
    let emailExists = false;
    let phoneExists = false;

    if (email && typeof email === 'string' && email.trim().length > 0) {
      const existingByEmail = await User.findOne({ where: { email: email.trim().toLowerCase() } });
      emailExists = !!existingByEmail;
    }
    if (phone && (typeof phone === 'string' || typeof phone === 'number')) {
      const phoneStr = phone.toString().replace(/[^\d+\-\s()]/g, '').trim();
      if (phoneStr.length > 0 && /^[\+]?[1-9][\d]{0,15}$/.test(phoneStr)) {
        const existingByPhone = await User.findOne({ where: { phone: phoneStr } });
        phoneExists = !!existingByPhone;
      }
    }

    res.json({ emailExists, phoneExists });
  } catch (error) {
    console.error('Check availability error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login with email and password (direct, no OTP)
router.post('/login', async (req, res) => {
  try {
    const { email, password, rememberMe } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isValidPassword = await user.checkPassword(password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate tokens (long-lived when rememberMe)
    const accessToken = authService.generateAccessToken(user, Boolean(rememberMe));
    const refreshToken = authService.generateRefreshToken(user, Boolean(rememberMe));

    // Store refresh token
    await authService.storeRefreshToken(user.id, refreshToken, Boolean(rememberMe));

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
      tokens: {
        accessToken,
        refreshToken,
        accessTokenExpiresIn: rememberMe ? '365d' : '15m',
        refreshTokenExpiresIn: rememberMe ? '365d' : '7d',
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Verify OTP and complete login
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp, rememberMe } = req.body;

    // Validate input
    if (!email || !otp) {
      return res.status(400).json({ error: 'Email and OTP are required' });
    }

    // Find user
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email' });
    }

    // Verify OTP
    await authService.verifyOTP(user, otp);

    const keepLoggedIn = Boolean(rememberMe);
    const accessToken = authService.generateAccessToken(user, keepLoggedIn);
    const refreshToken = authService.generateRefreshToken(user, keepLoggedIn);
    await authService.storeRefreshToken(user.id, refreshToken, keepLoggedIn);

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
      tokens: {
        accessToken,
        refreshToken,
        accessTokenExpiresIn: keepLoggedIn ? '365d' : '15m',
        refreshTokenExpiresIn: keepLoggedIn ? '365d' : '7d',
      },
    });
  } catch (error) {
    console.error('OTP verification error:', error);
    res.status(401).json({ error: error.message });
  }
});

// Refresh tokens
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }

    // Decode refresh token to get user ID
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);
    const userId = decoded.userId;

    // Refresh tokens with rotation
    const tokens = await authService.refreshTokens(userId, refreshToken);

    res.json({
      message: 'Tokens refreshed',
      tokens: {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessTokenExpiresIn: '15m',
        refreshTokenExpiresIn: '7d',
      },
    });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});

// Google preflight: verify token, check if user exists, return profile for registration (no login)
router.post('/google-preflight', async (req, res) => {
  try {
    const { idToken } = req.body;
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
      return res.json({
        exists: true,
        name,
        email,
        photoUrl,
        phone,
      });
    }
    return res.json({
      exists: false,
      name,
      email,
      photoUrl,
      phone,
    });
  } catch (error) {
    console.error('Google preflight error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Complete registration with Google - verify token, create user or log in if exists, return tokens
router.post('/register-with-google', async (req, res) => {
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
    } else if (decoded.picture && typeof decoded.picture === 'string' && /^https?:\/\/.+/.test(decoded.picture.trim())) {
      sanitizedProfileUrl = decoded.picture.trim();
    }
    if (sanitizedProfileUrl) console.log('[register-with-google] profile_picture_url:', sanitizedProfileUrl.length > 60 ? sanitizedProfileUrl.substring(0, 60) + '...' : sanitizedProfileUrl);
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
        return res.status(409).json({ error: 'This mobile number is already linked to an account.' });
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
      tokens: {
        accessToken,
        refreshToken,
        accessTokenExpiresIn: '365d',
        refreshTokenExpiresIn: '365d',
      },
    });
  } catch (error) {
    console.error('Register with Google error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Social login (Google) - verify Firebase ID token, find or create user, return session
router.post('/social-login', async (req, res) => {
  try {
    const { provider, idToken, createIfNotExists = true, rememberMe } = req.body;
    if (provider !== 'google' || !idToken || typeof idToken !== 'string') {
      return res.status(400).json({ error: 'Provider and idToken are required' });
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
    if (!email) {
      return res.status(400).json({ error: 'Email not provided by Google' });
    }

    let user = await User.findOne({ where: { email } });
    if (!user) {
      if (!createIfNotExists) {
        return res.status(404).json({ error: 'No account found. Create one with Register or use phone if you signed up that way.' });
      }
      const randomPassword = crypto.randomBytes(32).toString('hex');
      user = await User.create({
        name,
        email,
        password: randomPassword,
        phone: null,
        role: 'user',
        user_type: 'buyer',
      });
    }

    const keepLoggedIn = Boolean(rememberMe);
    const accessToken = authService.generateAccessToken(user, keepLoggedIn);
    const refreshToken = authService.generateRefreshToken(user, keepLoggedIn);
    await authService.storeRefreshToken(user.id, refreshToken, keepLoggedIn);

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
      tokens: {
        accessToken,
        refreshToken,
        accessTokenExpiresIn: keepLoggedIn ? '365d' : '15m',
        refreshTokenExpiresIn: keepLoggedIn ? '365d' : '7d',
      },
    });
  } catch (error) {
    console.error('Social login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login with phone - verify Firebase ID token (from phone auth), find user by phone
router.post('/login-with-phone', async (req, res) => {
  try {
    const { idToken, rememberMe } = req.body;
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
    const user = await User.findOne({ where: { phone: phoneStr } });
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

// Logout
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Remove refresh token
    await authService.logout(userId);

    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get current user profile
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update current user profile
router.patch('/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const { name, phone, city, profile_picture_url } = req.body;
    const updateData = {};

    if (name !== undefined) {
      if (typeof name !== 'string' || name.trim().length < 2 || name.trim().length > 100) {
        return res.status(400).json({ error: 'Name must be 2-100 characters' });
      }
      updateData.name = name.trim();
    }
    if (phone !== undefined) {
      if (phone === null) {
        updateData.phone = null;
      } else {
        const phoneStr = phone.toString().replace(/[^\d+\-\s()]/g, '');
        if (!/^[\+]?[1-9][\d]{0,15}$/.test(phoneStr)) {
          return res.status(400).json({ error: 'Invalid phone number format' });
        }
        updateData.phone = phoneStr;
      }
    }
    if (city !== undefined) {
      if (city === null || city === '') {
        updateData.city = null;
      } else if (typeof city === 'string') {
        updateData.city = city.trim().substring(0, 255);
      } else {
        return res.status(400).json({ error: 'Invalid city format' });
      }
    }
    if (profile_picture_url !== undefined) {
      if (profile_picture_url === null) {
        updateData.profile_picture_url = null;
      } else if (typeof profile_picture_url === 'string' && /^https?:\/\/.+/.test(profile_picture_url.trim())) {
        updateData.profile_picture_url = profile_picture_url.trim();
      } else {
        return res.status(400).json({ error: 'Invalid profile picture URL' });
      }
    }

    await user.update(updateData);
    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
