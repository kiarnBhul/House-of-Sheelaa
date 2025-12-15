# Odoo Appointment Type Linking - Troubleshooting & Manual Fix

## 🔍 Problem: Appointment Type Not Linking to Product

You've created an appointment type and linked the product in "Up-front Payment", but the calendar still doesn't show. This is because **Odoo's appointment.type model doesn't automatically set the reverse link on product.template**.

---

## 🎯 Root Cause

When you set the product in appointment type's "Up-front Payment" section:
```python
appointment.type.product_id = 123  # Links appointment → product
```

But this does NOT automatically set:
```python
product.template.appointment_type_id = 456  # Reverse link product → appointment
```

**The app reads `product.template.appointment_type_id`**, so if this field is empty, it won't detect the appointment.

---

## ✅ Solution: Manual Field Update

You need to manually set the `appointment_type_id` field on the product. Here are 3 methods:

---

## Method 1: Add Field to Product Form (RECOMMENDED)

This is the cleanest solution - make the field visible in the UI.

### Step 1: Enable Developer Mode
1. Go to **Settings** in Odoo
2. Scroll to bottom
3. Click **Activate Developer Mode**

### Step 2: Find the Product Template Model
1. Go to **Settings** → **Technical** → **Database Structure** → **Models**
2. Search for: `product.template`
3. Click on it

### Step 3: Check if appointment_type_id Field Exists
1. Click **Fields** button (top menu)
2. Search for: `appointment_type_id`
3. **If you find it**: Great! Proceed to Step 4
4. **If you DON'T find it**: The field doesn't exist in your Odoo version - see Method 3

### Step 4: Add Field to Product Form View
1. Go to **Settings** → **Technical** → **User Interface** → **Views**
2. Search for: `product.template.product.form` (or just "product template form")
3. Find the form view (type = "Form")
4. Click **Edit Architecture**
5. Find the section with `<group>` tags (usually in General Information)
6. Add this line inside a `<group>`:
```xml
<field name="appointment_type_id" 
       domain="[('product_id', '=', False)]"
       options="{'no_create': True}"/>
```

Example placement:
```xml
<group name="general">
    <field name="name"/>
    <field name="type"/>
    <field name="list_price"/>
    <field name="appointment_type_id" 
           domain="[('product_id', '=', False)]"
           options="{'no_create': True}"/>  <!-- ADD THIS -->
</group>
```

7. Save

### Step 5: Set Appointment Type on Product
1. Go to **Sales** → **Products** → [Your Service]
2. You should now see **Appointment Type** field
3. Select the appointment type from dropdown
4. Save
5. Refresh your Flutter app → Calendar should now show!

---

## Method 2: Use Odoo Python Shell (QUICK FIX)

If you have access to Odoo shell, you can directly set the field.

### Step 1: Open Odoo Shell
```bash
# SSH into your Odoo server
ssh user@your-odoo-server

# Open Odoo shell
cd /path/to/odoo
./odoo-bin shell -d your_database_name
```

### Step 2: Find Your Product and Appointment Type
```python
# Find the appointment type
apt = env['appointment.type'].search([('name', '=', 'Chakra Healing')])[0]
print(f"Appointment Type ID: {apt.id}")

# Find the product
product = env['product.template'].search([('name', '=', 'Chakra Healing')])[0]
print(f"Product ID: {product.id}")
print(f"Current appointment_type_id: {product.appointment_type_id}")
```

### Step 3: Set the Reverse Link
```python
# Set the appointment type on the product
product.appointment_type_id = apt.id
env.cr.commit()

print(f"Updated! Product now has appointment_type_id: {product.appointment_type_id}")
```

### Step 4: Verify
```python
# Verify the link works both ways
print(f"Appointment Type's Product: {apt.product_id.name}")
print(f"Product's Appointment Type: {product.appointment_type_id.name}")
```

### Step 5: Test in App
1. Stop and restart your Flutter app
2. Navigate to the service
3. Calendar should now appear!

---

## Method 3: Use Odoo XML-RPC API (FOR YOUR FLUTTER APP)

If the field doesn't exist in your Odoo, you can use a custom field or workaround.

### Check if Field Exists
Add this diagnostic code to your Flutter app:

```dart
// In lib/core/odoo/odoo_api_service.dart, add this method:

Future<void> diagnoseProductFields(int productId) async {
  try {
    final result = await _client.callKw({
      'model': 'product.template',
      'method': 'fields_get',
      'args': [],
      'kwargs': {
        'attributes': ['string', 'type', 'relation'],
      },
    });

    debugPrint('═══════════════════════════════════════');
    debugPrint('AVAILABLE FIELDS ON product.template:');
    result.forEach((fieldName, fieldInfo) {
      if (fieldName.contains('appoint') || fieldName.contains('type')) {
        debugPrint('  $fieldName: ${fieldInfo['string']} (${fieldInfo['type']})');
      }
    });
    debugPrint('═══════════════════════════════════════');

    // Now read the specific product
    final productData = await searchRead(
      model: 'product.template',
      domain: [['id', '=', productId]],
      fields: ['id', 'name', 'appointment_type_id'],
    );

    debugPrint('Product Data for ID $productId:');
    debugPrint('  ${productData[0]}');

  } catch (e) {
    debugPrint('Diagnostic failed: $e');
  }
}
```

