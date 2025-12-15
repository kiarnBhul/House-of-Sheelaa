# Odoo Service Type Configuration Guide

## 🎯 How the App Determines Service Types

The app automatically detects whether a service needs appointment booking or cart checkout based on **Odoo configuration**. Here's exactly how it works:

---

## 📋 Detection Logic (How It Works)

### Step 1: Product Template (Service) Configuration
**Location**: Odoo → Sales → Products → [Your Service]

The app reads the `product.template` record and checks for:

```python
# In Odoo backend
product_template.appointment_type_id  # This field links to appointment.type
```

**Detection Rule**:
```dart
// In Flutter app (odoo_models.dart)
if (product['appointment_type_id'] != null && 
    product['appointment_type_id'] != false) {
  hasAppointment = true;  // Show calendar booking
} else {
  hasAppointment = false; // Show add to cart
}
```

---

## 🔧 Configuration Steps in Odoo

### **For APPOINTMENT-BASED Services** (Calendar Booking)

These services require scheduled time slots with consultants (e.g., TRAUMA HEALING, Chakra Healing).

#### Step 1: Create Appointment Type
1. Go to **Appointments** app in Odoo
2. Click **Configuration** → **Appointment Types**
3. Click **Create**
4. Fill in:
   - **Name**: "TRAUMA HEALING" (or your service name)
   - **Duration**: 15 minutes (or desired duration)
   - **Staff Members**: Select your consultants (e.g., Ashutosh, Rohit)
   - **Website Published**: ✅ Yes
   - **Appointment Time Zone**: Your timezone
   - **Min/Max Time Before**: Set booking window (e.g., 1 hour before, 7 days advance)

5. **CRITICAL**: In the **Up-front Payment** section:
   - **Product**: Select your service product from dropdown
   - This creates the bidirectional link!

6. Save

#### Step 2: Verify Product Link
1. Go to **Sales** → **Products** → [Your Service]
2. Look at the **General Information** tab
3. You should see **Appointment Type** field populated
4. If empty, go back to Appointment Type and set the product link

#### Visual Verification:
```
Appointments App → Appointment Types
┌─────────────────────────────────────┐
│ TRAUMA HEALING         15 mins      │  ✅ Has product link
│ Prosperity Healing     15 mins      │  ✅ Has product link
│ Chakra Healing         15 mins      │  ✅ Has product link (if appointment-based)
└─────────────────────────────────────┘

Products (Services)
┌─────────────────────────────────────┐
│ TRAUMA HEALING                      │
│   Appointment Type: TRAUMA HEALING  │  ✅ Linked
│   Sales Price: ₹1800               │
└─────────────────────────────────────┘
```

---

### **For DIGITAL/INSTANT Services** (Cart Checkout)

These services are delivered instantly via email/download (e.g., Karma Release, digital reports).

#### Step 1: Product Configuration
1. Go to **Sales** → **Products** → [Your Service]
2. In **General Information** tab:
   - **Product Type**: Service
   - **Invoicing Policy**: Prepaid/Fixed Price
   - **Sales Price**: Set price
   - **Appointment Type**: **LEAVE EMPTY** ← This is the key!

3. Optional: Add custom field to explicitly mark:
   - Go to **Settings** → **Technical** → **Database Structure** → **Models**
   - Find model: `product.template`
   - Add custom field: `x_delivery_type` (Selection)
     - Options: "instant", "scheduled", "physical"

#### Step 2: No Appointment Type Needed
- Simply DO NOT create or link an appointment type
- The app will automatically detect this as a cart-based service

#### Visual Verification:
```
Products (Services)
┌─────────────────────────────────────┐
│ Karma Release                       │
│   Appointment Type: [EMPTY]         │  ✅ No link = Cart flow
│   Sales Price: ₹1800               │
│   Product Type: Service            │
└─────────────────────────────────────┘
```

---

## 🔍 How to Check Current Configuration

### Method 1: Via Odoo UI

**Check Appointment Types**:
```
Appointments → Appointments
- Look for your service in the list
- If it appears = appointment-based
- If missing = cart-based
```

**Check Product**:
```
Sales → Products → [Service Name]
- General Information tab
- Look for "Appointment Type" field
- If populated = appointment-based
- If empty = cart-based
```

### Method 2: Via Odoo API (Technical)

Run this in Odoo shell or use RPC:

