const jwt = require('jsonwebtoken');
const { createClient } = require('redis');
const EmailService = require('./emailService');

class AuthService {
  constructor() {
    this.redisClient = createClient({
      url: process.env.REDIS_URL || 'redis://redis:6379',
    });

    this.redisClient.on('error', (err) => console.error('Redis Client Error', err));
  }

  async ensureConnected() {
    if (!this.redisClient.isOpen) {
      await this.redisClient.connect();
    }
  }

  // Generate access token (15m default, 365d when rememberMe)
  generateAccessToken(user, rememberMe = false) {
    const payload = { userId: user.id, email: user.email };
    if (user.role != null) payload.role = user.role;
    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: rememberMe ? '365d' : '15m' });
  }

  // Generate refresh token (7d default, 365d when rememberMe)
  generateRefreshToken(user, rememberMe = false) {
    const payload = { userId: user.id, email: user.email, type: 'refresh', rememberMe: !!rememberMe };
    if (user.role != null) payload.role = user.role;
    return jwt.sign(payload, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET, { expiresIn: rememberMe ? '365d' : '7d' });
  }

  // Store refresh token in Redis
  async storeRefreshToken(userId, refreshToken, rememberMe = false) {
    await this.ensureConnected();
    const key = `refresh_token:${userId}`;
    const ttlSeconds = rememberMe ? 365 * 24 * 60 * 60 : 7 * 24 * 60 * 60;
    await this.redisClient.setEx(key, ttlSeconds, refreshToken);
  }

  // Verify refresh token
  async verifyRefreshToken(userId, refreshToken) {
    try {
      await this.ensureConnected();
      const key = `refresh_token:${userId}`;
      const storedToken = await this.redisClient.get(key);

      if (!storedToken || storedToken !== refreshToken) {
        return false;
      }

      // Verify JWT
      const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);
      return decoded;
    } catch (error) {
      console.error('Refresh token verification error:', error);
      return false;
    }
  }

  // Remove refresh token (logout)
  async removeRefreshToken(userId) {
    await this.ensureConnected();
    const key = `refresh_token:${userId}`;
    await this.redisClient.del(key);
  }

  // Generate and send OTP
  async sendOTP(user) {
    const otp = EmailService.generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Update user with OTP
    user.two_factor_code = otp;
    user.two_factor_expire = expiresAt;
    await user.save();

    // Send email
    await EmailService.sendOTP(user.email, otp);

    return { success: true, expiresAt };
  }

  // Verify OTP
  async verifyOTP(user, otp) {
    if (!user.two_factor_code || !user.two_factor_expire) {
      throw new Error('No OTP found');
    }

    if (new Date() > user.two_factor_expire) {
      throw new Error('OTP expired');
    }

    if (user.two_factor_code !== otp) {
      throw new Error('Invalid OTP');
    }

    // Clear OTP after successful verification
    user.two_factor_code = null;
    user.two_factor_expire = null;
    await user.save();

    return true;
  }

  // Refresh tokens (with rotation)
  async refreshTokens(userId, oldRefreshToken) {
    const isValid = await this.verifyRefreshToken(userId, oldRefreshToken);
    if (!isValid) {
      throw new Error('Invalid refresh token');
    }

    // Remove old refresh token
    await this.removeRefreshToken(userId);

    // Generate new tokens (pass through role and rememberMe from refresh token)
    const user = { id: userId, email: isValid.email, role: isValid.role };
    const rememberMe = !!isValid.rememberMe;
    const newAccessToken = this.generateAccessToken(user, rememberMe);
    const newRefreshToken = this.generateRefreshToken(user, rememberMe);

    // Store new refresh token
    await this.storeRefreshToken(userId, newRefreshToken, rememberMe);

    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    };
  }

  // Logout
  async logout(userId) {
    await this.removeRefreshToken(userId);
  }

  // Verify access token
  verifyAccessToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Invalid access token');
    }
  }
}

module.exports = new AuthService();