Call this function and check the output to see what fields are available.

### If appointment_type_id Doesn't Exist - Create Custom Field

1. Go to **Settings** → **Technical** → **Database Structure** → **Models**
2. Search for: `product.template`
3. Click **Fields** → **Create**
4. Fill in:
   - **Field Name**: `x_appointment_type_id`
   - **Field Label**: Appointment Type
   - **Field Type**: Many2one
   - **Related Model**: `appointment.type`
   - **Required**: No
5. Save

Then update your Flutter app to read `x_appointment_type_id` instead:

```dart
// In lib/core/models/odoo_models.dart
final appointmentIdVal = json['x_appointment_type_id'] is List  // Try custom field first
    ? (json['x_appointment_type_id'] as List)[0] as int?
    : (json['x_appointment_type_id'] is int 
        ? json['x_appointment_type_id'] as int? 
        : (json['appointment_type_id'] is List  // Fallback to standard field
            ? (json['appointment_type_id'] as List)[0] as int?
            : (json['appointment_type_id'] is int ? json['appointment_type_id'] as int? : null)));
```

---

## Method 4: Use Automated Action (BEST LONG-TERM)

Set up an Odoo automated action to automatically sync the links.

### Step 1: Create Automated Action
1. Go to **Settings** → **Technical** → **Automation** → **Automated Actions**
2. Click **Create**

### Step 2: Configure Trigger
- **Model**: Appointment Type (`appointment.type`)
- **Trigger**: On Update
- **Apply On**: All records
- **Trigger Condition**: `product_id` is set

### Step 3: Set Python Code
```python
# When appointment.type.product_id is set, update the reverse link
if record.product_id:
    product = record.product_id
    if not product.appointment_type_id or product.appointment_type_id != record:
        product.appointment_type_id = record.id
```

### Step 4: Save & Test
1. Save the automated action
2. Go to any appointment type
3. Change the product in "Up-front Payment"
4. Save
5. Check the product - `appointment_type_id` should now be set automatically!

---

## 🧪 Testing & Verification

After applying any of the above methods:

### 1. Verify in Odoo
```python
# In Odoo Python shell or create a test script
product = env['product.template'].search([('name', '=', 'Chakra Healing')])[0]
apt = env['appointment.type'].search([('name', '=', 'Chakra Healing')])[0]

print("Bidirectional Link Check:")
print(f"Product → Appointment: {product.appointment_type_id.name if product.appointment_type_id else 'NOT SET'}")
print(f"Appointment → Product: {apt.product_id.name if apt.product_id else 'NOT SET'}")

# Both should be set!
```

### 2. Verify in Flutter App Console
After restarting the app, navigate to the service and check logs:

```
📦 Service: Chakra Healing
   Has Appointment: true           ← Should be true now
   Appointment Type ID: 14         ← Should show the ID
   Raw appointment_type_id: [14, "Chakra Healing"]  ← Odoo format
   Flow: APPOINTMENT (Calendar)    ← Should show calendar!
```

### 3. Visual Check in App
- Open service details
- Should see calendar date picker (not "Add to Cart")
- Should see consultant selection dropdown
- Should see time slot selection

---

## 🎯 Quick Decision: Which Method?

| Method | Best For | Difficulty | Permanent? |
|--------|----------|-----------|-----------|
| **Method 1** (Add field to form) | Production use | Medium | ✅ Yes |
| **Method 2** (Python shell) | Quick testing | Easy | ✅ Yes (if saved) |
| **Method 3** (Custom field) | If standard field missing | Medium | ✅ Yes |
| **Method 4** (Automated action) | Long-term automation | Hard | ✅ Yes |

**Recommendation**: 
- **For immediate fix**: Use Method 2 (Python shell)
- **For permanent solution**: Use Method 1 (Add field to form) + Method 4 (Automated action)

---

## 📞 Still Not Working?

If after trying these methods the calendar still doesn't show:

### Run Full Diagnostic

1. Check Odoo console logs for field errors
2. Check Flutter console for the enhanced logging output
3. Verify both links in Odoo:
   ```sql
   SELECT id, name, appointment_type_id FROM product_template WHERE name = 'Chakra Healing';
   SELECT id, name, product_id FROM appointment_type WHERE name = 'Chakra Healing';
   ```
4. Clear Flutter app cache:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Share These Details:
- Odoo version (e.g., 15.0, 16.0, 17.0)
- Appointment module version
- Console log output from the enhanced logging
- Screenshots of appointment type and product forms

---

**Next Step**: Try Method 2 (Python shell) first for immediate fix, then implement Method 1 for permanent solution.
