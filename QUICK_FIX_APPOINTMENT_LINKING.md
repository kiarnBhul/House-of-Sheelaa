# Quick Action Guide - Fix Appointment Type Not Showing

## 🎯 The Issue

You created an appointment type in Odoo and linked the product in "Up-front Payment", but the calendar still doesn't show in the app. This is showing "Add to Cart" instead.

---

## ✅ Solution Steps

### Option 1: Use Built-in Diagnostic Tool (EASIEST)

I've added a diagnostic tool to your app!

1. **Hot reload your Flutter app** (press `r` in terminal or save a file)
2. **Open the drawer menu** (hamburger icon top-left)
3. **Tap "Odoo Diagnostic"** (new option before "Help & Support")
4. **Tap "Run Diagnostic"** button
5. **Read the report** - it will tell you exactly what's wrong:
   - Which appointments are missing product links
   - Which products are missing appointment_type_id
   - Specific fix instructions for each issue

The diagnostic will show output like:
```
⚠️ Services missing appointment links:
   - Chakra Healing (Product ID: 2259)
     Matching appointment: Chakra Healing (ID: 14)
     Fix: Set appointment_type_id = 14 on product
```

### Option 2: Manual Check in Console

Watch the console when you open a service. You should see:
```
📦 Service: Chakra Healing
   Has Appointment: false           ← Should be true
   Appointment Type ID: null        ← Should show the ID
   Raw appointment_type_id: false   ← Should show [14, "Chakra Healing"]
```

If you see `false` or `null`, the link is missing on the product side.

---

## 🔧 How to Fix in Odoo

The problem is that setting the product in appointment type's "Up-front Payment" doesn't automatically set the reverse link. You need to manually set `appointment_type_id` on the product.

### Method 1: Python Shell (Quickest - 2 minutes)

If you have SSH access to your Odoo server:

```bash
# SSH into server
ssh user@your-server

# Open Odoo shell
cd /path/to/odoo
./odoo-bin shell -d your_database_name
```

```python
# Find your appointment type and product
apt = env['appointment.type'].search([('name', '=', 'Chakra Healing')])[0]
product = env['product.template'].search([('name', '=', 'Chakra Healing')])[0]

# Set the link
product.appointment_type_id = apt.id
env.cr.commit()

# Verify
print(f"✅ Linked! Product '{product.name}' → Appointment '{apt.name}'")
```

**Then restart your Flutter app** - calendar should now show!

### Method 2: Add Field to Odoo UI (Permanent solution)

This makes the field visible so you can click and select:

1. **Enable Developer Mode**:
   - Settings → Scroll to bottom → "Activate Developer Mode"

2. **Edit Product Form View**:
   - Settings → Technical → User Interface → Views
   - Search: "product.template.product.form"
   - Click on the form view
   - Click "Edit Architecture" button

3. **Add this XML** (inside a `<group>` tag):
```xml
<field name="appointment_type_id" 
       string="Appointment Type"
       domain="[('product_id', '=', False)]"/>
```

Example placement:
```xml
<group>
    <field name="name"/>
    <field name="type"/>
    <field name="list_price"/>
    <field name="appointment_type_id"/>  <!-- ADD THIS -->
</group>
```

4. **Save and refresh Odoo**

5. **Go to your product** (Sales → Products → Chakra Healing)

6. **You'll see "Appointment Type" dropdown** - select it!

7. **Save** - refresh Flutter app - done!

### Method 3: Check if Field Exists (If methods above fail)

The `appointment_type_id` field might not exist in your Odoo version. Check:

1. Settings → Technical → Database Structure → Models
2. Search: `product.template`
3. Click "Fields" button
4. Search: `appointment_type_id`
5. **If NOT found** → See "ODOO_APPOINTMENT_LINKING_FIX.md" for creating custom field

---

## 📊 Verification Checklist

After applying the fix, verify:

- [ ] **In Odoo**: Product shows appointment type field populated
- [ ] **In App Console**: `Raw appointment_type_id` shows `[14, "Chakra Healing"]` (not false)
- [ ] **In App UI**: Service shows calendar date picker (not "Add to Cart")
- [ ] **In Diagnostic Tool**: No warnings for that service

---

## 🎯 Quick Decision Tree

```
Can you access Odoo server SSH?
│
├─ YES → Use Method 1 (Python Shell) - 2 minutes
│
└─ NO → Can you access Odoo UI as admin?
    │
    ├─ YES → Use Method 2 (Add field to form) - 10 minutes
    │
    └─ NO → Contact your Odoo admin with the diagnostic report
```

---

## 📞 Next Steps

1. **Hot reload your app** to get the diagnostic tool
2. **Run the diagnostic** - it will tell you exactly what to fix
3. **Apply Method 1 or 2** based on your access level
4. **Restart the app** and test

---

## 📚 Documentation Reference

For detailed technical information, see:
- `ODOO_SERVICE_TYPE_CONFIGURATION_GUIDE.md` - Complete Odoo configuration guide
- `ODOO_APPOINTMENT_LINKING_FIX.md` - Deep troubleshooting guide
- `SERVICE_TYPE_BUG_FIX.md` - Technical details of the fix applied

---

**Status**: 
- ✅ Diagnostic tool added to app
- ✅ Enhanced logging added
- ✅ Fix methods documented
- ⏳ Waiting for you to run diagnostic and apply fix
