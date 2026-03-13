const jwt = require('jsonwebtoken');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyLCJlbWFpbCI6InRlc3QudXNlckBleGFtcGxlLmNvbSIsImlhdCI6MTc2MTQ4NTM2NCwiZXhwIjoxNzYxNDg2MjY0fQ.OuKu6RZysX5DxNc3QQEiVsxNiDsnWGT-bB1dxajKEcI';
const secret = 'a_much_more_secure_secret';

try {
  const decoded = jwt.verify(token, secret);
  console.log(decoded);
} catch (error) {
  console.error(error);
}
