function normalizeBaseUrl(value) {
  if (!value || typeof value !== 'string') return '';
  return value.trim().replace(/\/+$/, '');
}

function getConfiguredPublicBaseUrl() {
  return normalizeBaseUrl(
    process.env.PUBLIC_BASE_URL ||
      process.env.APP_URL ||
      process.env.BASE_URL
  );
}

function getRequestPublicBaseUrl(req) {
  const protocol = req.get('x-forwarded-proto') || req.protocol || 'http';
  const host =
    req.get('x-forwarded-host') ||
    req.get('host') ||
    `localhost:${process.env.PORT || 3000}`;

  return normalizeBaseUrl(`${protocol}://${host}`);
}

function getPublicBaseUrl(req) {
  return getConfiguredPublicBaseUrl() || getRequestPublicBaseUrl(req);
}

function buildPublicUrl(req, pathname) {
  const cleanPath = pathname.startsWith('/') ? pathname : `/${pathname}`;
  return `${getPublicBaseUrl(req)}${cleanPath}`;
}

module.exports = {
  buildPublicUrl,
  getConfiguredPublicBaseUrl,
  getPublicBaseUrl,
};
