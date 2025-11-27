# Odoo CORS Solution Guide

This guide explains how to solve CORS (Cross-Origin Resource Sharing) errors when connecting to Odoo from your Flutter web application.

## Understanding the Problem

When your Flutter web app tries to connect to Odoo, you may see errors like:
- `Access to fetch at '...' has been blocked by CORS policy`
- `Failed to fetch`
- `NetworkError`

This happens because browsers enforce CORS policies, and Odoo servers typically don't allow requests from other origins (domains).

## Solutions

### Solution 1: Use Proxy Server (Recommended for Web)

A proxy server sits between your Flutter app and Odoo, forwarding requests and adding CORS headers.

**Steps:**

1. **Start the proxy server:**
   ```bash
   cd odoo-proxy-server
   npm install
   npm start
   ```

2. **Configure in Flutter app:**
   - Open Admin Panel → Integration → Odoo Configuration
   - Enter your Odoo details
   - **Proxy Server URL**: `http://localhost:3000/api/odoo`
   - Click "Test & Connect"

3. **For production:**
   - Deploy the proxy server to a cloud service
   - Update the proxy URL to your production proxy URL

**Pros:**
- ✅ Works immediately
- ✅ No server-side configuration needed
- ✅ Can be deployed separately

**Cons:**
- ❌ Requires running an additional server
- ❌ Additional latency

---

### Solution 2: Configure CORS on Odoo Server (Best if You Have Access)

If you have access to your Odoo server configuration, you can allow CORS from your Flutter app domain.

**For Odoo.sh/odoo.com instances:**

Contact Odoo support to add your domain to the CORS whitelist.

**For self-hosted Odoo:**

Add CORS configuration to your Odoo instance. This typically involves:
1. Installing a CORS module
2. Configuring allowed origins

**Pros:**
- ✅ No proxy needed
- ✅ Direct connection
- ✅ Better performance

**Cons:**
- ❌ Requires server access
- ❌ May not be possible with Odoo.com instances

---

### Solution 3: Use Mobile/Desktop Builds (Workaround)

Flutter mobile and desktop apps don't have CORS restrictions.

**Steps:**

Instead of running on web, test on:
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Desktop
flutter run -d windows  # or macos, linux
```

**Pros:**
- ✅ No CORS issues
- ✅ Works immediately
- ✅ Good for testing

**Cons:**
- ❌ Not a solution for web deployment
- ❌ Different behavior than web

---

### Solution 4: Use Backend API (Advanced)

Create your own backend API that communicates with Odoo, and have your Flutter app communicate with your backend instead.

**Pros:**
- ✅ Full control
- ✅ Can add authentication, caching, etc.
- ✅ No CORS issues

**Cons:**
- ❌ Most complex solution
- ❌ Requires backend development

---

## Recommended Approach

### For Development:
Use **Solution 1 (Proxy Server)** - Quick and easy to set up locally.

### For Production:
1. **First choice**: **Solution 2 (Configure CORS)** - If you can get Odoo support to whitelist your domain
2. **Second choice**: **Solution 1 (Proxy Server)** - Deploy proxy server to production
3. **Last resort**: **Solution 3 (Mobile/Desktop)** - If web is not critical

## Quick Setup Guide

### Using the Included Proxy Server

1. **Install Node.js** (if not already installed):
   - Download from: https://nodejs.org/

2. **Start the proxy server:**
   ```bash
   cd odoo-proxy-server
   npm install
   npm start
   ```

3. **Configure in Flutter app:**
   - Go to Admin → Integration
   - Click "Configure" on Odoo card
   - Fill in:
     - Odoo Base URL: `https://house-of-sheelaa.odoo.com`
     - Database Name: `house-of-sheelaa`
     - API Key: Your API key
     - **Proxy Server URL**: `http://localhost:3000/api/odoo`
   - Click "Test & Connect"

4. **Verify connection:**
   - You should see "Successfully connected to Odoo!"
   - The connection status should show "Connected"

## Troubleshooting

### Proxy Server Won't Start

- **Check Node.js installation**: `node --version`
- **Check port availability**: Make sure port 3000 is not in use
- **Check firewall**: Ensure port 3000 is accessible

### Still Getting CORS Errors

1. **Verify proxy URL**: Make sure it matches exactly (no trailing slash)
2. **Check browser console**: Look for specific error messages
3. **Test proxy directly**: Visit `http://localhost:3000/health` in browser
4. **Clear browser cache**: Sometimes cached CORS errors persist

### Connection Works But Data Doesn't Load

- Check Odoo API permissions for your API key
- Verify database name matches exactly
- Check Odoo logs for errors

## Next Steps

Once connected to Odoo:
1. Services will sync automatically
2. Products and inventory will be available
3. Orders can be created in Odoo
4. Real-time sync between Flutter app and Odoo

## Support

If you continue to have issues:
1. Check the browser console for detailed error messages
2. Check proxy server logs for request/response details
3. Verify all URLs and credentials are correct
4. Try testing with Postman/curl to isolate the issue


