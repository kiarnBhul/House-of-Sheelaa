# Odoo API Key Setup Guide

Your API key has been pre-configured in the app: `ec48b7e79184485691fbf3464be9330a7f6031fc`

## Quick Setup Steps (For Admin/Developer Only)

> **Note**: The Odoo Configuration screen is hidden from regular users for security. Only admins/developers can access it.

### Initial Setup (One-time, Developer/Admin Only)

1. **Access Odoo Configuration** (Developer/Admin access required)
   - The configuration screen is not visible to regular users
   - For initial setup, you can access it programmatically or through developer tools
   - Route: `/odoo-config` (hidden from public menu)

2. **Enter Your Odoo Details**
   - **Odoo Base URL**: Your Odoo instance URL (e.g., `https://your-odoo-instance.com` or `http://your-odoo-instance.com`)
   - **Database Name**: Your Odoo database name
   - **Toggle "Use API Key Authentication"**: Make sure it's ON (enabled)
   - **API Key**: Already pre-filled with your key: `ec48b7e79184485691fbf3464be9330a7f6031fc`

4. **Test Connection**
   - Tap "Test & Connect"
   - Wait for authentication
   - If successful, you'll see "Connected to Odoo" message

5. **Products Will Auto-Load**
   - Once connected, products from Odoo will automatically appear in the Shop
   - You can refresh products by tapping the sync icon in the Shop screen

## Managing Products in Odoo

### Adding Products

1. **In Odoo Admin Panel:**
   - Go to **Inventory → Products → Products**
   - Click **Create**
   - Fill in:
     - **Product Name**: Name of the product
     - **Product Type**: Select "Storable Product" or "Consumable"
     - **Can be Sold**: Check this box ✓
     - **Sales Price**: Set the selling price
     - **Category**: Select or create a category
     - **Image**: Upload product image
     - **Description**: Add product description
   - Click **Save**

2. **In the App:**
   - Products will appear automatically in the Shop
   - Tap the refresh icon (🔄) in the Shop screen to sync latest products

### Product Requirements

For products to appear in the app:
- ✅ `sale_ok` must be `True` (Can be Sold checkbox)
- ✅ `type` should be `'product'` (not `'service'`)
- ✅ Product must have a `list_price` (selling price)
- ✅ Product should have a `categ_id` (category) for better organization

### Categories

Products are organized by categories in Odoo:
- Create categories in Odoo: **Inventory → Configuration → Product Categories**
- Products will be grouped by category in the app
- Users can filter by category in the Shop screen

## Inventory Management

Stock levels are automatically synced:
- **Available Quantity**: Shows in product details
- **Out of Stock**: Products with `qty_available = 0` won't show (if filter is enabled)
- **Stock Updates**: Refresh the app to see latest inventory

## Services Management

To add services (like Numerology, Healing, etc.):

1. **In Odoo:**
   - Go to **Inventory → Products → Products**
   - Click **Create**
   - Set **Product Type** to **"Service"**
   - Fill in service details
   - Set **Can be Sold** to `True`
   - Click **Save**

2. **In the App:**
   - Services will appear in the Services section
   - Users can book services directly

## Events Management

To add events:

1. **Install Event Module** (if not installed):
   - Go to **Apps** in Odoo
   - Search for "Events"
   - Install the module

2. **Create Events:**
   - Go to **Events → Events**
   - Click **Create**
   - Fill in:
     - **Event Name**
     - **Start Date/Time**
     - **End Date/Time**
     - **Location**
     - **Description**
     - **Image**
   - Click **Save**

3. **In the App:**
   - Events will appear in the Events section
   - Users can view and register for events

## Troubleshooting

### API Key Not Working

If authentication fails with API key:

1. **Check Odoo Version**: API key authentication works with Odoo 14+
2. **Verify API Key**: Make sure the key is correct
3. **Check Odoo Settings**: 
   - Go to **Settings → Users & Companies → API Keys**
   - Verify the key is active
4. **Try Username/Password**: Toggle off "Use API Key" and use username/password instead

### Products Not Showing

1. **Check Product Settings:**
   - `sale_ok` must be `True`
   - `type` must be `'product'` (not `'service'`)
   - Product must have a price

2. **Refresh Products:**
   - Tap the refresh icon (🔄) in Shop screen
   - Or restart the app

3. **Check Permissions:**
   - Verify your Odoo user has read access to products
   - Check user groups and permissions

### Connection Issues

1. **Check URL Format:**
   - Must start with `http://` or `https://`
   - No trailing slash
   - Example: `https://your-odoo-instance.com`

2. **Check Database Name:**
   - Must match exactly (case-sensitive)
   - Usually visible in Odoo login page

3. **Network:**
   - Ensure Odoo instance is accessible
   - Check firewall settings
   - Verify SSL certificate if using HTTPS

## API Key Format

Your API key format: `02aad5fe3af89ccca6d120ae6223f0278d683017`

This is a 40-character hexadecimal string, which is the standard Odoo API key format.

## Support

For issues:
1. Check the error message in Odoo Configuration screen
2. Verify Odoo instance is running
3. Check Odoo logs for API errors
4. Ensure API key has proper permissions

