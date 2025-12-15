# Appointment Booking Setup - Quick Guide

## 🎯 Making Bookings Show in Odoo Appointments

### Problem
When customers book services from the app, appointments weren't showing in Odoo's **Staff Bookings** section.

### Solution
The code has been updated to properly link bookings to your existing **Appointment Types** in Odoo.

---

## ✅ What Was Fixed

### 1. **Smart Name Matching**
The app now automatically matches product names to appointment types:

```
Product Name                → Appointment Type
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"Manifestation Healing"     → "Manifestation Healing" ✅
"Manifestation Healing Booking" → "Manifestation Healing" ✅ (auto-cleaned)
"TRAUMA HEALING"            → "TRAUMA HEALING" ✅
"Extraction Healing Service" → "Extraction Healing" ✅ (auto-cleaned)
```

### 2. **Proper Odoo Integration**
- Links calendar events to appointment types via `appointment_type_id`
- Assigns bookings to staff users configured in appointment types
- Sets proper state (`open` = booked/confirmed)
- Enables video calls (Odoo Discuss)

### 3. **Enhanced Logging**
Console now shows detailed booking process:
```
[Payment] 🔍 Looking for appointment type: Manifestation Healing
[OdooApi] ✅ Found appointment type: Manifestation Healing (ID: 19)
[OdooApi] 👨‍💼 Using staff from appointment type: User ID 2
[OdooApi] ✅ Appointment booking created: ID 45
[Payment] ✅ Appointment booking created for Manifestation Healing
```

---

## 📋 Setup Checklist

### Step 1: Verify Product Names in Odoo

1. **Go to Odoo Products**
   ```
   Odoo → Sales → Products → Products
   ```

2. **Check Service Product Names**
   
   Your products should be named to match appointment types:
   
   ✅ **Correct Examples:**
   - `Manifestation Healing`
   - `TRAUMA HEALING`
   - `Prosperity Healing`
   - `Extraction Healing`
   
   ⚠️ **Also Works (auto-cleaned):**
   - `Manifestation Healing Booking`
   - `Extraction Healing Service`
   - `TRAUMA HEALING Session`

### Step 2: Verify Appointment Types Exist

1. **Go to Appointments**
   ```
   Odoo → Appointments → Configuration → Appointment Types
   ```

2. **Check These Exist:**
   - [ ] TRAUMA HEALING (15 mins)
   - [ ] Prosperity Healing (15 mins)
   - [ ] Manifestation Healing (15 mins)
   - [ ] Cutting chords healing (15 mins)
   - [ ] Lemurian Healing (15 mins)
   - [ ] Chakra Healing (15 mins)
   - [ ] Extraction Healing (30 mins)

3. **Configure Each Appointment Type:**
   
   Click on appointment type → Edit:
   
   ```
   Staff/Users: [Select consultant(s)]
   Location: Online
   Video Call: Enabled (Odoo Discuss or Google Meet)
   Timezone: Asia/Kolkata
   Duration: 15 or 30 minutes
   ```

### Step 3: Assign Staff to Appointment Types

**CRITICAL:** Each appointment type needs at least one staff member assigned!

1. Open appointment type (e.g., "Manifestation Healing")
2. Go to **"Users"** tab
3. Click **"Add a line"**
4. Select staff member(s):
   - **Admin** (default)
   - **Rohit** (if available)
   - **Vineet Jain** (if available)
5. Save

**Why?** The code automatically assigns bookings to the staff configured in the appointment type.

---

## 🧪 Testing the Complete Flow

### Test Scenario

1. **Book from App**
   ```
   - Add "Manifestation Healing" to cart
   - Checkout with customer details
   - Complete payment
   ```

2. **Check Console Logs**
   ```
   Look for these messages in browser console:
   
   ✅ [Payment] 🔍 Looking for appointment type: Manifestation Healing
   ✅ [OdooApi] ✅ Found appointment type: Manifestation Healing (ID: 19)
   ✅ [OdooApi] 👨‍💼 Using staff from appointment type: User ID 2
   ✅ [OdooApi] ✅ Appointment booking created: ID 45
   ✅ [Payment] ✅ Appointment booking created for Manifestation Healing
   ```

3. **Verify in Odoo - Appointments Module**
   ```
   Odoo → Appointments → Appointments
   
   Should show:
   - Subject: Manifestation Healing
   - Attendees: House of Sheelaa, [Customer Name]
   - Status: Booked
   - Date/Time: [Scheduled time]
   ```

4. **Verify in Staff Bookings**
   ```
   Odoo → Appointments → Appointment Types
   Click on "Manifestation Healing"
   
   Should show:
   - "1 Meeting Total" (counter increased)
   - Click "Staff Bookings" tab
   - See the booking on calendar
   ```

5. **Verify Sales Order Link**
   ```
   Odoo → Sales → Orders → [Your SO number]
   
   In "Notes" field should see:
   "Appointment Booking ID: 45
    Scheduled: [Date/Time]
    Service: Manifestation Healing"
   ```

