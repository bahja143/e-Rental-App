require('dotenv').config();

const mongoose = require('mongoose');
const db = require('../src/models');
const Conversation = require('../src/models/Conversation');
const Message = require('../src/models/Message');

const FIGMA_IMAGES = {
  brookvale: 'https://www.figma.com/api/mcp/asset/15855b80-c86c-4a44-8e3c-36edc38728ef',
  overdale: 'https://www.figma.com/api/mcp/asset/196009a7-dad1-47eb-a36b-015d44845b7a',
  flowerHeaven: 'https://www.figma.com/api/mcp/asset/287cbe40-257d-4858-9e2e-9a8c01de893a',
  dandelion: 'https://www.figma.com/api/mcp/asset/bde4e198-8bfa-4ef7-bb5e-3ae6c4a73592',
  bridgeland: 'https://www.figma.com/api/mcp/asset/e4dc8313-46ee-4d2c-b641-00417db80d6c',
  millSper: 'https://www.figma.com/api/mcp/asset/636ac4a4-a1a5-461a-8639-576a12397eae',
  bungalow: 'https://www.figma.com/api/mcp/asset/300aee5e-f567-4697-b22e-c21d4f650b05',
  avatarAmanda: 'https://www.figma.com/api/mcp/asset/654236e4-56ee-45ef-94a3-fd5669941a10',
};

const USER_SEEDS = [
  {
    name: 'Amanda',
    email: 'amanda.trust@email.com',
    phone: '+252611111111',
    password: 'Pass1234!',
    city: 'Jakarta',
    lat: -6.2088,
    lng: 106.8456,
    looking_for: 'sale',
    role: 'user',
    user_type: 'seller',
    profile_picture_url: FIGMA_IMAGES.avatarAmanda,
  },
  {
    name: 'Anderson',
    email: 'anderson.agent@email.com',
    phone: '+252611111112',
    password: 'Pass1234!',
    city: 'Bali',
    lat: -8.4095,
    lng: 115.1889,
    looking_for: 'sale',
    role: 'user',
    user_type: 'seller',
  },
  {
    name: 'Jonathan',
    email: 'jonathan@email.com',
    phone: '+252611111113',
    password: 'Pass1234!',
    city: 'Mogadishu',
    lat: 2.0469,
    lng: 45.3182,
    looking_for: 'rent',
    role: 'user',
    user_type: 'buyer',
  },
  {
    name: 'Sarah',
    email: 'sarah.client@email.com',
    phone: '+252611111114',
    password: 'Pass1234!',
    city: 'Semarang',
    lat: -6.9667,
    lng: 110.4167,
    looking_for: 'buy',
    role: 'user',
    user_type: 'buyer',
  },
];

const LOCATION_SEEDS = [
  { name: 'Jakarta, Indonesia', latitude: -6.2088, longitude: 106.8456, address: 'Jakarta, Indonesia' },
  { name: 'Bali, Indonesia', latitude: -8.4095, longitude: 115.1889, address: 'Bali, Indonesia' },
  { name: 'Semarang, Indonesia', latitude: -6.9667, longitude: 110.4167, address: 'Semarang, Indonesia' },
  { name: 'Mogadishu, Somalia', latitude: 2.0469, longitude: 45.3182, address: 'Mogadishu, Somalia' },
  { name: 'Yogyakarta, Indonesia', latitude: -7.7956, longitude: 110.3695, address: 'Yogyakarta, Indonesia' },
];

