const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { buildPublicUrl } = require('../utils/publicUrl');

const router = express.Router();

const profileUploadsDir = path.join(process.cwd(), 'uploads', 'profiles');
const listingUploadsDir = path.join(process.cwd(), 'uploads', 'listings');
for (const finalDir of [profileUploadsDir, listingUploadsDir]) {
  if (!fs.existsSync(finalDir)) {
    fs.mkdirSync(finalDir, { recursive: true });
  }
}

const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, profileUploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `profile-${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  },
});

const listingStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, listingUploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.bin';
    cb(null, `listing-${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
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
const videoMimeTypes = [
  'video/mp4',
  'video/quicktime',
  'video/webm',
  'video/x-msvideo',
  'application/octet-stream',
];
const videoExtensions = ['.mp4', '.mov', '.webm', '.avi'];

const upload = multer({
  storage: profileStorage,
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

const listingMediaUpload = multer({
  storage: listingStorage,
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ext = (path.extname(file.originalname) || '').toLowerCase();
    const isImage = imageMimeTypes.includes(file.mimetype) || (imageExtensions.includes(ext) && (!file.mimetype || file.mimetype === 'application/octet-stream'));
    const isVideo = videoMimeTypes.includes(file.mimetype) || (videoExtensions.includes(ext) && (!file.mimetype || file.mimetype === 'application/octet-stream'));
    if (isImage || isVideo) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Use an image or MP4/MOV/WebM/AVI video.'), false);
    }
  },
});

router.post('/profile-image', upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }
    const url = buildPublicUrl(req, `/uploads/profiles/${req.file.filename}`);
    console.log('[upload/profile-image] Saved:', req.file.filename, '-> URL:', url.substring(0, 80) + '...');
    res.json({ url });
  } catch (error) {
    console.error('Profile image upload error:', error);
    res.status(500).json({ error: 'Upload failed' });
  }
});

router.post('/listing-media', listingMediaUpload.single('media'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No media file provided' });
    }
    const url = buildPublicUrl(req, `/uploads/listings/${req.file.filename}`);
    const ext = (path.extname(req.file.originalname) || '').toLowerCase();
    const type = videoExtensions.includes(ext) || `${req.file.mimetype}`.startsWith('video/') ? 'video' : 'image';
    res.json({ url, type });
  } catch (error) {
    console.error('Listing media upload error:', error);
    res.status(500).json({ error: 'Upload failed' });
  }
});

module.exports = router;
