const multer = require('multer');
// const keycdn = require('keycdn');
const { Queue } = require('bullmq');
const { redisClient } = require('../config/database');

// Configure KeyCDN
// const keycdnClient = new keycdn.KeyCDN({
//   apiKey: process.env.KEYCDN_API_KEY,
//   zoneId: process.env.KEYCDN_ZONE_ID
// });

// Multer configuration for memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'video/avi', 'video/mov'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  }
});

let mediaQueue;
if (redisClient) {
  mediaQueue = new Queue('media-processing', {
    connection: redisClient
  });
}

// Check if video sharing is enabled
const isVideoSharingEnabled = () => {
  return process.env.ENABLE_VIDEO_SHARING === 'true';
};

// Upload image to KeyCDN
const uploadImage = async (file) => {
  try {
    // Process image (resize, format) - KeyCDN handles this via API or transformations
    const result = await keycdnClient.upload(file.buffer, {
      filename: `chat-image-${Date.now()}-${file.originalname}`,
      folder: 'chat-images'
    });

    return {
      url: result.url,
      thumbnail: result.thumbnail || result.url // KeyCDN can generate thumbnails
    };
  } catch (error) {
    throw new Error(`Image upload failed: ${error.message}`);
  }
};

// Upload video to KeyCDN
const uploadVideo = async (file) => {
  if (!isVideoSharingEnabled()) {
    throw new Error('Video sharing is disabled');
  }

  try {
    // Process video (resize, format) - KeyCDN handles this
    const result = await keycdnClient.upload(file.buffer, {
      filename: `chat-video-${Date.now()}-${file.originalname}`,
      folder: 'chat-videos'
    });

    return {
      url: result.url,
      thumbnail: result.thumbnail || result.url
    };
  } catch (error) {
    throw new Error(`Video upload failed: ${error.message}`);
  }
};

// Process media upload asynchronously
const processMediaUpload = async (file, type) => {
  const job = await mediaQueue.add('process-media', {
    file: file.buffer,
    filename: file.originalname,
    type
  });

  return job.id;
};

// Worker function to process media (to be called in a separate worker file)
const processMediaJob = async (job) => {
  const { file, filename, type } = job.data;

  if (type === 'image') {
    return await uploadImage({ buffer: file, originalname: filename });
  } else if (type === 'video') {
    return await uploadVideo({ buffer: file, originalname: filename });
  } else {
    throw new Error('Unsupported media type');
  }
};

module.exports = {
  upload,
  uploadImage,
  uploadVideo,
  processMediaUpload,
  processMediaJob,
  isVideoSharingEnabled,
  mediaQueue
};
