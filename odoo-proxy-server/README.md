# Odoo Proxy Server

A CORS proxy server to enable Flutter web apps to communicate with Odoo ERP without CORS restrictions.

## Why This Is Needed

Flutter web applications run in the browser and are subject to CORS (Cross-Origin Resource Sharing) policies. Odoo servers typically don't allow cross-origin requests from web browsers, causing "Failed to fetch" errors.

This proxy server sits between your Flutter web app and Odoo, forwarding requests and adding the necessary CORS headers.

## Quick Start

### 1. Install Dependencies

```bash
cd odoo-proxy-server
npm install
```

### 2. Start the Server

```bash
npm start
```

Or for development with auto-reload:

```bash
npm run dev
```

The server will start on `http://localhost:3000` by default.

### 3. Configure in Flutter App

1. Open your Flutter app's Odoo configuration screen
2. Enter your Odoo details:
   - **Odoo Base URL**: `https://house-of-sheelaa.odoo.com`
   - **Database Name**: `house-of-sheelaa`
   - **API Key**: Your Odoo API key
3. **Proxy Server URL**: `http://localhost:3000/api/odoo`
4. Click "Test & Connect"

## Configuration

### Environment Variables

You can set these optional environment variables:

- `PORT`: Server port (default: 3000)
- `ODOO_BASE_URL`: Default Odoo URL (optional, can be sent via header)

```bash
PORT=3000 ODOO_BASE_URL=https://your-odoo.com npm start
```

### CORS Configuration

The server allows requests from any origin by default. For production, you should restrict this:

Edit `server.js` and modify the CORS configuration:

```javascript
app.use(cors({
  origin: 'https://your-flutter-app-domain.com', // Your Flutter web app URL
  credentials: true,
  // ...
}));
```

## Production Deployment

### Option 1: Deploy to a VPS/Cloud Server

1. Upload the `odoo-proxy-server` folder to your server
2. Install Node.js and npm
3. Install dependencies: `npm install`
4. Use PM2 or similar to keep it running:
   ```bash
   npm install -g pm2
   pm2 start server.js --name odoo-proxy
   pm2 save
   pm2 startup
   ```

### Option 2: Deploy to Heroku

1. Create a Heroku app
2. Set environment variables if needed
3. Deploy:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   heroku create your-app-name
   git push heroku main
   ```

### Option 3: Use a Serverless Function

You can deploy this as a serverless function on platforms like:
- Vercel
- Netlify Functions
- AWS Lambda
- Google Cloud Functions

## How It Works

1. Flutter app sends request to proxy: `POST http://localhost:3000/api/odoo/web/session/authenticate`
2. Proxy reads the `X-Odoo-Base-Url` header from the request
3. Proxy forwards the request to the actual Odoo server
4. Proxy adds CORS headers to the response
5. Browser receives the response with proper CORS headers

## Security Considerations

⚠️ **Important for Production:**

1. **Restrict CORS origins** to only your Flutter web app domain
2. **Use HTTPS** in production (use a reverse proxy like nginx)
3. **Add authentication** if needed (API keys, tokens)
4. **Rate limiting** to prevent abuse
5. **Request validation** to ensure only valid Odoo requests pass through

## Troubleshooting

### Connection Refused

- Make sure the proxy server is running
- Check if the port is correct
- Verify firewall settings

### CORS Errors Still Occurring

- Check browser console for specific error
- Verify the proxy URL in Flutter app matches the server URL
- Ensure CORS headers are being added (check Network tab in DevTools)

### 400 Bad Request: Odoo Base URL not provided

- Make sure you've entered the Odoo Base URL in your Flutter app
- The Flutter app automatically sends it in the `X-Odoo-Base-Url` header

## Alternative Solutions

If you don't want to run a proxy server:

1. **Configure CORS on Odoo server** (if you have server access)
2. **Use mobile/desktop builds** instead of web (they don't have CORS restrictions)
3. **Use Odoo's External API** if available

## License

MIT


