/**
 * Extract user-friendly error message from API rejection.
 * authAxios rejects with error.response?.data (object like { error: 'msg' }) or string.
 */
export const getApiErrorMessage = (err, fallback = 'Request failed') => {
  if (!err) return fallback;
  if (typeof err === 'string') return err;
  if (err?.error && typeof err.error === 'string') return err.error;
  if (err?.message) return err.message;
  return fallback;
};
