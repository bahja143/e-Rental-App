require('dotenv').config();
const db = require('../src/models');

const ADMIN_EMAIL = 'admin@rental.com';
const ADMIN_PASSWORD = 'Admin123!';
const ADMIN_NAME = 'Admin';

(async () => {
  try {
    const existing = await db.User.findOne({ where: { email: ADMIN_EMAIL } });
    if (existing) {
      console.log('Admin user already exists:', existing.email);
      process.exit(0);
      return;
    }

    const admin = await db.User.create({
      name: ADMIN_NAME,
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      role: 'admin',
    });

    console.log('Admin user created successfully:');
    console.log('  Email:', admin.email);
    console.log('  Password:', ADMIN_PASSWORD);
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
})();
