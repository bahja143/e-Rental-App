const path = require('path');
const fs = require('fs/promises');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const db = require('../src/models');
const { parseJsonArray } = require('../src/utils/listingSerializer');

const SOURCE_DIR = path.resolve(__dirname, '..', 'listing_images');
const LEGACY_UPLOADS_DIR = path.resolve(__dirname, '..', 'uploads', 'listings');
const IMAGE_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif']);
const MIN_IMAGES_PER_LISTING = 3;
const MAX_IMAGES_PER_LISTING = 5;

function isImageFile(filename) {
  return IMAGE_EXTENSIONS.has(path.extname(filename).toLowerCase());
}

function createSeededRandom(seed) {
  let state = (Number(seed) || 1) >>> 0;
  return () => {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 0x100000000;
  };
}

function pickListingImages(sourceImages, listingId) {
  const desiredCount =
    MIN_IMAGES_PER_LISTING +
    (Math.abs(Number(listingId) || 0) % (MAX_IMAGES_PER_LISTING - MIN_IMAGES_PER_LISTING + 1));

  const available = [...sourceImages];
  const random = createSeededRandom(listingId);

  for (let index = available.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(random() * (index + 1));
    [available[index], available[swapIndex]] = [available[swapIndex], available[index]];
  }

  return available
    .slice(0, Math.min(desiredCount, available.length))
    .map((filename) => `/listing-images/${encodeURIComponent(filename)}`);
}

function extractLegacyUploadFilename(value) {
  if (typeof value !== 'string') return null;

  const trimmed = value.trim();
  if (!trimmed) return null;

  let pathname = trimmed;
  if (!pathname.startsWith('/')) {
    try {
      pathname = new URL(trimmed).pathname;
    } catch (error) {
      return null;
    }
  }

  if (!pathname.startsWith('/uploads/listings/')) return null;

  const filename = decodeURIComponent(path.basename(pathname));
  return isImageFile(filename) ? filename : null;
}

async function getSourceImages() {
  const entries = await fs.readdir(SOURCE_DIR, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && isImageFile(entry.name))
    .map((entry) => entry.name)
    .sort((left, right) => left.localeCompare(right));
}

async function deleteLegacyImages(filenames) {
  let deletedCount = 0;

  for (const filename of filenames) {
    const absolutePath = path.join(LEGACY_UPLOADS_DIR, filename);
    try {
      await fs.unlink(absolutePath);
      deletedCount += 1;
    } catch (error) {
      if (error.code !== 'ENOENT') {
        console.warn(`Failed to delete legacy listing image: ${filename}`, error.message);
      }
    }
  }

  return deletedCount;
}

async function run() {
  const sourceImages = await getSourceImages();
  if (sourceImages.length < MIN_IMAGES_PER_LISTING) {
    throw new Error(
      `Need at least ${MIN_IMAGES_PER_LISTING} source images in ${SOURCE_DIR}, found ${sourceImages.length}`
    );
  }

  await db.sequelize.authenticate();

  const listings = await db.Listing.findAll({
    attributes: ['id', 'images'],
    order: [['id', 'ASC']],
  });

  const legacyUploadFilenames = new Set();
  let updatedListings = 0;

  for (const listing of listings) {
    const currentImages = parseJsonArray(listing.images).filter((value) => typeof value === 'string');
    for (const image of currentImages) {
      const filename = extractLegacyUploadFilename(image);
      if (filename) {
        legacyUploadFilenames.add(filename);
      }
    }

    const replacementImages = pickListingImages(sourceImages, listing.id);
    if (JSON.stringify(currentImages) === JSON.stringify(replacementImages)) {
      continue;
    }

    await listing.update({ images: replacementImages }, { fields: ['images'] });
    updatedListings += 1;
  }

  const deletedLegacyImages = await deleteLegacyImages(legacyUploadFilenames);

  console.log(
    JSON.stringify(
      {
        totalListings: listings.length,
        updatedListings,
        sourceImagePool: sourceImages.length,
        deletedLegacyImages,
      },
      null,
      2
    )
  );
}

run()
  .catch((error) => {
    console.error('Failed to reassign listing images:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await db.sequelize.close();
  });
