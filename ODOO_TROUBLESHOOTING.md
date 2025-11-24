# Odoo Connection Troubleshooting Guide

## Common Authentication Errors

### Error: "Authentication failed: Please check your API key or credentials"

This error can occur for several reasons. Follow these steps:

### Step 1: Check Your Odoo URL Format

**For Odoo.com instances:**
- ✅ Correct: `https://house-of-sheelaa.odoo.com`
- ❌ Wrong: `https://house-of-sheelaa.odoo.com/odoo`

**The app automatically removes `/odoo` suffix**, but make sure your base URL is:
- `https://house-of-sheelaa.odoo.com` (without `/odoo` at the end)

### Step 2: Verify Database Name

- Database name must match **exactly** (case-sensitive)
- For Odoo.com: Usually the same as your instance name
- Example: If URL is `house-of-sheelaa.odoo.com`, database is likely `house-of-sheelaa`

### Step 3: API Key Authentication Methods

The app tries multiple authentication methods automatically:

1. **Database name as username** (most common for Odoo.com)
   - Username: `house-of-sheelaa`
   - Password: Your API key

2. **Admin username**
   - Username: `admin`
   - Password: Your API key

3. **API username**
   - Username: `api`
   - Password: Your API key

4. **JSON-RPC method**
   - Direct RPC authentication

### Step 4: Verify API Key in Odoo

1. **Log into Odoo Admin Panel**
2. **Go to Settings → Users & Companies → Users**
3. **Find your user or create an API user**
4. **Go to API Keys section**
5. **Verify the API key matches**: `02aad5fe3af89ccca6d120ae6223f0278d683017`

### Step 5: Check API Key Permissions

Your API key user needs:
- ✅ Access to Products module
- ✅ Read permissions for `product.product` and `product.template`
- ✅ Access to Inventory/Stock module (for inventory sync)
- ✅ Access to Events module (if using events)

### Step 6: Test Connection Manually

You can test the connection using curl or Postman:

```bash
curl -X POST https://house-of-sheelaa.odoo.com/web/session/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "params": {
      "db": "house-of-sheelaa",
      "login": "house-of-sheelaa",
      "password": "ec48b7e79184485691fbf3464be9330a7f6031fc"
    }
  }'
```

### Step 7: Alternative - Use Username/Password

If API key doesn't work, you can:
1. Toggle OFF "Use API Key Authentication"
2. Enter your Odoo username
3. Enter your Odoo password
4. This will use standard Odoo authentication

### Common Issues

**Issue: URL has `/odoo` suffix**
- **Fix**: Remove `/odoo` from the end
- The app automatically normalizes this, but it's better to enter it correctly

**Issue: Database name mismatch**
- **Fix**: Check your Odoo login page - the database name is usually shown there
- Or check Odoo settings

**Issue: API key not working**
- **Fix**: Try using username/password instead
- Or verify API key is active in Odoo

**Issue: Network/CORS errors**
- **Fix**: Ensure Odoo instance is accessible
- Check firewall settings
- Verify SSL certificate if using HTTPS

### Getting Help

If authentication still fails:
1. Check the detailed error message in the app
2. Verify all credentials in Odoo admin panel
3. Try username/password authentication as alternative
4. Check Odoo server logs for more details

### Success Indicators

When connection is successful, you'll see:
- ✅ "Connected to Odoo" message
- ✅ Products will start loading automatically
- ✅ No error messages

