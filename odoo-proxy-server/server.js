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

// Track server start time
const serverStartTime = new Date();
let requestCount = 0;
let lastRequestTime = new Date();

// Enhanced health check endpoint with server stats
app.get('/health', (req, res) => {
  const uptime = Math.floor((new Date() - serverStartTime) / 1000);
  const timeSinceLastRequest = Math.floor((new Date() - lastRequestTime) / 1000);
  
  res.json({ 
    ok: true,
    status: 'healthy',
    uptime: `${uptime}s`,
    requests: requestCount,
    lastRequest: `${timeSinceLastRequest}s ago`,
    timestamp: new Date().toISOString(),
    message: 'Proxy server is awake and ready'
  });
});

// Middleware to track requests
app.use((req, res, next) => {
  requestCount++;
  lastRequestTime = new Date();
  next();
});

// Simple root route
app.get('/', (req, res) => {
  const uptime = Math.floor((new Date() - serverStartTime) / 1000);
  res.type('text/html').send(`
    <html>
      <head><title>Odoo Proxy Server</title></head>
      <body style="font-family: system-ui; padding: 2rem; max-width: 800px; margin: 0 auto;">
        <h1>🔄 Odoo Proxy Server</h1>
        <p>Server is running and ready to handle requests.</p>
        <ul>
          <li><strong>Status:</strong> ✅ Healthy</li>
          <li><strong>Uptime:</strong> ${uptime}s</li>
          <li><strong>Requests handled:</strong> ${requestCount}</li>
          <li><strong>Target:</strong> https://house-of-sheelaa.odoo.com</li>
        </ul>
        <p><a href="/health">Health Check</a></p>
      </body>
    </html>
  `);
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
const server = app.listen(PORT, HOST, () => {
  console.log(`✅ Odoo proxy server listening on ${HOST}:${PORT}`);
  console.log(`🎯 Target: https://house-of-sheelaa.odoo.com`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
  
  // Self-ping keep-alive mechanism for Render.com free tier
  // Ping every 5 minutes to prevent cold starts (Render sleeps after 15 min inactivity)
  // Using 5 min instead of 10 min for safety margin
  if (process.env.RENDER) {
    console.log('📡 Render.com detected - enabling keep-alive ping');
    const KEEP_ALIVE_INTERVAL = 5 * 60 * 1000; // 5 minutes
    
    // Get the public Render URL from environment or construct it
    const renderUrl = process.env.RENDER_EXTERNAL_URL || `https://house-of-sheelaa-proxy-server.onrender.com`;
    console.log(`🔄 Keep-alive will ping: ${renderUrl}/health every 5 minutes`);
    console.log(`⏰ Render free tier sleeps after 15 min - 5 min interval keeps it awake`);
    
    setInterval(async () => {
      try {
        const https = require('https');
        const url = new URL(`${renderUrl}/health`);
        
        const options = {
          hostname: url.hostname,
          port: url.port || 443,
          path: url.pathname,
          method: 'GET',
          timeout: 10000,
        };
        
        const req = https.request(options, (res) => {
          console.log(`🔄 Keep-alive ping successful (status: ${res.statusCode}) - ${new Date().toISOString()}`);
          res.on('data', () => {}); // Consume response data
        });
        
        req.on('error', (error) => {
          console.error(`❌ Keep-alive ping failed: ${error.message}`);
        });
        
        req.on('timeout', () => {
          console.error(`⏱️ Keep-alive ping timeout`);
          req.destroy();
        });
        
        req.end();
      } catch (error) {
        console.error(`❌ Keep-alive error: ${error.message}`);
      }
    }, KEEP_ALIVE_INTERVAL);
    
    // Perform first keep-alive ping immediately on startup
    console.log('🔍 Performing immediate initial keep-alive test...');
    setTimeout(async () => {
      try {
        const https = require('https');
        const url = new URL(`${renderUrl}/health`);
        
        const req = https.request({
          hostname: url.hostname,
          port: url.port || 443,
          path: url.pathname,
          method: 'GET',
          timeout: 10000,
        }, (res) => {
          console.log(`✅ Initial keep-alive test successful - Server is accessible at ${renderUrl}`);
          console.log(`💚 Keep-alive monitoring active - server will stay awake 24/7`);
        });
        
        req.on('error', (error) => {
          console.error(`❌ Initial keep-alive test failed: ${error.message}`);
          console.error(`⚠️ Server may sleep after 15 minutes without external requests`);
        });
        
        req.end();
      } catch (error) {
        console.error(`❌ Initial keep-alive error: ${error.message}`);
      }
    }, 5000); // 5 seconds - quick initial test
  }
});


