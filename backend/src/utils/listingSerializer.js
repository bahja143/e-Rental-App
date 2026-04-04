function parseJsonArray(value) {
  if (Array.isArray(value)) return value;
  if (typeof value !== 'string') return [];

  const trimmed = value.trim();
  if (!trimmed) return [];

  try {
    const parsed = JSON.parse(trimmed);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    return [];
  }
}

function normalizeListingMediaFields(rawListing) {
  if (!rawListing || typeof rawListing !== 'object') return rawListing;

  const listing =
    typeof rawListing.toJSON === 'function' ? rawListing.toJSON() : { ...rawListing };

  listing.images = parseJsonArray(listing.images);
  listing.videos = parseJsonArray(listing.videos);

  return listing;
}

function normalizeListingCollection(listings) {
  if (!Array.isArray(listings)) return [];
  return listings.map(normalizeListingMediaFields);
}

module.exports = {
  normalizeListingCollection,
  normalizeListingMediaFields,
  parseJsonArray,
};