const LISTING_SEEDS = [
  {
    ownerEmail: 'amanda.trust@email.com',
    title: 'Brookvale Villa',
    lat: -6.1751,
    lng: 106.865,
    address: 'Central Jakarta, Indonesia',
    images: [FIGMA_IMAGES.brookvale],
    rent_price: 320,
    rent_type: 'monthly',
    description: 'Spacious modern villa with city access and premium facilities.',
    availability: '1',
  },
  {
    ownerEmail: 'anderson.agent@email.com',
    title: 'The Overdale Apartment',
    lat: -6.2146,
    lng: 106.8451,
    address: 'South Jakarta, Indonesia',
    images: [FIGMA_IMAGES.overdale],
    rent_price: 290,
    rent_type: 'monthly',
    description: 'High-rise apartment inspired by the Figma design sample.',
    availability: '1',
  },
  {
    ownerEmail: 'amanda.trust@email.com',
    title: 'Flower Heaven House',
    lat: -8.65,
    lng: 115.2167,
    address: 'Denpasar, Bali, Indonesia',
    images: [FIGMA_IMAGES.flowerHeaven],
    rent_price: 370,
    rent_type: 'monthly',
    description: 'Beautiful family house close to beach and local attractions.',
    availability: '1',
  },
  {
    ownerEmail: 'anderson.agent@email.com',
    title: 'Sky Dandelions Apartment',
    lat: -6.2,
    lng: 106.82,
    address: 'West Jakarta, Indonesia',
    images: [FIGMA_IMAGES.dandelion],
    rent_price: 290,
    rent_type: 'monthly',
    description: 'Popular apartment unit shown in featured Figma cards.',
    availability: '1',
  },
  {
    ownerEmail: 'anderson.agent@email.com',
    title: 'Bridgeland Modern House',
    lat: -6.978,
    lng: 110.412,
    address: 'Semarang, Indonesia',
    images: [FIGMA_IMAGES.bridgeland],
    rent_price: 260,
    rent_type: 'monthly',
    description: 'Modern architecture house with open-plan living spaces.',
    availability: '1',
  },
  {
    ownerEmail: 'amanda.trust@email.com',
    title: 'Mill Sper House',
    lat: -6.239,
    lng: 106.823,
    address: 'North Jakarta, Indonesia',
    images: [FIGMA_IMAGES.millSper],
    rent_price: 271,
    rent_type: 'monthly',
    description: 'Comfortable family home with balanced price and quality.',
    availability: '1',
  },
  {
    ownerEmail: 'anderson.agent@email.com',
    title: 'Bungalow House',
    lat: -6.181,
    lng: 106.828,
    address: 'Jakarta, Indonesia',
    images: [FIGMA_IMAGES.bungalow],
    rent_price: 235,
    rent_type: 'monthly',
    description: 'Simple and elegant bungalow for long-term rental.',
    availability: '1',
  },
];

const FAQ_SEEDS = [
  {
    title_en: 'How do I book a viewing?',
    title_so: 'Sideen u qabsan karaa booqasho?',
    description_en: 'Open the listing details, tap chat or booking, and select your preferred date and time.',
    description_so: 'Fur faahfaahinta guriga, guji chat ama booking, kadibna dooro taariikhda iyo waqtiga.',
    type: 'buyer',
  },
  {
    title_en: 'How can I list my property?',
    title_so: 'Sideen ku dari karaa gurigeyga?',
    description_en: 'Go to Add Property, complete location, photos, and details, then publish.',
    description_so: 'Tag Add Property, buuxi goobta, sawirrada, iyo faahfaahinta, kadibna daabac.',
    type: 'seller',
  },
  {
    title_en: 'When do I receive rental payments?',
    title_so: 'Goorma ayaan helayaa lacagta kirada?',
    description_en: 'Payments are released to your available balance after booking confirmation and settlement rules.',
    description_so: 'Lacagta waxaa lagu sii daayaa available balance-kaaga kadib xaqiijinta booking-ka.',
    type: 'seller',
  },
];

const PROPERTY_CATEGORY_SEEDS = [
  { name_en: 'Apartment', name_so: 'Apartment' },
  { name_en: 'Villa', name_so: 'Villa' },
  { name_en: 'House', name_so: 'House' },
  { name_en: 'Bungalow', name_so: 'Bungalow' },
];

const PROPERTY_FEATURE_SEEDS = [
  { name_en: 'Bedroom', name_so: 'Qol jiif', type: 'number' },
  { name_en: 'Bathroom', name_so: 'Musqul', type: 'number' },
  { name_en: 'Area', name_so: 'Baaxad', type: 'string' },
];

const FACILITY_SEEDS = [
  { name_en: 'Parking', name_so: 'Baarkin' },
  { name_en: 'Swimming Pool', name_so: 'Barkad dabaal' },
  { name_en: 'Garden', name_so: 'Beer' },
  { name_en: 'WiFi', name_so: 'WiFi' },
];

const NEARBY_PLACE_SEEDS = [
  { name_en: 'Hospital', name_so: 'Isbitaal' },
  { name_en: 'School', name_so: 'Dugsi' },
  { name_en: 'Bus Stop', name_so: 'Meesha baska' },
];

