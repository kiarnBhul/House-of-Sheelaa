const fetch = globalThis.fetch || require('node-fetch');

exports.handler = async function(event, context) {
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

    const target = new URL('/jsonrpc', ODOO_BASE).toString();

    const reqHeaders = { 'Content-Type': 'application/json' };
    if (event.headers && event.headers.cookie) {
      reqHeaders['Cookie'] = event.headers.cookie;
    }

    // Forward the body (JSON-RPC payload)
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
    if (setCookie) headers['Set-Cookie'] = setCookie;

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
