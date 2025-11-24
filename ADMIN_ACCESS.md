# Admin Access Guide

## Odoo Configuration Access (For Developers/Admins Only)

The Odoo Configuration screen is **hidden from regular users** for security. Only administrators should have access.

### How to Access (For Setup)

**Option 1: Direct Route Access (Development)**
- The route `/odoo-config` is still registered but hidden from the menu
- You can access it programmatically during development
- Or use Flutter DevTools to navigate to it

**Option 2: Add Temporary Access (For Initial Setup)**
- You can temporarily add a hidden button or gesture to access it
- Example: Tap logo 5 times, or long-press a specific area
- Remove after initial configuration

**Option 3: Configure Before Release**
- Set up Odoo connection during development
- The app will automatically connect in the background
- Users won't see any admin screens

### Automatic Background Connection

Once configured, the app will:
- ✅ Automatically connect to Odoo on app start (if configured)
- ✅ Load products from Odoo silently in the background
- ✅ Sync data without user interaction
- ✅ Hide all admin/configuration screens from users

### For Production

**Recommended Approach:**
1. Configure Odoo connection during development
2. Test that products load correctly
3. Remove or hide the configuration screen completely
4. The app will work automatically with Odoo data

### Current Status

- ✅ Odoo Configuration removed from public menu
- ✅ Automatic background connection enabled
- ✅ Products sync automatically when connected
- ✅ No admin screens visible to users

### If You Need to Reconfigure

If you need to change Odoo settings later:
1. Use Flutter DevTools to navigate to `/odoo-config`
2. Or temporarily add a hidden access method
3. Or clear app data and reconfigure during development


