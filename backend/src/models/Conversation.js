const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  participants: [{
    type: String,
    required: true
  }],
  listing_id: {
    type: String,
    default: null
  },
  last_message: {
    text: String,
    type: {
      type: String,
      enum: ['text', 'image', 'video']
    },
    created_at: Date
  },
  unread_counts: {
    type: Map,
    of: Number,
    default: {}
  },
  created_at: {
    type: Date,
    default: Date.now
  },
  updated_at: {
    type: Date,
    default: Date.now
  }
});

// Indexes
conversationSchema.index({ participants: 1 });
conversationSchema.index({ listing_id: 1 });

// Update updated_at on save
conversationSchema.pre('save', function(next) {
  this.updated_at = new Date();
  next();
});

module.exports = mongoose.model('Conversation', conversationSchema);
