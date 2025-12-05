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

// Body parser middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => res.json({ ok: true }));

// Simple root route
app.get('/', (req, res) => {
  res.type('text/html').send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>House of Sheelaa - Odoo Proxy Server</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
          background: white;
          padding: 40px;
          border-radius: 10px;
          box-shadow: 0 10px 25px rgba(0,0,0,0.2);
          text-align: center;
        }
        h1 { color: #333; margin: 0 0 10px 0; }
        p { color: #666; margin: 10px 0; }
        .status { color: #4CAF50; font-weight: bold; font-size: 18px; }
        .endpoints {
          text-align: left;
          background: #f5f5f5;
          padding: 20px;
          border-radius: 5px;
          margin-top: 20px;
        }
        .endpoints h3 { margin-top: 0; }
        code { background: #ddd; padding: 2px 6px; border-radius: 3px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🔗 House of Sheelaa Proxy Server</h1>
        <p class="status">✓ Proxy Server is Running</p>
        <p>This server handles CORS-enabled requests to your Odoo instance.</p>
        
        <div class="endpoints">
          <h3>Available Endpoints:</h3>
          <p><code>/health</code> - Health check</p>
          <p><code>/api/odoo/*</code> - All Odoo API requests (proxied to your Odoo server)</p>
          <p><strong>Required Header:</strong> <code>X-Odoo-Base-Url</code> (your Odoo server URL)</p>
        </div>
        
        <p style="margin-top: 20px; font-size: 12px; color: #999;">
          For use with House of Sheelaa Flutter Application
        </p>
      </div>
    </body>
    </html>
  `);
});

// Proxy middleware for Odoo requests (MUST be before catch-all)
app.use('/api/odoo', (req, res, next) => {
  // Get the actual Odoo base URL from header or environment variable
  const odooBaseUrl = req.headers['x-odoo-base-url'] || process.env.ODOO_BASE_URL;
  
  if (!odooBaseUrl) {
    return res.status(400).json({
      error: 'Odoo Base URL not provided',
      message: 'Please provide X-Odoo-Base-Url header or set ODOO_BASE_URL environment variable'
    });
  }

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
      
      // Log the request
      if (req.body) {
        const bodyData = JSON.stringify(req.body);
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

// Catch-all route for undefined endpoints (MUST be last)
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Endpoint ${req.originalUrl} does not exist`,
    hint: 'Use /api/odoo/* for Odoo API requests. Visit / for documentation.',
  });
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


