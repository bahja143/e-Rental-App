const mongoose = require('mongoose');

const listingConversationSchema = new mongoose.Schema({
  listing_id: {
    type: String,
    required: true
  },
  conversation_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true
  },
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }],
  created_at: {
    type: Date,
    default: Date.now
  }
});

// Indexes
listingConversationSchema.index({ listing_id: 1 });

module.exports = mongoose.model('ListingConversation', listingConversationSchema);
