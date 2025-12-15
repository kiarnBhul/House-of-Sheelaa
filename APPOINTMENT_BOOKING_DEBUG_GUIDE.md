# 🔍 Appointment Booking Debug Guide

## Issue
Appointments are not showing in Odoo **Appointments → Staff Bookings** even though sales orders are being created successfully.

## Enhanced Debugging Added

I've added comprehensive logging to track exactly what's happening. When you book an appointment, you'll now see detailed console output showing:

### 1. **Payment Screen Logs**
```
[Payment] ═════════════════════════════════════════
[Payment] 🎯 STARTING APPOINTMENT CREATION PROCESS
[Payment] 📊 Partner ID: 123
[Payment] 📊 Sales Order ID: 456
[Payment] 📊 Order Status: sale/draft
[Payment] 📊 Items to process: 1
[Payment] ═════════════════════════════════════════

[Payment] 🔍 Processing service:
[Payment]    Original name: Chakra Healing Booking
[Payment]    Cleaned name: Chakra Healing
[Payment]    Calling createAppointmentFromOrder...
```

### 2. **Appointment Type Search Logs**
```
[OdooApi] 🔍 Searching for appointment type...
[OdooApi]    Service name: "Chakra Healing"
[OdooApi]    Trying exact match: name = "Chakra Healing"
[OdooApi]    Exact match results: 1 types found

[OdooApi] ✅✅✅ FOUND APPOINTMENT TYPE!
[OdooApi]    ID: 14
[OdooApi]    Name: Chakra Healing
[OdooApi]    Staff IDs: [[2, "Rohit"]]
[OdooApi]    Duration: 15
```

### 3. **Staff Assignment Logs**
```
[OdooApi] 👨‍💼 Using staff from appointment type: User ID 2
```

### 4. **Calendar Event Creation Logs**
```
[OdooApi] 📝 Creating calendar.event record...
[OdooApi]    Model: calendar.event
[OdooApi]    Method: create
[OdooApi]    appointment_type_id: 14
[OdooApi]    user_id (staff): 2
[OdooApi]    partner_ids (customer): [[6, 0, [123]]]
[OdooApi]    state: open
[OdooApi]    videocall_location: odoo_discuss

[OdooApi] Response from create: 789 (type: int)

[OdooApi] ✅✅✅ CALENDAR EVENT CREATED SUCCESSFULLY!
[OdooApi]    Appointment ID: 789
[OdooApi]    Should now be visible in:
[OdooApi]       Appointments → Appointment Types → Staff Bookings
[OdooApi]       Filter: Appointment = Chakra Healing
```

### 5. **Final Summary**
```
[Payment] ═════════════════════════════════════════
[Payment] 📊 APPOINTMENT CREATION SUMMARY:
[Payment]    ✅ Successful: 1
[Payment]    ❌ Failed: 0
[Payment] ═════════════════════════════════════════
```

## What to Check Now

### Step 1: Test Booking Flow
1. **Open your Flutter app** in Chrome
2. **Open Browser Console** (F12 → Console tab)
3. **Add Chakra Healing to cart**
4. **Go through checkout**
5. **Watch the console output carefully**

### Step 2: Identify the Problem

Look for these specific error patterns:

#### ❌ **Problem 1: Appointment Type Not Found**
```
[OdooApi] ❌❌❌ NO APPOINTMENT TYPE FOUND!
[OdooApi]    Searched for: "Chakra Healing"
```

**Solution:**
- Go to Odoo → Appointments → Appointment Types
- Click "New" or edit existing type
- Make sure name EXACTLY matches: "Chakra Healing" (case-sensitive)
- Save

#### ❌ **Problem 2: Sales Order Not Confirmed**
```
[OdooApi] ❌❌❌ CRITICAL: Order confirmation FAILED!
```

**Solution:**
- Sales order must be in "Sale Order" state, not "Draft"
- Check Odoo Settings → Sales → Quotations & Orders
- Ensure automatic confirmation is enabled
- Or manually confirm orders in Odoo

#### ❌ **Problem 3: Calendar Event Creation Failed**
```
[OdooApi] ❌ Appointment creation failed
```

**Solution:**
- Check if you have "Appointments" module installed in Odoo
- Check if you have "Calendar" module installed
- Verify user permissions for calendar.event model

#### ❌ **Problem 4: Missing Staff Assignment**
```
[OdooApi] ⚠️ Error finding staff user
```

**Solution:**
- Open appointment type in Odoo
- Go to "Users" tab
- Add at least one staff member (Rohit, Vineet Jain, or Admin)
- Save

### Step 3: Check Odoo Side

After booking, verify in Odoo:

