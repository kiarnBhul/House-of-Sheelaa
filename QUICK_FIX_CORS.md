# 🚨 Quick Fix for CORS Error - Step by Step

## Problem
You're seeing CORS errors even though you've configured a proxy URL. The requests are still going directly to Odoo instead of through the proxy.

## Root Cause
The proxy server is either:
1. ❌ Not running
2. ❌ Not accessible at the configured URL
3. ❌ Configuration not being saved/loaded correctly

## Solution: Use Proxy Server (Best for Your Case)

Since you're using **Odoo.com** (`house-of-sheelaa.odoo.com`), you **CANNOT** use:
- ❌ Method 1: Configure Odoo Controller Routes (no server access)
- ❌ Method 2: Configure Nginx/Apache (no server access)
- ✅ Method 3: Proxy Server (THIS IS YOUR ONLY OPTION)

---

## ✅ Step-by-Step Fix

### Step 1: Start the Proxy Server

**Open a NEW terminal window** (keep it running):

```bash
cd odoo-proxy-server
npm install
npm start
```

You should see:
```
🚀 Odoo Proxy Server running on http://localhost:3000
📡 Health check: http://localhost:3000/health
🔗 Proxy endpoint: http://localhost:3000/api/odoo/*
```

**⚠️ IMPORTANT: Keep this terminal window open!** The proxy server must be running.

### Step 2: Verify Proxy Server is Running

Open your browser and go to:
```
http://localhost:3000/health
```

You should see:
```json
{"status":"ok","message":"Odoo Proxy Server is running"}
```

If you see an error, the proxy server is not running properly.

### Step 3: Update Flutter App Configuration

1. **Open your Flutter app**
2. **Go to**: Admin Panel → Integration → Odoo Configuration
3. **Clear the form** and re-enter:

   - **Odoo Base URL**: `https://house-of-sheelaa.odoo.com`
   - **Database Name**: `house-of-sheelaa`
   - **Proxy Server URL**: `http://localhost:3000/api/odoo` ⚠️ **MUST match exactly**
   - **Authentication**: Choose one:
     - ✅ Use API Key (recommended)
     - OR Username/Password

4. **Click "Test & Connect"**

### Step 4: Check Browser Console

After clicking "Test & Connect", check the browser console. You should see:

**✅ GOOD (Using Proxy):**
```
[OdooConfig] Using proxy for authUrl: http://localhost:3000/api/odoo/web/session/authenticate
[OdooApiService] Using proxy: http://localhost:3000/api/odoo
```

**❌ BAD (Not Using Proxy):**
```
[OdooConfig] Using direct authUrl: https://house-of-sheelaa.odoo.com/web/session/authenticate
[OdooConfig] Using direct jsonRpcUrl: ... (proxyUrl: )
```

If you see "BAD", the proxy URL is not being saved/loaded.

### Step 5: If Proxy Still Not Working

**Try this debug checklist:**

1. ✅ **Is proxy server running?** Check terminal
2. ✅ **Is proxy URL correct?** Must be `http://localhost:3000/api/odoo` (no trailing slash)
3. ✅ **Is proxy accessible?** Visit `http://localhost:3000/health` in browser
4. ✅ **Clear browser cache** and refresh the Flutter app
5. ✅ **Check console logs** for `[OdooConfig]` messages

---

## 🔧 Alternative: Test Proxy Connection Manually

Open browser console on the Flutter app page and run:

```javascript
fetch('http://localhost:3000/health')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

Should return: `{status: "ok", ...}`

If this fails, the proxy server is not accessible.

---

## 📋 Configuration Checklist

- [ ] Node.js installed (`node --version`)
- [ ] Proxy server folder exists (`odoo-proxy-server/`)
- [ ] Dependencies installed (`npm install` completed)
- [ ] Proxy server running (terminal shows "running on port 3000")
- [ ] Proxy health check works (`http://localhost:3000/health`)
- [ ] Flutter app proxy URL set to `http://localhost:3000/api/odoo`
- [ ] Browser console shows proxy is being used

---

## 🎯 Expected Behavior

**When working correctly:**

1. Flutter app sends request to: `http://localhost:3000/api/odoo/web/session/authenticate`
2. Proxy server receives request
3. Proxy forwards to: `https://house-of-sheelaa.odoo.com/web/session/authenticate`
4. Odoo responds
5. Proxy adds CORS headers and returns to Flutter app
6. ✅ **No CORS errors!**

---

## 🚀 Production Deployment

Once it works locally, for production:

1. Deploy proxy server to a cloud service (Heroku, Vercel, AWS, etc.)
2. Update proxy URL in Flutter app to production proxy URL
3. Configure CORS on proxy server to allow your production domain

---

## ❓ Still Having Issues?

1. **Check proxy server logs** - terminal will show all requests
2. **Check browser Network tab** - see where requests are actually going
3. **Verify Odoo credentials** - API key or username/password must be correct
4. **Try with different browser** - sometimes cached CORS errors persist

---

## 💡 Why This Works

- Browser blocks direct requests to Odoo (CORS)
- Proxy server runs outside browser (no CORS restrictions)
- Proxy forwards requests and adds CORS headers
- Browser accepts responses from proxy ✅


