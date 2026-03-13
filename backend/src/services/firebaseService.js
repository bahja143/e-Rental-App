const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

let initialized = false;
let enabled = false;
let initError = null;

function resolveServiceAccount() {
  const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (rawJson && rawJson.trim()) {
    try {
      return JSON.parse(rawJson);
    } catch (error) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON');
    }
  }

  const rawPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!rawPath || !rawPath.trim()) {
    return null;
  }

  const serviceAccountPath = path.isAbsolute(rawPath)
    ? rawPath
    : path.resolve(process.cwd(), rawPath);
  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(`Firebase service account file not found at ${serviceAccountPath}`);
  }

  const content = fs.readFileSync(serviceAccountPath, 'utf8');
  return JSON.parse(content);
}

function ensureInitialized() {
  if (initialized) return;
  initialized = true;

  try {
    const serviceAccount = resolveServiceAccount();
    if (!serviceAccount) {
      enabled = false;
      return;
    }

    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    }
    enabled = true;
  } catch (error) {
    enabled = false;
    initError = error;
    console.error('Firebase Admin initialization failed:', error.message);
  }
}

function sanitizeData(input = {}) {
  const out = {};
  Object.entries(input || {}).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    out[String(key)] = typeof value === 'string' ? value : JSON.stringify(value);
  });
  return out;
}

function chunk(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

function isInvalidTokenError(code) {
  return code === 'messaging/invalid-registration-token' || code === 'messaging/registration-token-not-registered';
}

async function sendPushToTokens(tokens, { title, body, data = {} }) {
  ensureInitialized();

  if (!enabled) {
    return {
      enabled: false,
      sentCount: 0,
      failedCount: 0,
      invalidTokens: [],
      error: initError ? initError.message : 'Firebase not configured'
    };
  }

  const uniqueTokens = [...new Set((tokens || []).map((t) => `${t}`.trim()).filter(Boolean))];
  if (uniqueTokens.length === 0) {
    return { enabled: true, sentCount: 0, failedCount: 0, invalidTokens: [] };
  }

  const payloadData = sanitizeData(data);
  const groups = chunk(uniqueTokens, 500);
  let sentCount = 0;
  let failedCount = 0;
  const invalidTokens = [];

  for (const group of groups) {
    const response = await admin.messaging().sendEachForMulticast({
      tokens: group,
      notification: { title: title || '', body: body || '' },
      data: payloadData
    });

    sentCount += response.successCount;
    failedCount += response.failureCount;
    response.responses.forEach((res, index) => {
      if (!res.success && isInvalidTokenError(res.error?.code)) {
        invalidTokens.push(group[index]);
      }
    });
  }

  return { enabled: true, sentCount, failedCount, invalidTokens };
}

module.exports = {
  sendPushToTokens
};