```python
# Check a specific product
product = env['product.template'].search([('name', '=', 'Karma Release')])[0]
print(f"Product: {product.name}")
print(f"Appointment Type ID: {product.appointment_type_id}")
print(f"Has Appointment: {bool(product.appointment_type_id)}")

# Expected output for cart-based service:
# Product: Karma Release
# Appointment Type ID: False
# Has Appointment: False
```

### Method 3: Via App Console (What You See Now)

When you open a service, check the console logs:

```
📄 ServiceDetailPageNew Build
   Service: Karma Release
   Widget hasAppointment: false        ← Should be false for cart
   Loaded service hasAppointment: null  ← null means no appointment type in Odoo
   Effective hasAppointment: false     ← Final decision
   Flow: PRODUCT (Cart)                ← Correct!
```

---

## 🗂️ Complete Service Type Matrix

| Service Type | Odoo Config | appointment_type_id | App Flow | UI Elements |
|-------------|-------------|---------------------|----------|-------------|
| **Appointment-Based** | Linked appointment type | Valid ID | Calendar | Date picker, time slots, consultant selection |
| **Digital/Instant** | No appointment type | null/false | Cart | Add to Cart, quantity, checkout |
| **Physical Product** | No appointment type, type=storable | null/false | Cart | Add to Cart, shipping address |

---

## ⚙️ Setting Up Your Services (Recommended Structure)

### Healing Category Services

#### **Appointment-Based** (Need consultant time):
- ✅ TRAUMA HEALING → Create appointment type
- ✅ Prosperity Healing → Create appointment type
- ✅ Manifestation Healing → Create appointment type
- ✅ Chakra Healing → Create appointment type (if 1-on-1 sessions)
- ✅ Extraction Healing → Create appointment type

#### **Digital/Instant** (No consultant time):
- ❌ Karma Release → No appointment type (instant energy work)
- ❌ Cutting Chords Healing → No appointment type (if self-service)
- ❌ Lemurian Healing → No appointment type (if recording/instant)

### Astrology Category Services

#### **Appointment-Based**:
- ✅ Personal Consultation → Create appointment type
- ✅ Couple Reading → Create appointment type
- ✅ Business Astrology → Create appointment type

#### **Digital/Instant**:
- ❌ Birth Chart Report → No appointment type (generated report)
- ❌ Yearly Forecast → No appointment type (PDF delivery)
- ❌ Compatibility Report → No appointment type (automated)

---

## 🔄 Migration Steps (For Your Current Setup)

Based on your screenshot, here's what you need to do:

### **Chakra Healing** - Decision Required

Currently showing as cart-based (no appointment type linked). You need to decide:

**Option A: Make it Appointment-Based**
```
1. Go to Appointments → Create New Appointment Type
   Name: "Chakra Healing"
   Duration: 15 minutes
   Staff: Your consultants
   Product: Chakra Healing (link it!)

2. Save

3. Refresh app → Now shows calendar
```

**Option B: Keep it Digital/Instant**
```
1. Do nothing in Odoo (keep appointment type empty)
2. It will continue showing "Add to Cart"
3. Customers buy and receive via email/instant access
```

### **Karma Release** - Already Correct ✅

You confirmed this has no appointment type in Odoo. Perfect!
- App correctly shows "Add to Cart"
- No changes needed

---

## 🎨 Odoo Custom Field Setup (Optional Enhancement)

For clearer service categorization, add a custom field:

### Step 1: Enable Developer Mode
```
Settings → Activate Developer Mode
```

### Step 2: Create Custom Field
```
Settings → Technical → Database Structure → Models
1. Search for: product.template
2. Click "Fields" → Create
3. Field Name: x_service_delivery_type
4. Field Label: Service Delivery Type
5. Field Type: Selection
6. Selection Options:
   - appointment: "Appointment Booking Required"
   - instant: "Instant/Digital Delivery"
   - physical: "Physical Product Shipping"
7. Save
```

### Step 3: Add to Product Form
```
Settings → Technical → User Interface → Views
1. Search for: product.template form
2. Edit form view
3. Add field in General Information section:
   <field name="x_service_delivery_type"/>
4. Save
```

### Step 4: Use in App (Future Enhancement)
```dart
// In odoo_models.dart, enhance detection:
final deliveryType = json['x_service_delivery_type'] as String?;
final hasAppointment = 
  deliveryType == 'appointment' || 
  (json['appointment_type_id'] != null && json['appointment_type_id'] != false);
```

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Orphaned Appointment Types
**Problem**: Appointment type exists but not linked to product
```
Appointment Type: "Chakra Healing" (no product)
Product: "Chakra Healing" (no appointment type)
Result: App shows cart instead of calendar
```
**Fix**: Link them properly using "Up-front Payment" section

