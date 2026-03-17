const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

const uploadsDir = path.join(process.cwd(), 'uploads', 'profiles');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `profile-${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  },
});

const imageMimeTypes = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/heic',
  'image/heif',
  'application/octet-stream', // some clients send this for images
];
const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'];

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const ext = (path.extname(file.originalname) || '').toLowerCase();
    const isValidMime = imageMimeTypes.includes(file.mimetype);
    const isValidExt = imageExtensions.includes(ext);
    // Accept if mime is valid, or if octet-stream/unknown but extension is image
    if (isValidMime || (isValidExt && (!file.mimetype || file.mimetype === 'application/octet-stream'))) {
      cb(null, true);
    } else {
      console.log('[upload] Rejected mimetype:', file.mimetype, 'ext:', ext);
      cb(new Error('Invalid file type. Use JPEG, PNG, GIF or WebP.'), false);
    }
  },
});

router.post('/profile-image', upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }
    const protocol = req.get('x-forwarded-proto') || req.protocol || 'http';
    const host = req.get('x-forwarded-host') || req.get('host') || `localhost:${process.env.PORT || 3000}`;
    const url = `${protocol}://${host}/uploads/profiles/${req.file.filename}`;
    console.log('[upload/profile-image] Saved:', req.file.filename, '-> URL:', url.substring(0, 80) + '...');
    res.json({ url });
  } catch (error) {
    console.error('Profile image upload error:', error);
    res.status(500).json({ error: 'Upload failed' });
  }
});

module.exports = router;
