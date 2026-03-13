const nodemailer = require('nodemailer');

// Create transporter (configure with your email service)
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || 'smtp.gmail.com',
  port: process.env.EMAIL_PORT || 587,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

class EmailService {
  static async sendOTP(email, otp) {
    try {
      // const mailOptions = {
      //   from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
      //   to: email,
      //   subject: 'Your OTP for Hantario Login',
      //   html: `
      //     <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      //       <h2 style="color: #333;">Hantario Login Verification</h2>
      //       <p>Hello,</p>
      //       <p>Your One-Time Password (OTP) for logging into Hantario is:</p>
      //       <div style="background-color: #f8f9fa; padding: 20px; text-align: center; margin: 20px 0;">
      //         <span style="font-size: 24px; font-weight: bold; color: #007bff;">${otp}</span>
      //       </div>
      //       <p>This OTP will expire in 10 minutes.</p>
      //       <p>If you didn't request this, please ignore this email.</p>
      //       <p>Best regards,<br>Hantario Team</p>
      //     </div>
      //   `,
      // };

      // const info = await transporter.sendMail(mailOptions);
      // console.log('OTP email sent:', info.messageId);
      
      console.log(`OTP for ${email}: ${otp}`);
      return { success: true, messageId: 'mock-message-id' };
    } catch (error) {
      console.error('Error sending OTP email:', error);
      throw new Error('Failed to send OTP email');
    }
  }

  static generateOTP() {
    // Generate 4-digit OTP
    return Math.floor(1000 + Math.random() * 9000).toString();
  }
}

module.exports = EmailService;