#### A. Check Calendar Events
```
Odoo → Calendar (app)
```
- Should see new event created
- Event name should be service name
- Should have customer as attendee

#### B. Check Appointment Module
```
Odoo → Appointments → Appointment Types → [Chakra Healing]
→ Click "Staff Bookings" button
```
- Filter: Attendees = All
- Filter: Appointment = Chakra Healing
- Should show booking in calendar

#### C. Check Sales Order
```
Odoo → Sales → Orders
```
- Find your order (SO123)
- Check "Notes" field - should have appointment reference
- Verify status is "Sale Order" not "Draft"

## Common Issues & Solutions

### Issue 1: Bookings Created But Not Showing
**Symptom:** Console shows ✅ success but nothing in Staff Bookings

**Causes:**
1. **Wrong Filters** - Remove all filters in Staff Bookings calendar view
2. **Wrong Date** - Appointments scheduled 2 hours from now, check correct date/time
3. **Wrong Staff Member** - Filter by correct staff user
4. **Missing appointment_type_id** - Event created without type link

**Check:**
```sql
-- In Odoo debug console
SELECT id, name, appointment_type_id, user_id, partner_ids 
FROM calendar_event 
WHERE name = 'Chakra Healing' 
ORDER BY id DESC LIMIT 5;
```

### Issue 2: Appointment Type Name Mismatch
**Symptom:** "NO APPOINTMENT TYPE FOUND" in logs

**Solution:**
Service names from app must EXACTLY match appointment type names in Odoo:

| App Service Name | Odoo Appointment Type Name | Match |
|-----------------|---------------------------|-------|
| Chakra Healing Booking | Chakra Healing | ✅ Auto-cleaned |
| TRAUMA HEALING | TRAUMA HEALING | ✅ Exact |
| trauma healing | TRAUMA HEALING | ❌ Case mismatch |
| Chakra  Healing | Chakra Healing | ❌ Extra space |

**Fix:** Make names identical in both systems

### Issue 3: No Staff Assigned
**Symptom:** "Using default admin user" in logs

**Solution:**
1. Odoo → Appointments → Appointment Types → [Type Name]
2. Click "Users" tab
3. Click "Add a line"
4. Select consultant (Rohit, Vineet Jain)
5. Save

### Issue 4: Email Server Not Configured
**Symptom:** "Could not send invitation email"

**Solution:**
1. Settings → Technical → Email → Outgoing Mail Servers
2. Configure SMTP server
3. Test connection
4. Set as default

## Testing Checklist

- [ ] Console shows appointment type found
- [ ] Console shows staff user assigned
- [ ] Console shows calendar event created with ID
- [ ] Console shows ✅ success message
- [ ] Console shows no ❌ errors
- [ ] Sales order is in "Sale Order" status (not Draft)
- [ ] Odoo Calendar app shows new event
- [ ] Odoo Appointments → Staff Bookings shows booking
- [ ] Customer receives booking confirmation email

## Expected Full Flow

```
1. User adds Chakra Healing to cart
   ↓
2. Completes checkout with details
   ↓
3. Payment screen calls createSalesOrderFromCart
   ↓
4. Sales order created (SO123) ✅
   ↓
5. Sales order confirmed (Draft → Sale Order) ✅
   ↓
6. For each service in order:
   a. Clean service name: "Chakra Healing Booking" → "Chakra Healing"
   b. Search Odoo for appointment type "Chakra Healing"
   c. Get staff users from appointment type
   d. Create calendar.event with:
      - appointment_type_id = 14 (Chakra Healing type)
      - user_id = 2 (Staff member)
      - partner_ids = [123] (Customer)
      - state = open (Booked)
   e. Send email invitation
   f. Update sales order notes
   ↓
7. Booking appears in:
   - Odoo Calendar ✅
   - Odoo Appointments → Staff Bookings ✅
   - Customer email inbox ✅
```

## Critical Fields for Staff Bookings View

For appointment to appear in Staff Bookings calendar, the calendar.event MUST have:

| Field | Required | Purpose |
|-------|----------|---------|
| appointment_type_id | ✅ YES | Links event to appointment type |
| user_id | ✅ YES | Assigns to staff member |
| state | ✅ YES | Must be 'open' (booked) |
| partner_ids | Optional | Shows customer attendee |
| start | ✅ YES | Appointment start time |
| stop | ✅ YES | Appointment end time |

**Most Common Miss:** `appointment_type_id` not set → event created but not linked to appointment type → doesn't show in Staff Bookings!

## Next Steps

1. **Book a test appointment** with enhanced logging
2. **Copy ALL console output** showing the creation process
3. **Share the logs** so we can identify exactly where it's failing
4. **Check Odoo** for the specific error messages

The detailed logs will show us EXACTLY what's happening at each step!
