# Odoo Appointments Integration - Complete Setup Guide

## 🎯 Overview

This guide explains the complete appointment booking system that integrates your Flutter app with Odoo's Appointments module. When customers book services, appointments are automatically created in Odoo with email invitations for online consultations.

## 📋 Features Implemented

### ✅ Automatic Appointment Creation
- **When:** After sales order is confirmed in Odoo
- **What:** Creates appointment in consultant's calendar
- **Where:** Shows in Odoo Appointments module
- **How:** Links customer, service, sales order together

### ✅ Email Invitations
- Sends automatic email to customer with appointment details
- Includes video call link (Google Meet or Odoo Discuss)
- Customer can accept/decline invitation

### ✅ Consultant Assignment
- Automatically assigns appointment to consultant (admin user by default)
- Consultant sees appointment in their Odoo calendar
- Can manage, complete, or reschedule appointments

### ✅ Video Call Integration
- Supports Google Meet video calls
- Alternative: Odoo Discuss (built-in video chat)
- Link sent via email invitation

## 🔧 Odoo Configuration Required

### Step 1: Enable Appointments Module

1. **Install Appointments App**
   - Go to Odoo → Apps
   - Search "Appointments"
   - Click "Install"

2. **Configure Appointment Settings**
   - Go to Appointments → Configuration → Settings
   - Enable "Video Calls"
   - Choose provider: Google Meet or Odoo Discuss
   - Save

### Step 2: Create Consultant Users

1. **Add Consultant User** (if not using admin)
   ```
   Settings → Users & Companies → Users → Create
   
   Name: [Consultant Name]
   Email: consultant@houseofsheelaa.com
   Login: consultant
   User Type: Internal User (NOT Portal)
   Access Rights: Give "Appointments / Administrator" rights
   ```

2. **Update Code with Consultant**
   - In `odoo_api_service.dart` line 1889:
   ```dart
   domain: [['login', '=', 'admin']], // Change 'admin' to your consultant's login
   ```

### Step 3: Configure Email Server

**For Email Invitations to Work:**

1. **Setup Outgoing Mail Server**
   ```
   Settings → Technical → Email → Outgoing Mail Servers
   
   SMTP Server: smtp.gmail.com (or your provider)
   SMTP Port: 587
   Security: TLS
   Username: your-email@gmail.com
   Password: [App Password]
   ```

2. **Test Email**
   - Click "Test Connection"
   - Should show "Connection successful"

3. **Enable Email on Calendar Events**
   ```
   Settings → General Settings
   Scroll to "Discuss" section
   Enable "Calendar" and "Email Integration"
   Save
   ```

### Step 4: Configure Video Call Settings

#### Option A: Google Meet (Recommended)

1. **Enable Google Calendar Integration**
   ```
   Settings → Integrations → Google Calendar
   Enable "Use Google Calendar"
   Follow OAuth setup
   ```

2. **Video Call Provider**
   ```
   Appointments → Configuration → Settings
   Video Call Provider: Google Meet
   Save
   ```

#### Option B: Odoo Discuss (Built-in)

1. **Enable Discuss**
   ```
   Apps → Search "Discuss" → Install
   
   Appointments → Configuration → Settings
   Video Call Provider: Odoo Discuss
   Save
   ```

### Step 5: Configure Appointment Types

Appointment types are automatically created by the app, but you can customize:

1. **View Appointment Types**
   ```
   Appointments → Configuration → Appointment Types
   ```

2. **Customize Service Settings**
   ```
   Click on service (e.g., "Manifestation Healing Booking")
   
   Settings:
   - Duration: 15 minutes (or customize)
   - Location: Online
   - Video Call: Enabled
   - Timezone: Asia/Kolkata
   - Assign Method: Choose Staff
   - Notification Settings: Email reminders enabled
   ```

## 📱 How It Works - Complete Flow

### Customer Side (Flutter App)

```
1. Customer browses services
   ↓
2. Adds service to cart (with quantity & variants)
   ↓
3. Goes to checkout, fills details
   ↓
4. Selects payment method
   ↓
5. Payment processed
   ↓
6. Order confirmation shown ✅
```

