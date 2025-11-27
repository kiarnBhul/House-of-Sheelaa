# Admin Panel Navigation Guide

## How to Access the Admin Panel

### Method 1: Run Admin App Directly (Recommended)

The admin panel is a separate Flutter app. To run it:

#### For Web:
```bash
flutter run -d chrome --target lib/main_admin.dart
```

#### For Desktop:
```bash
flutter run -d windows --target lib/main_admin.dart
# or
flutter run -d macos --target lib/main_admin.dart
# or
flutter run -d linux --target lib/main_admin.dart
```

#### For Mobile:
```bash
flutter run -d <device-id> --target lib/main_admin.dart
```

### Method 2: Access via URL (Web Only)

If running on web, you can directly navigate to:
- **Login Page**: `http://localhost:port/#/hofs-admin/login`
- **Dashboard**: `http://localhost:port/#/hofs-admin/dashboard` (redirects to login if not authenticated)

### Admin Routes

Once logged in, you can navigate to:

1. **Dashboard**: `/hofs-admin/dashboard`
   - Main overview with metrics, charts, and quick actions

2. **Numero Dashboard**: `/hofs-admin/dashboard/numero`
   - Numerology-specific analytics and services management

3. **Integration**: `/hofs-admin/integration`
   - Manage Odoo, Firebase, and other integrations

4. **Services**: `/hofs-admin/services`
   - Manage all services
   - Create new: `/hofs-admin/services/new`
   - Edit existing: `/hofs-admin/services/:id`

## Login Credentials

The admin panel uses Firebase Firestore for authentication. Admin credentials are stored in the `HofS-admin` collection.

### Setting Up Admin Account

1. **Create Admin Document in Firestore:**
   - Collection: `HofS-admin`
   - Document ID: Your email address (e.g., `admin@houseofsheelaa.com`)
   - Fields:
     ```json
     {
       "password": "your-secure-password",
       "name": "Admin Name",
       "role": "admin"
     }
     ```

2. **Login with:**
   - Email: The document ID (your email)
   - Password: The password stored in the document

### Example Admin Setup (Firestore)

```javascript
// In Firebase Console or using Firebase Admin SDK
db.collection('HofS-admin').doc('admin@houseofsheelaa.com').set({
  password: 'your-secure-password-here',
  name: 'Admin User',
  role: 'admin',
  createdAt: FieldValue.serverTimestamp()
});
```

## Navigation Features

### Side Navigation
- **Collapsible Sidebar**: Click the chevron button at the bottom to expand/collapse
- **Active State**: Current page is highlighted in the sidebar
- **Smooth Animations**: All navigation transitions are animated

### Top Bar
- **Search**: Search functionality (placeholder for now)
- **Notifications**: Notification bell with badge
- **User Profile**: Profile icon
- **Sign Out**: Logout button

## Quick Start

1. **Run the admin app:**
   ```bash
   flutter run -d chrome --target lib/main_admin.dart
   ```

2. **Login page appears automatically**

3. **Enter your credentials:**
   - Email: Your admin email (document ID in Firestore)
   - Password: Your admin password

4. **After login, you'll see:**
   - Dashboard with metrics and charts
   - Side navigation with all sections
   - Modern, beautiful UI with brand colors

## Troubleshooting

### Can't Access Admin Panel

1. **Check if you're running the correct entry point:**
   - Make sure you're using `--target lib/main_admin.dart`
   - Not `lib/main.dart` (that's the main app)

2. **Firebase Not Initialized:**
   - Ensure Firebase is properly configured
   - Check `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)

3. **Login Fails:**
   - Verify admin document exists in Firestore `HofS-admin` collection
   - Check email matches document ID exactly
   - Verify password is correct

### Routes Not Working

- Admin routes start with `/hofs-admin/`
- Make sure you're using GoRouter navigation
- Check browser console for errors (web)

## Development Tips

### Hot Reload
The admin app supports hot reload:
- Make changes to admin files
- Press `r` in terminal to hot reload
- Press `R` for hot restart

### Debugging
- Use Flutter DevTools for debugging
- Check network tab for Firebase calls
- Use browser console for web-specific issues

## Security Notes

⚠️ **Important:**
- Admin credentials are stored in Firestore
- Use strong passwords
- Consider implementing proper authentication (Firebase Auth) for production
- The current implementation is for development/admin use


