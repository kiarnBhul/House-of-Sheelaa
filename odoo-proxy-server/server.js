const express = require('express');
const app = express();
const cors = require('cors');
const helmet = require('helmet');
const { createProxyMiddleware } = require('http-proxy-middleware');

// Basic security headers (disable CSP to avoid blocking devtools/inline scripts)
app.use(helmet({ contentSecurityPolicy: false }));

// Enable CORS for all routes
app.use(cors({
  origin: true, // Allow all origins (you can restrict this in production)
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Odoo-Base-Url', 'Cookie'],
}));

// Body parser middleware - ORDER MATTERS!
// Parse text/xml BEFORE json to prevent express.json from corrupting XML
app.use(express.text({ type: 'text/xml' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => res.json({ ok: true }));

// Simple root route
app.get('/', (req, res) => {
  res.type('text/plain').send('Odoo Proxy Server is running. Use /api/odoo/* endpoints.');
});

// Proxy middleware for Odoo requests (both /api/odoo and direct paths)
app.use('/api/odoo', (req, res, next) => {
  // Fixed Odoo base URL for this deployment
  const odooBaseUrl = 'https://house-of-sheelaa.odoo.com';
  
  // Extract the path after /api/odoo
  const targetPath = req.originalUrl.replace('/api/odoo', '');
  const targetUrl = `${odooBaseUrl}${targetPath}`;

  console.log(`[Proxy] ${req.method} ${req.originalUrl} -> ${targetUrl}`);

  // Create proxy middleware for this request
  const proxy = createProxyMiddleware({
    target: odooBaseUrl,
    changeOrigin: true,
    pathRewrite: {
      '^/api/odoo': '', // Remove /api/odoo prefix
    },
    onProxyReq: (proxyReq, req, res) => {
      // Forward all headers except the X-Odoo-Base-Url (internal use only)
      Object.keys(req.headers).forEach((key) => {
        if (key !== 'x-odoo-base-url' && key !== 'host') {
          proxyReq.setHeader(key, req.headers[key]);
        }
      });
      
      // Set the target host
      const url = new URL(odooBaseUrl);
      proxyReq.setHeader('host', url.host);
      
      // Handle different content types
      if (req.body !== undefined && req.body !== null) {
        let bodyData;
        const contentType = req.headers['content-type'] || '';
        
        if (contentType.includes('text/xml') || contentType.includes('application/xml')) {
          // XML body - must be string
          bodyData = typeof req.body === 'string' ? req.body : String(req.body);
          console.log(`[Proxy] Forwarding XML body (${bodyData.length} bytes)`);
        } else if (typeof req.body === 'string') {
          // Other text body
          bodyData = req.body;
        } else {
          // JSON body
          bodyData = JSON.stringify(req.body);
        }
        
        proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
        proxyReq.write(bodyData);
      }
    },
    onProxyRes: (proxyRes, req, res) => {
      // Add CORS headers to response
      proxyRes.headers['Access-Control-Allow-Origin'] = req.headers.origin || '*';
      proxyRes.headers['Access-Control-Allow-Credentials'] = 'true';
      
      console.log(`[Proxy] Response: ${proxyRes.statusCode} for ${req.originalUrl}`);
    },
    onError: (err, req, res) => {
      console.error(`[Proxy Error] ${err.message}`);
      res.status(500).json({
        error: 'Proxy Error',
        message: err.message
      });
    },
  });

  proxy(req, res, next);
});

// Catch-all route: proxy all requests directly to Odoo (for /web/session/authenticate, /jsonrpc, etc)
app.use((req, res, next) => {
  const odooBaseUrl = 'https://house-of-sheelaa.odoo.com';
  const targetUrl = `${odooBaseUrl}${req.originalUrl}`;

  console.log(`[Proxy] ${req.method} ${req.originalUrl} -> ${targetUrl}`);

  // Create proxy middleware for this request
  const proxy = createProxyMiddleware({
    target: odooBaseUrl,
    changeOrigin: true,
    onProxyReq: (proxyReq, req, res) => {
      // Forward all headers except host
      Object.keys(req.headers).forEach((key) => {
        if (key !== 'host') {
          proxyReq.setHeader(key, req.headers[key]);
        }
      });
      
      // Set the target host
      const url = new URL(odooBaseUrl);
      proxyReq.setHeader('host', url.host);
      
      // Handle body forwarding
      if (req.body !== undefined && req.body !== null) {
        let bodyData;
        const contentType = req.headers['content-type'] || '';
        
        if (typeof req.body === 'string') {
          bodyData = req.body;
        } else {
          bodyData = JSON.stringify(req.body);
        }
        
        proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
        proxyReq.write(bodyData);
      }
    },
    onProxyRes: (proxyRes, req, res) => {
      // Add CORS headers to response
      proxyRes.headers['Access-Control-Allow-Origin'] = req.headers.origin || '*';
      proxyRes.headers['Access-Control-Allow-Credentials'] = 'true';
      
      console.log(`[Proxy] Response: ${proxyRes.statusCode} for ${req.originalUrl}`);
    },
    onError: (err, req, res) => {
      console.error(`[Proxy Error] ${err.message}`);
      res.status(500).json({
        error: 'Proxy Error',
        message: err.message
      });
    },
  });

  proxy(req, res, next);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('[Server Error]', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';
app.listen(PORT, HOST, () => {
  console.log(`odoo-proxy server listening on ${HOST}:${PORT}`);
});


