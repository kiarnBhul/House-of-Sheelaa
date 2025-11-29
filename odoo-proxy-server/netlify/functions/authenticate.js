const fetch = globalThis.fetch || require('node-fetch');

exports.handler = async function(event, context) {
  // Allow preflight
  const origin = event.headers.origin || event.headers.Origin || null;
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 204,
      headers: {
        'Access-Control-Allow-Origin': origin || '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Credentials': 'true',
      },
      body: '',
    };
  }

  try {
    const ODOO_BASE = process.env.ODOO_BASE_URL;
    if (!ODOO_BASE) {
      return { statusCode: 500, body: JSON.stringify({ error: 'Missing ODOO_BASE_URL env var' }) };
    }

    // Forward request body to Odoo authenticate endpoint
    const target = new URL('/web/session/authenticate', ODOO_BASE).toString();

    const reqHeaders = { 'Content-Type': 'application/json' };
    if (event.headers && event.headers.cookie) {
      reqHeaders['Cookie'] = event.headers.cookie;
    }

    const resp = await fetch(target, {
      method: 'POST',
      headers: reqHeaders,
      body: event.body,
    });

    const setCookie = resp.headers.get('set-cookie');
    const data = await resp.text();

    const headers = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': origin || '*',
      'Access-Control-Allow-Credentials': 'true',
    };
    if (setCookie) {
      // Forward cookie from Odoo to client
      headers['Set-Cookie'] = setCookie;
    }

    return {
      statusCode: resp.status,
      headers,
      body: data,
    };
  } catch (e) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: e.message || String(e) }),
    };
  }
};
