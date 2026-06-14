const crypto = require('crypto');

const trimEnv = (value) => (value ? String(value).trim().replace(/^["']|["']$/g, '') : '');

const safeAmount = (value) => Number(Number(value || 0).toFixed(2));

const normalizeSomaliPhone = (value) => {
  const phone = String(value || '').trim().replace(/[^\d+]/g, '');
  const withoutPlus = phone.replace(/^\+/, '');
  if (!/^2526\d{8}$/.test(withoutPlus)) {
    return null;
  }
  return withoutPlus;
};

const isApproved = (waafiResult) => {
  const responseCode = String(waafiResult?.responseCode || '');
  const state = String(waafiResult?.params?.state || '').toUpperCase();
  return (responseCode === '2001' || responseCode === '200') && (state === 'APPROVED' || state === 'SUCCESS');
};

const initiatePurchase = async ({
  amount,
  currency = 'USD',
  payerPhone,
  transactionRef,
  invoiceId,
  description,
  metadata = {},
}) => {
  const normalizedPhone = normalizeSomaliPhone(payerPhone);
  if (!normalizedPhone) {
    const error = new Error('Invalid phone number format. Use +2526XXXXXXXX or 2526XXXXXXXX.');
    error.statusCode = 400;
    throw error;
  }

  const apiKey = trimEnv(process.env.WAAFI_API_KEY || process.env.WAAFI_PAY_API_KEY);
  const merchantUid = trimEnv(process.env.WAAFI_MERCHANT_UID || process.env.WAAFI_PAY_CLIENT_ID);
  const apiUserId = trimEnv(process.env.WAAFI_API_USER_ID);
  const baseUrl = trimEnv(process.env.WAAFI_PAY_BASE_URL) || 'https://api.waafipay.com';

  if (process.env.WAAFI_PAY_MOCK === 'true' || (process.env.NODE_ENV === 'test' && !apiKey && !merchantUid)) {
    return {
      normalizedPhone,
      requestId: crypto.randomUUID(),
      payload: null,
      result: {
        responseCode: '2001',
        responseMsg: 'Mock approved',
        params: {
          state: 'APPROVED',
          description: 'Mock Waafi payment approved',
        },
      },
      approved: true,
    };
  }

  if (!apiKey || !merchantUid || !apiUserId) {
    const error = new Error('WaafiPay credentials are not configured.');
    error.statusCode = 503;
    throw error;
  }

  const requestId = crypto.randomUUID();
  const payload = {
    schemaVersion: '1.0',
    requestId,
    timestamp: new Date().toISOString(),
    channelName: 'WEB',
    serviceName: 'API_PURCHASE',
    serviceParams: {
      merchantUid,
      apiUserId,
      apiKey,
      paymentMethod: 'MWALLET_ACCOUNT',
      payerInfo: {
        accountNo: normalizedPhone,
        accountType: 'MERCHANT',
      },
      transactionInfo: {
        amount: safeAmount(amount).toFixed(2),
        currency,
        referenceId: transactionRef,
        invoiceId,
        description,
      },
      metadata,
    },
  };

  const response = await fetch(`${baseUrl}/asm`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  const result = await response.json();

  return {
    normalizedPhone,
    requestId,
    payload,
    result,
    approved: isApproved(result),
  };
};

module.exports = {
  initiatePurchase,
  normalizeSomaliPhone,
  safeAmount,
};