### Backend (Odoo Integration)

```
1. Sales Order created in Odoo
   ↓
2. Sales Order confirmed (state: 'sale')
   ↓
3. Appointment automatically created:
   - Finds/Creates appointment type for service
   - Assigns to consultant user
   - Links customer (partner)
   - Sets appointment time (2 hours from booking)
   - Enables video call
   ↓
4. Email invitation sent to customer
   ↓
5. Appointment shows in:
   - Odoo Appointments module
   - Consultant's calendar
   - Customer's email
```

### Consultant Side (Odoo)

```
1. Sees new appointment in calendar
   ↓
2. Reviews customer details
   ↓
3. Sends video call link (if needed)
   ↓
4. Conducts consultation at scheduled time
   ↓
5. Marks appointment as "Done"
```

## 🎛️ Customization Options

### Change Appointment Timing

**File:** `lib/features/store/payment_screen.dart` Line 143

```dart
// Currently: 2 hours from booking
final appointmentDate = DateTime.now().add(const Duration(hours: 2));

// Options:
// - Same day evening: DateTime(now.year, now.month, now.day, 18, 0)
// - Next day: DateTime.now().add(const Duration(days: 1))
// - Custom: Let user select date in checkout
```

### Change Appointment Duration

**File:** `lib/features/store/payment_screen.dart` Line 150

```dart
durationMinutes: 15, // Change to 30, 60, 90, etc.
```

### Change Video Call Provider

**File:** `lib/core/odoo/odoo_api_service.dart` Line 1932, 1940

```dart
'videocall_location': 'google_meet', // Options: 'google_meet', 'odoo_discuss'
```

### Assign to Different Consultant

**Option 1: Change Default**

File: `lib/core/odoo/odoo_api_service.dart` Line 1889

```dart
domain: [['login', '=', 'your_consultant_username']],
```

**Option 2: Service-Specific Assignment** (Future Enhancement)

Map services to consultants:
```dart
final consultantMap = {
  'Manifestation Healing': 'healer1@example.com',
  'Numerology': 'numerologist@example.com',
  'Card Reading': 'reader@example.com',
};
```

## 📊 Viewing Appointments in Odoo

### Appointments List View

```
Odoo → Appointments → Appointments

You'll see:
- Subject: House of Sheelaa - [Service Name] Booking
- Start Date: 12 Dec, 2:00 pm
- End Date: 12 Dec, 2:15 pm
- Attendees: House of Sheelaa, [Customer Name]
- Location: Online Video Call
- Status: Booked
- Duration: 00:15
```

### Calendar View

```
Odoo → Appointments → Calendar

Shows all appointments in calendar format
Color-coded by status:
- Green: Confirmed
- Orange: Pending
- Blue: Done
```

### Pivot Reports

```
Odoo → Appointments → Reporting

Group by:
- Month
- Service Type
- Consultant
- Status
```

## 🐛 Troubleshooting

### Issue: Appointments not showing in module

**Check:**
1. ✅ Appointments app is installed in Odoo
2. ✅ User has "Appointments / User" access rights
3. ✅ Filter is not hiding appointments (remove all filters)
4. ✅ Check console logs for error messages

**Debug:**
```dart
// In payment_screen.dart, check logs:
[Payment] 📅 Appointment created for [Service Name]
```

### Issue: Email invitations not sent

**Check:**
1. ✅ Outgoing mail server configured
2. ✅ Test connection successful
3. ✅ Customer email is valid
4. ✅ Email integration enabled in Settings

**Debug:**
Look for log:
```
[OdooApi] 📧 Invitation email sent to customer
```

### Issue: Video call link not working

**Check:**
1. ✅ Google Calendar integration setup (for Google Meet)
2. ✅ OR Discuss app installed (for Odoo Discuss)
3. ✅ Video call provider selected in Appointments settings
4. ✅ Consultant has Google account linked (for Google Meet)

### Issue: Wrong consultant assigned

**Fix:**
Update consultant username in `odoo_api_service.dart`:
```dart
domain: [['login', '=', 'correct_username']],
```