---

## 🔧 Common Issues & Solutions

### Issue 1: Appointment Type Not Found

**Error in logs:**
```
[OdooApi] ⚠️ No appointment type found for: [Service Name]
```

**Solution:**
1. Check product name in Odoo exactly matches appointment type name
2. OR create appointment type with matching name:
   ```
   Appointments → Configuration → Appointment Types → Create
   Name: [Exact product name]
   Duration: 15
   Location: Online
   ```

### Issue 2: No Staff Assigned

**Error in logs:**
```
[OdooApi] ⚠️ Using default admin user
```

**Solution:**
1. Open appointment type in Odoo
2. Go to "Users" tab  
3. Add staff member(s)
4. Save

### Issue 3: Booking Created But Not Showing

**Check:**
1. ✅ Filter in Appointments view - remove all filters
2. ✅ Date range - check calendar view
3. ✅ User permissions - ensure you can see calendar events
4. ✅ Appointment type ID - check logs to confirm it was linked

**Debug:**
```
Check logs for:
[OdooApi] ✅ Appointment booking created: ID XX

Then search in Odoo:
Appointments → Search bar → Type "ID XX"
```

### Issue 4: Multiple Bookings Created

**Why:** If there are multiple items in cart, it creates one booking per item.

**Expected:** This is correct behavior! Each service gets its own appointment.

---

## 🎨 Customization Options

### Change Appointment Timing

**File:** `payment_screen.dart` line 145

```dart
// Default: 2 hours from booking
final appointmentDate = DateTime.now().add(const Duration(hours: 2));

// Change to:
// - Same day 6 PM:
final appointmentDate = DateTime(now.year, now.month, now.day, 18, 0);

// - Next day 10 AM:
final tomorrow = DateTime.now().add(const Duration(days: 1));
final appointmentDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);

// - User selects (requires UI change):
final appointmentDate = selectedDateTime; // From date picker
```

### Change Default Duration

**File:** `payment_screen.dart` line 151

```dart
durationMinutes: 15, // Change to 30, 60, 90, etc.
```

**OR get from product:**
```dart
final duration = item['duration'] as int? ?? 15;
```

### Change Video Call Provider

**File:** `odoo_api_service.dart` line 1955

```dart
'videocall_location': 'odoo_discuss', // Current: Odoo built-in

// Change to:
'videocall_location': 'google_meet', // Google Meet integration
```

### Add Product-to-Duration Mapping

If different services have different durations:

```dart
// In payment_screen.dart, before createAppointmentFromOrder call:

final durationMap = {
  'Manifestation Healing': 15,
  'TRAUMA HEALING': 15,
  'Extraction Healing': 30,
  'Prosperity Healing': 15,
  'Cutting chords healing': 15,
  'Lemurian Healing': 15,
  'Chakra Healing': 15,
};

final duration = durationMap[serviceName] ?? 15;

// Then use in call:
durationMinutes: duration,
```

---

## ✅ Success Indicators

When everything is working correctly, you'll see:

### In Browser Console:
```
[Payment] 🔍 Looking for appointment type: Manifestation Healing
[OdooApi] ✅ Found appointment type: Manifestation Healing (ID: 19)
[OdooApi] 👨‍💼 Using staff from appointment type: User ID 2
[OdooApi] 📝 Creating calendar event with data: name, start, stop, ...
[OdooApi] ✅ Appointment booking created: ID 45
[OdooApi] 📧 Email invitation sent to customer@email.com
[OdooApi] 🔗 Sales order updated with appointment reference
[Payment] ✅ Appointment booking created for Manifestation Healing
```

### In Odoo Appointments:
- ✅ Appointment shows in main list
- ✅ "Staff Bookings" counter increased
- ✅ Booking visible in calendar view
- ✅ Customer shows as attendee
- ✅ Video call link available

### Customer Experience:
- ✅ Receives email invitation (if configured)
- ✅ Can accept/decline appointment
- ✅ Has video call link in email

---

## 📞 Quick Troubleshooting

**No bookings showing at all?**
→ Check console logs for errors
→ Verify appointment types exist in Odoo
→ Ensure product names match

**Bookings created but wrong service?**
→ Check product name vs appointment type name matching
→ Add debug logs to see what names are being searched

**No staff assigned to booking?**
→ Add staff to appointment type in Odoo
→ OR booking will default to admin user

**Email not sent?**
→ Configure outgoing mail server in Odoo
→ Non-critical, booking still works

---

## 🎉 You're All Set!

The appointment booking system now:
- ✅ Finds your existing appointment types
- ✅ Creates bookings that show in Staff Bookings
- ✅ Links to customers and sales orders
- ✅ Sends email invitations
- ✅ Enables video consultations
- ✅ Shows in all Odoo reports

Test it out and watch the bookings appear in your Odoo Appointments module!