async function seedUsers() {
  const userMap = new Map();

  for (const seed of USER_SEEDS) {
    const [user] = await db.User.findOrCreate({
      where: { email: seed.email },
      defaults: seed,
    });

    await user.update({
      name: seed.name,
      city: seed.city,
      lat: seed.lat,
      lng: seed.lng,
      looking_for: seed.looking_for,
      role: seed.role,
      user_type: seed.user_type,
      profile_picture_url: seed.profile_picture_url || user.profile_picture_url,
      phone: seed.phone,
    });

    userMap.set(seed.email, user);
  }

  return userMap;
}

async function seedLocations() {
  for (const location of LOCATION_SEEDS) {
    await db.Location.findOrCreate({
      where: { name: location.name },
      defaults: location,
    });
  }
}

async function seedListings(userMap) {
  const listings = [];

  for (const seed of LISTING_SEEDS) {
    const owner = userMap.get(seed.ownerEmail);
    if (!owner) continue;

    const [listing] = await db.Listing.findOrCreate({
      where: {
        user_id: owner.id,
        title: seed.title,
      },
      defaults: {
        user_id: owner.id,
        title: seed.title,
        lat: seed.lat,
        lng: seed.lng,
        address: seed.address,
        images: seed.images,
        rent_price: seed.rent_price,
        rent_type: seed.rent_type,
        description: seed.description,
        availability: seed.availability,
      },
    });

    await listing.update({
      lat: seed.lat,
      lng: seed.lng,
      address: seed.address,
      images: seed.images,
      rent_price: seed.rent_price,
      rent_type: seed.rent_type,
      description: seed.description,
      availability: seed.availability,
    });

    listings.push(listing);
  }

  return listings;
}

async function seedListingMetadata(listings) {
  const categoryMap = new Map();
  for (const seed of PROPERTY_CATEGORY_SEEDS) {
    const [row] = await db.PropertyCategory.findOrCreate({
      where: { name_en: seed.name_en },
      defaults: seed,
    });
    categoryMap.set(seed.name_en, row);
  }

  const featureMap = new Map();
  for (const seed of PROPERTY_FEATURE_SEEDS) {
    const [row] = await db.PropertyFeatures.findOrCreate({
      where: { name_en: seed.name_en },
      defaults: seed,
    });
    featureMap.set(seed.name_en, row);
  }

  const facilityMap = new Map();
  for (const seed of FACILITY_SEEDS) {
    const [row] = await db.Facility.findOrCreate({
      where: { name_en: seed.name_en },
      defaults: seed,
    });
    facilityMap.set(seed.name_en, row);
  }

  const nearbyPlaceMap = new Map();
  for (const seed of NEARBY_PLACE_SEEDS) {
    const [row] = await db.NearbyPlace.findOrCreate({
      where: { name_en: seed.name_en },
      defaults: seed,
    });
    nearbyPlaceMap.set(seed.name_en, row);
  }

  for (const listing of listings) {
    const title = `${listing.title}`.toLowerCase();
    const categoryName = title.includes('villa')
      ? 'Villa'
      : title.includes('bungalow')
          ? 'Bungalow'
          : title.includes('house')
              ? 'House'
              : 'Apartment';
    const category = categoryMap.get(categoryName);
    if (category) {
      await db.ListingCategory.findOrCreate({
        where: {
          listing_id: listing.id,
          property_category_id: category.id,
        },
        defaults: {
          listing_id: listing.id,
          property_category_id: category.id,
        },
      });
    }

    const featureValues = [
      ['Bedroom', title.includes('villa') || title.includes('house') ? '4' : '2'],
      ['Bathroom', title.includes('villa') || title.includes('house') ? '3' : '2'],
      ['Area', title.includes('villa') ? '420 m2' : '180 m2'],
    ];
    for (const [featureName, value] of featureValues) {
      const feature = featureMap.get(featureName);
      if (!feature) continue;
      const [row] = await db.ListingFeature.findOrCreate({
        where: {
          listing_id: listing.id,
          property_feature_id: feature.id,
        },
        defaults: {
          listing_id: listing.id,
          property_feature_id: feature.id,
          value,
        },
      });
      if (row.value !== value) {
        await row.update({ value });
      }
    }

    for (const facilityName of ['Parking', 'WiFi', ...(title.includes('villa') ? ['Swimming Pool', 'Garden'] : [])]) {
      const facility = facilityMap.get(facilityName);
      if (!facility) continue;
      const [row] = await db.ListingFacility.findOrCreate({
        where: {
          listing_id: listing.id,
          facility_id: facility.id,
        },
        defaults: {
          listing_id: listing.id,
          facility_id: facility.id,
          value: 'Available',
        },
      });
      if (row.value !== 'Available') {
        await row.update({ value: 'Available' });
      }
    }

    for (const [placeName, value] of [['Hospital', '2 km'], ['School', '1.5 km'], ['Bus Stop', '300 m']]) {
      const place = nearbyPlaceMap.get(placeName);
      if (!place) continue;
      const [row] = await db.ListingPlace.findOrCreate({
        where: {
          listing_id: listing.id,
          nearby_place_id: place.id,
        },
        defaults: {
          listing_id: listing.id,
          nearby_place_id: place.id,
          value,
        },
      });
      if (row.value !== value) {
        await row.update({ value });
      }
    }
  }
}