### Issue: Appointment time is wrong

**Check:**
1. ✅ Timezone setting in appointment type: Asia/Kolkata
2. ✅ Server timezone matches
3. ✅ Date format is ISO 8601

**Adjust:**
```dart
// In payment_screen.dart
final appointmentDate = DateTime.now().add(const Duration(hours: 2));
```

## 📧 Email Template Customization

### Customize Invitation Email

```
Odoo → Settings → Technical → Email Templates

Search: "Calendar: Invitation"

Customize:
- Subject line
- Email body
- Add branding
- Include custom instructions
```

### Sample Email Content

```
Subject: Your Appointment with House of Sheelaa

Dear {{ object.partner_ids[0].name }},

Your appointment has been confirmed!

🎯 Service: {{ object.name }}
📅 Date: {{ object.start }}
⏱️ Duration: {{ object.duration }} hours
💻 Location: Online Video Call

Join Link: [Video Call URL]

Please join 5 minutes before the scheduled time.

Best regards,
House of Sheelaa Team
```

## 🚀 Advanced Features (Future Enhancements)

### Let Customer Choose Date/Time

Add date picker in checkout:
```dart
// In checkout_screen.dart
DateTime? selectedAppointmentDate;

// Add date picker field
InkWell(
  onTap: () async {
    final date = await showDatePicker(...);
    final time = await showTimePicker(...);
    // Combine and save
  },
  child: InputDecorator(...),
)
```

### Multiple Consultants

```dart
// In checkout_screen.dart
String? selectedConsultant;

DropdownButtonFormField<String>(
  items: consultants.map((c) => DropdownMenuItem(
    value: c.email,
    child: Text(c.name),
  )).toList(),
  onChanged: (value) => selectedConsultant = value,
)
```

### Appointment Reminders

```dart
// In odoo_api_service.dart, add alarm_ids:
'alarm_ids': [[6, 0, [1]]], // 1 = 15 min before reminder
```

### Customer Appointment History

Create new screen to show customer's past/upcoming appointments:
```dart
Future<List> getCustomerAppointments(String email) async {
  return await searchRead(
    model: 'calendar.event',
    domain: [
      ['partner_ids.email', '=', email],
    ],
    fields: ['name', 'start', 'stop', 'state'],
  );
}
```

## ✅ Testing Checklist

### Before Going Live

- [ ] Install Appointments app in Odoo
- [ ] Configure email server and test
- [ ] Setup video call provider
- [ ] Create consultant user(s)
- [ ] Update consultant username in code
- [ ] Test complete booking flow
- [ ] Verify appointment shows in Odoo
- [ ] Check email invitation received
- [ ] Test video call link works
- [ ] Verify consultant can see in calendar
- [ ] Test appointment completion flow

### Test Scenario

1. **Book a Service**
   - Add "Manifestation Healing Booking" to cart
   - Go to checkout
   - Fill customer details
   - Complete payment

2. **Check Odoo**
   - Sales order created? ✅
   - Sales order confirmed? ✅
   - Appointment in Appointments module? ✅
   - Appointment in consultant's calendar? ✅

3. **Check Email**
   - Customer received invitation? ✅
   - Email has appointment details? ✅
   - Video call link present? ✅

4. **Conduct Appointment**
   - Consultant clicks video link ✅
   - Customer joins call ✅
   - Consultation completed ✅
   - Marked as "Done" in Odoo ✅

## 📞 Support

If you encounter issues:

1. **Check Logs**
   - Browser console for Flutter app
   - Odoo logs: Settings → Technical → Logging

2. **Verify Setup**
   - All configuration steps completed
   - Required apps installed
   - Email/video settings configured

3. **Test Manually**
   - Create appointment directly in Odoo
   - Send test email invitation
   - Check if video call works

## 🎉 Success!

When everything is working, you'll see:

✅ Appointments automatically created after purchase
✅ Consultant gets notification in calendar
✅ Customer receives email invitation
✅ Video call link ready for online consultation
✅ Complete workflow from booking to completion

Your House of Sheelaa appointment system is now fully integrated! 🏠✨