### ❌ Mistake 2: Wrong Product Link
**Problem**: Appointment type linked to wrong product
```
Appointment Type: "Trauma Healing" → Product: "Chakra Healing"
Result: Wrong service gets calendar booking
```
**Fix**: Verify product links in each appointment type

### ❌ Mistake 3: Duplicate Names
**Problem**: Multiple appointment types with same name
```
Appointment Types:
- "Healing Session" (15 min)
- "Healing Session" (30 min)
Result: App can't distinguish
```
**Fix**: Use unique names (e.g., "Healing - 15min", "Healing - 30min")

### ❌ Mistake 4: Case Sensitivity
**Problem**: Product name doesn't match appointment type name exactly
```
Product: "chakra healing" (lowercase)
Appointment Type: "Chakra Healing" (title case)
Result: Fallback matching may fail
```
**Fix**: Use consistent naming (prefer Title Case)

---

## 📊 Data Model Reference

### Odoo Database Structure

```
appointment.type (appointment.appointment.type)
├── id (integer)
├── name (char)
├── duration (float) → in hours
├── product_id (many2one) → product.template ← KEY LINK!
├── staff_user_ids (many2many) → res.users
└── website_published (boolean)

product.template
├── id (integer)
├── name (char)
├── type (selection) → 'service', 'consu', 'product'
├── list_price (float)
├── appointment_type_id (many2one) → appointment.type ← KEY LINK!
└── [custom fields...]
```

### Flutter App Data Flow

```
1. OdooApiService.getServices()
   ↓ Fetches product.template with type='service'
   
2. OdooService.fromJson()
   ↓ Parses appointment_type_id field
   ↓ Sets hasAppointment = (appointment_type_id != null)
   
3. service_detail_screen.dart
   ↓ Builds service list with hasAppointment flag
   
4. ServiceDetailPageNew
   ↓ Shows calendar IF hasAppointment == true
   ↓ Shows cart IF hasAppointment == false
```

---

## 🎯 Quick Decision Tree

```
Do customers need to schedule a specific time with a consultant?
│
├─ YES → Appointment-Based Service
│   └─ Create appointment type in Odoo
│      └─ Link product in "Up-front Payment"
│         └─ App shows calendar booking
│
└─ NO → Digital/Instant Service
    └─ Leave appointment type empty
       └─ App shows Add to Cart
```

---

## ✅ Verification Checklist

After configuring your services in Odoo:

- [ ] Each appointment-based service has an appointment type created
- [ ] Each appointment type has "Product" field populated (Up-front Payment section)
- [ ] Each product shows appointment type in General Information tab
- [ ] Digital/instant services have NO appointment type linked
- [ ] All services have unique names (no duplicates)
- [ ] App console logs show correct hasAppointment values
- [ ] Calendar appears for appointment services
- [ ] Cart appears for digital services

---

## 🔧 Troubleshooting

### Problem: Service shows cart but should show calendar

**Check**:
1. Odoo: Does the service have an appointment type linked?
2. Appointment Type: Does it have the product linked?
3. App console: What does `Widget hasAppointment` show?

**Fix**: Link the appointment type to the product in Odoo

### Problem: Service shows calendar but should show cart

**Check**:
1. Odoo: Does the service have an appointment type incorrectly linked?
2. App console: What does `appointmentId` show?

**Fix**: Remove the appointment type link in Odoo (or delete the appointment type)

### Problem: All services showing same behavior

**Check**:
1. App logs: Look for "forceHealingAppointment" (should not exist after our fix)
2. Code: Check service_detail_screen.dart for forced logic

**Fix**: Already fixed! If still happening, clear app cache and rebuild

---

## 📞 Need Help?

If you're unsure about how to configure a specific service:

1. **Ask yourself**: "Does this service require a consultant's time at a specific scheduled slot?"
   - YES → Appointment type
   - NO → No appointment type

2. **Check the console**: Open the service in app and look at the logs
   - Shows "APPOINTMENT (Calendar)" → Appointment type is linked
   - Shows "PRODUCT (Cart)" → No appointment type

3. **Test both flows**: Configure one service each way and test the user experience

---

**Configuration Summary**:
- ✅ Appointment-based = Link appointment type in Odoo
- ✅ Digital/instant = Leave appointment type empty
- ✅ App automatically detects based on this configuration
- ✅ No code changes needed - it's all data-driven!
