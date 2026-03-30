const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  conversation_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true
  },
  sender_id: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['text', 'image', 'video'],
    required: true
  },
  text: {
    type: String,
    default: null
  },
  media_url: {
    type: String,
    default: null
  },
  listing_snapshot: {
    id: mongoose.Schema.Types.ObjectId,
    title: String,
    price: Number,
    thumbnail: String
  },
  reply_to: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message',
    default: null
  },
  reactions: [{
    user_id: {
      type: String,
      required: true
    },
    emoji: {
      type: String,
      required: true
    }
  }],
  edited_at: Date,
  created_at: {
    type: Date,
    default: Date.now
  }
});

// Indexes
messageSchema.index({ conversation_id: 1, created_at: 1 });

module.exports = mongoose.model('Message', messageSchema);