async function seedFaqs() {
  for (const faq of FAQ_SEEDS) {
    const [row] = await db.Faq.findOrCreate({
      where: {
        title_en: faq.title_en,
        type: faq.type,
      },
      defaults: faq,
    });

    await row.update({
      title_so: faq.title_so,
      description_en: faq.description_en,
      description_so: faq.description_so,
    });
  }
}

async function seedReviewsAndFavourites(userMap, listings) {
  const jonathan = userMap.get('jonathan@email.com');
  const sarah = userMap.get('sarah.client@email.com');
  if (!jonathan || !sarah || listings.length === 0) return;

  // Favourites
  for (const listing of listings.slice(0, 4)) {
    await db.Favourite.findOrCreate({
      where: { user_id: jonathan.id, listing_id: listing.id },
      defaults: {
        user_id: jonathan.id,
        listing_id: listing.id,
      },
    });
  }

  // Listing reviews
  const reviewPayload = [
    { listing: listings[0], userId: sarah.id, rating: 5, comment: 'Great location and clean apartment.' },
    { listing: listings[1], userId: jonathan.id, rating: 4, comment: 'Nice view and smooth booking process.' },
    { listing: listings[2], userId: sarah.id, rating: 5, comment: 'Matches the app photos and has good facilities.' },
  ];

  for (const row of reviewPayload) {
    if (!row.listing) continue;
    await db.ListingReview.findOrCreate({
      where: {
        listing_id: row.listing.id,
        user_id: row.userId,
        comment: row.comment,
      },
      defaults: {
        listing_id: row.listing.id,
        user_id: row.userId,
        rating: row.rating,
        comment: row.comment,
        images: [],
      },
    });
  }
}

async function seedNotificationsAndSearches(userMap, listings) {
  const jonathan = userMap.get('jonathan@email.com');
  if (!jonathan) return;

  const notifications = [
    {
      type: 'message',
      title: 'New message from Amanda',
      message: 'Hi! I would like to schedule a viewing for Brookvale Villa.',
      data: { listingId: listings[0]?.id || null, sender: 'Amanda' },
      is_read: false,
    },
    {
      type: 'review',
      title: 'New review',
      message: 'Your recent booking received a 5-star review.',
      data: { rating: 5 },
      is_read: false,
    },
    {
      type: 'price_drop',
      title: 'Price drop',
      message: 'A saved property has dropped by \$50.',
      data: { listingId: listings[2]?.id || null },
      is_read: true,
    },
  ];

  for (const n of notifications) {
    await db.Notification.findOrCreate({
      where: {
        user_id: jonathan.id,
        title: n.title,
        type: n.type,
      },
      defaults: {
        user_id: jonathan.id,
        ...n,
      },
    });
  }

  await db.RecentSearch.destroy({
    where: {
      user_id: jonathan.id,
      search_text: ['Modern House', 'Jakarta, Indonesia', 'Bali villa'],
    },
  });

  await db.RecentSearch.bulkCreate([
    {
      user_id: jonathan.id,
      search_text: 'Modern House',
      latitude: -6.2088,
      longitude: 106.8456,
      radius: 10,
      created_at: new Date(),
    },
    {
      user_id: jonathan.id,
      search_text: 'Jakarta, Indonesia',
      latitude: -6.2088,
      longitude: 106.8456,
      radius: 25,
      created_at: new Date(),
    },
    {
      user_id: jonathan.id,
      search_text: 'Bali villa',
      latitude: -8.4095,
      longitude: 115.1889,
      radius: 40,
      created_at: new Date(),
    },
  ]);
}

