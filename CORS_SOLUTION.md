# CORS Error Solution for Flutter Web + Odoo

## Problem

When running your Flutter app on web (Chrome, Firefox, etc.), you may encounter:
```
ClientException: Failed to fetch
```

This is a **CORS (Cross-Origin Resource Sharing)** issue. Browsers block requests from `localhost` to external Odoo servers for security reasons.

## Why This Happens

- Flutter web runs in a browser
- Browsers enforce CORS policies
- Odoo.com servers don't allow requests from `localhost` by default
- This is a browser security feature, not a bug

## Solutions

### Solution 1: Test on Mobile/Desktop (Recommended for Development)

Instead of web, test on native platforms:

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

**Native apps don't have CORS restrictions!**

### Solution 2: Configure Odoo Server CORS (For Production)

If you have access to your Odoo server configuration, you can enable CORS:

#### For Odoo.com (Cloud Hosting)

Contact Odoo support to:
1. Add your domain to CORS whitelist
2. Enable API access from your domain
3. Configure CORS headers

#### For Self-Hosted Odoo

Add CORS configuration in your Odoo instance:

1. **Install CORS module** (if available)
2. **Or modify Odoo configuration** to add CORS headers:
   ```python
   # In Odoo configuration file
   cors = '*'
   # Or specific domains:
   # cors = 'https://yourdomain.com,https://localhost:8080'
   ```

3. **Or use Nginx/Apache reverse proxy** to add CORS headers:
   ```nginx
   # Nginx configuration
   add_header 'Access-Control-Allow-Origin' '*' always;
   add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
   add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
   ```

### Solution 3: Use Backend Proxy (Best for Production)

Create a backend server that acts as a proxy:

1. **Backend receives requests** from your Flutter web app
2. **Backend makes requests** to Odoo (no CORS restrictions)
3. **Backend returns data** to Flutter app

Example using Node.js/Express:

```javascript
// proxy-server.js
const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());

app.post('/api/odoo/authenticate', async (req, res) => {
  try {
    const response = await axios.post(
      'https://house-of-sheelaa.odoo.com/web/session/authenticate',
      req.body
    );
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Proxy server running on port 3000');
});
```

Then update your Flutter app to use:
```dart
final response = await http.post(
  Uri.parse('http://localhost:3000/api/odoo/authenticate'),
  // ... rest of code
);
```

### Solution 4: Use Odoo External API (If Available)

Some Odoo instances provide external API endpoints that have CORS enabled:

- Check if your Odoo instance has `/api/v1/` endpoints
- These might have different CORS settings
- Contact Odoo support to enable external API access

## Current Implementation

The app now:
1. ✅ Tries JSON-RPC endpoint first (better CORS support)
2. ✅ Detects CORS errors and shows helpful messages
3. ✅ Provides multiple authentication methods
4. ✅ Shows CORS warning in web builds

## Testing Without CORS Issues

For immediate testing without CORS:

1. **Use Flutter mobile/desktop builds** (no CORS)
2. **Or use Chrome with CORS disabled** (development only):
   ```bash
   # Windows
   chrome.exe --user-data-dir="C:/Chrome dev session" --disable-web-security --disable-features=VizDisplayCompositor

   # macOS
   open -na Google\ Chrome --args --user-data-dir=/tmp/chrome_dev --disable-web-security

   # Linux
   google-chrome --user-data-dir=/tmp/chrome_dev --disable-web-security
   ```

   ⚠️ **Warning**: Only use this for development! Never disable CORS in production.

## Recommended Approach

1. **Development**: Use mobile/desktop builds
2. **Production**: 
   - Configure Odoo CORS (if you have server access)
   - Or use a backend proxy server
   - Or deploy Flutter as a mobile app (no CORS issues)

## References

- [Odoo Flutter Forum Discussion](https://www.odoo.com/forum/help-1/flutter-using-odoo-api-166540)
- [Flutter Web CORS Issues](https://docs.flutter.dev/development/platform-integration/web)
- [MDN CORS Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)


