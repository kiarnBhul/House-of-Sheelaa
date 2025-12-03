# Global Odoo Configuration Setup Guide

## Overview
This system allows **admin** to configure Odoo once, and **all users** automatically get data from that configuration.

## How It Works

### 1. **Admin Side** (Admin Panel)
- Admin navigates to Odoo Configuration screen
- Enters Odoo credentials (URL, database, API key)
- **Enables "Save globally for ALL users"** toggle
- Clicks "Test & Connect"
- Configuration is saved to Firestore: `app_settings/global_odoo_config`

### 2. **User Side** (Regular App Users)
- User opens the app
- App automatically loads global Odoo configuration from Firestore
- User sees products, services, events without any configuration
- **No Odoo setup required for end users!**

### 3. **Data Flow**
```
Admin Panel → Firestore (global_odoo_config) → All Users' Apps
```

## Firestore Setup

### Collection Structure
```
app_settings/
  └── global_odoo_config/
      ├── baseUrl: "https://your-odoo.com"
      ├── database: "your_database"
      ├── apiKey: "encrypted_key"
      ├── username: "username" (if not using API key)
      ├── password: "encrypted_password" (if not using API key)
      ├── proxyUrl: "https://your-proxy.com/api/odoo"
      ├── isActive: true
      ├── lastUpdated: timestamp
      └── version: 1
```

### Security Rules (Add to firestore.rules)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Global Odoo Configuration - Read by all, Write by admin only
    match /app_settings/global_odoo_config {
      allow read: if request.auth != null; // All authenticated users can read
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Existing rules...
  }
}
```

## Testing the Setup

### Step 1: Configure as Admin
1. Build and run the app
2. Login as admin user
3. Navigate to Admin Panel → Odoo Configuration
4. Enter your Odoo details:
   - Base URL: `https://your-odoo-instance.com`
   - Database: `your_database_name`
   - API Key: `your_api_key`
   - Proxy URL: `https://house-of-sheelaa-proxy-server.onrender.com/api/odoo`
5. **Enable** "🌍 Save globally for ALL users"
6. Click "Test & Connect"
7. You should see: "✅ Global configuration saved! All users will use this Odoo instance."

### Step 2: Test as Regular User
1. Logout or install app on another device
2. Login as regular (non-admin) user
3. App should automatically:
   - Load global Odoo configuration
   - Authenticate with Odoo
   - Display products, services, events
4. User **never** sees Odoo configuration screen

### Step 3: Verify in Firestore Console
1. Go to Firebase Console → Firestore Database
2. Navigate to `app_settings/global_odoo_config`
3. Verify all fields are populated
4. Check `lastUpdated` timestamp

## Production Deployment

### For Play Store / App Store Release:

1. **Configure Odoo Globally (One-time)**
   ```
   Admin Panel → Odoo Config → Enter credentials → Enable "Save globally" → Connect
   ```

2. **Deploy Apps**
   ```bash
   # Android
   flutter build apk --release
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   
   # Web
   flutter build web --release
   firebase deploy --only hosting
   ```

3. **All Users Automatically Connected**
   - Users download app
   - Users create account / login
   - App loads global Odoo config automatically
   - Products/services display immediately

## Troubleshooting

### Users Not Getting Data
**Check:**
1. Global config exists: `app_settings/global_odoo_config`
2. `isActive` field is `true`
3. Firestore security rules allow read access
4. User is authenticated
5. Check console logs for "[GlobalOdooConfig]" messages

### Admin Can't Save Globally
**Check:**
1. User has `role: 'admin'` in Firestore `users` collection
2. Firestore security rules allow admin write
3. Internet connection active
4. No Firestore permission errors in console

### Data Not Updating
**Solution:**
1. Admin updates config in admin panel
2. All users restart app (or implement real-time listener)
3. App automatically fetches updated config

## Development vs Production

### Development Mode
- Admin can configure locally (disable "Save globally")
- Multiple devs can test different Odoo instances
- Local config takes precedence for testing

### Production Mode
- Admin saves globally (enable "Save globally")
- All users use the same Odoo instance
- Perfect for live app with thousands of users

## Real-time Updates (Optional Enhancement)

To update users instantly when admin changes config:

```dart
// In OdooState._initialize()
_globalConfigService.watchGlobalConfig().listen((snapshot) {
  if (snapshot.exists) {
    _globalConfigService.loadGlobalConfig().then((_) {
      if (OdooConfig.isConfigured) {
        _autoConnect();
      }
    });
  }
});
```

## Benefits

✅ **One-time Setup**: Admin configures Odoo once  
✅ **Zero User Friction**: Users never see technical config  
✅ **Centralized Control**: Update config for all users instantly  
✅ **Scalable**: Works for 10 users or 10,000 users  
✅ **Secure**: Credentials stored encrypted in Firestore  
✅ **Production Ready**: Perfect for app store deployment  

## Next Steps

1. Deploy updated app
2. Configure Odoo as admin
3. Test with multiple user accounts
4. Monitor logs for successful auto-connection
5. Deploy to production! 🚀