async function seedTransactions(userMap, listings) {
  const jonathan = userMap.get('jonathan@email.com');
  const sarah = userMap.get('sarah.client@email.com');
  if (!jonathan || !sarah || listings.length < 2) return;

  const rentalListing = listings[0];
  const buyingListing = listings[1];

  await db.ListingRental.findOrCreate({
    where: {
      list_id: rentalListing.id,
      renter_id: jonathan.id,
      start_date: new Date('2026-04-01T00:00:00.000Z'),
    },
    defaults: {
      list_id: rentalListing.id,
      renter_id: jonathan.id,
      start_date: new Date('2026-04-01T00:00:00.000Z'),
      end_date: new Date('2026-05-01T00:00:00.000Z'),
      rent_type: 'monthly',
      status: 'confirmed',
      date: new Date(),
      subtotal: 320,
      discount: 0,
      total: 320,
      commission: 16,
      sellers_value: 304,
    },
  });

  await db.ListingBuying.findOrCreate({
    where: {
      listing_id: buyingListing.id,
      buyer_id: sarah.id,
      subtotal: 290,
    },
    defaults: {
      listing_id: buyingListing.id,
      buyer_id: sarah.id,
      subtotal: 290,
      discount: 0,
      total: 290,
      status: 'pending',
      commission: 14.5,
      sellers_value: 275.5,
    },
  });
}

async function seedMongoMessages() {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    console.log('MONGO_URI not set, skipping Mongo sample chat seed.');
    return;
  }

  await mongoose.connect(mongoUri);
  try {
    // Keep participant IDs stable across reruns for idempotent seed behavior.
    const participantA = '1';
    const participantB = '2';

    let conversation = await Conversation.findOne({ listing_id: 'figma-seed-listing-1' });
    if (!conversation) {
      conversation = await Conversation.create({
        participants: [participantA, participantB],
        listing_id: 'figma-seed-listing-1',
        last_message: {
          text: 'That would be great. How about tomorrow at 2pm?',
          type: 'text',
          created_at: new Date(),
        },
      });
    } else {
      conversation.participants = [participantA, participantB];
      conversation.last_message = {
        text: 'That would be great. How about tomorrow at 2pm?',
        type: 'text',
        created_at: new Date(),
      };
      await conversation.save();
    }

    const existing = await Message.countDocuments({ conversation_id: conversation._id });
    if (existing === 0) {
      await Message.insertMany([
        {
          conversation_id: conversation._id,
          sender_id: participantA,
          type: 'text',
          text: 'Hi! Is the apartment on 5th Street still available?',
          created_at: new Date(Date.now() - 1000 * 60 * 12),
        },
        {
          conversation_id: conversation._id,
          sender_id: participantB,
          type: 'text',
          text: 'Yes it is! Would you like to schedule a viewing?',
          created_at: new Date(Date.now() - 1000 * 60 * 8),
        },
        {
          conversation_id: conversation._id,
          sender_id: participantA,
          type: 'text',
          text: 'That would be great. How about tomorrow at 2pm?',
          created_at: new Date(Date.now() - 1000 * 60 * 5),
        },
      ]);
    }
  } finally {
    await mongoose.disconnect();
  }
}

async function run() {
  try {
    console.log('Seeding Figma-inspired sample data...');
    await db.sequelize.authenticate();

    const userMap = await seedUsers();
    await seedLocations();
    const listings = await seedListings(userMap);
    await seedListingMetadata(listings);
    await seedFaqs();
    await seedReviewsAndFavourites(userMap, listings);
    await seedNotificationsAndSearches(userMap, listings);
    await seedTransactions(userMap, listings);
    await seedMongoMessages();

    console.log('Sample data seed complete.');
    console.log('Users:', userMap.size);
    console.log('Listings:', listings.length);
  } catch (error) {
    console.error('Seed failed:', error);
    process.exitCode = 1;
  } finally {
    await db.sequelize.close();
  }
}

run();
