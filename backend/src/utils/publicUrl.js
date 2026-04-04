function normalizeBaseUrl(value) {
  if (!value || typeof value !== 'string') return '';
  return value.trim().replace(/\/+$/, '');
}

function getHostname(value) {
  try {
    return new URL(value).hostname || '';
  } catch (error) {
    return '';
  }
}

function isPrivateHostname(hostname) {
  const host = String(hostname || '').trim().toLowerCase();
  if (!host) return true;
  if (host === 'localhost' || host === '::1') return true;
  if (host.startsWith('127.')) return true;
  if (host.startsWith('10.')) return true;
  if (host.startsWith('192.168.')) return true;
  if (/^172\.(1[6-9]|2\d|3[0-1])\./.test(host)) return true;
  return false;
}

function getConfiguredPublicBaseUrl() {
  return normalizeBaseUrl(
    process.env.PUBLIC_BASE_URL ||
      process.env.APP_URL ||
      process.env.BASE_URL
  );
}

function getRequestPublicBaseUrl(req) {
  const protocol = (req.get('x-forwarded-proto') || req.protocol || 'http')
    .split(',')[0]
    .trim();
  const forwardedPort = (req.get('x-forwarded-port') || '')
    .split(',')[0]
    .trim();
  let host =
    (req.get('x-forwarded-host') || req.get('host') || '')
      .split(',')[0]
      .trim() ||
    `localhost:${process.env.PORT || 3000}`;

  const hasExplicitPort = host.includes(':');
  const isDefaultPort =
    (protocol === 'http' && forwardedPort === '80') ||
    (protocol === 'https' && forwardedPort === '443');

  if (forwardedPort && !hasExplicitPort && !isDefaultPort) {
    host = `${host}:${forwardedPort}`;
  }

  return normalizeBaseUrl(`${protocol}://${host}`);
}

function getPublicBaseUrl(req) {
  const requestBaseUrl = getRequestPublicBaseUrl(req);
  const configuredBaseUrl = getConfiguredPublicBaseUrl();

  if (!configuredBaseUrl) return requestBaseUrl;
  if (!requestBaseUrl) return configuredBaseUrl;

  const requestHostname = getHostname(requestBaseUrl);
  if (requestHostname && !isPrivateHostname(requestHostname)) {
    return requestBaseUrl;
  }

  return configuredBaseUrl;
}

function buildPublicUrl(req, pathname) {
  const cleanPath = pathname.startsWith('/') ? pathname : `/${pathname}`;
  return `${getPublicBaseUrl(req)}${cleanPath}`;
}

function rewritePublicUploadUrl(req, value) {
  if (typeof value !== 'string') return value;

  const trimmedValue = value.trim();
  if (!trimmedValue) return value;

  if (trimmedValue.startsWith('[') || trimmedValue.startsWith('{')) {
    try {
      const parsedValue = JSON.parse(trimmedValue);
      const normalizedValue = rewritePublicUploadUrlsDeep(req, parsedValue);
      return JSON.stringify(normalizedValue);
    } catch (error) {
      // Fall through and treat the value as a regular string.
    }
  }

  if (trimmedValue.startsWith('/uploads/')) {
    return buildPublicUrl(req, trimmedValue);
  }

  try {
    const parsed = new URL(trimmedValue);
    if (!parsed.pathname.startsWith('/uploads/')) {
      return value;
    }

    const rewrittenBaseUrl = getPublicBaseUrl(req);
    return `${rewrittenBaseUrl}${parsed.pathname}${parsed.search}${parsed.hash}`;
  } catch (error) {
    return value;
  }
}

function rewritePublicUploadUrlsDeep(req, value, seen = new WeakSet()) {
  if (typeof value === 'string') {
    return rewritePublicUploadUrl(req, value);
  }

  if (Array.isArray(value)) {
    return value.map((item) => rewritePublicUploadUrlsDeep(req, item, seen));
  }

  if (!value || typeof value !== 'object') {
    return value;
  }

  if (value instanceof Date) {
    return value;
  }

  const source = typeof value.toJSON === 'function' ? value.toJSON() : value;
  if (!source || typeof source !== 'object') {
    return source;
  }

  if (seen.has(source)) {
    return source;
  }
  seen.add(source);

  const normalized = {};
  for (const [key, childValue] of Object.entries(source)) {
    normalized[key] = rewritePublicUploadUrlsDeep(req, childValue, seen);
  }
  return normalized;
}

module.exports = {
  buildPublicUrl,
  getConfiguredPublicBaseUrl,
  getPublicBaseUrl,
  rewritePublicUploadUrl,
  rewritePublicUploadUrlsDeep,
};
