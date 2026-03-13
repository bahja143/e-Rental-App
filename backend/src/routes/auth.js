const express = require('express');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const authService = require('../services/authService');
const { authenticateToken } = require('../middleware/authMiddleware');

const router = express.Router();

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
    const { email, otp } = req.body;

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

    // Generate tokens
    const accessToken = authService.generateAccessToken(user);
    const refreshToken = authService.generateRefreshToken(user);

    // Store refresh token
    await authService.storeRefreshToken(user.id, refreshToken);

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
        accessTokenExpiresIn: '15m',
        refreshTokenExpiresIn: '7d',
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
