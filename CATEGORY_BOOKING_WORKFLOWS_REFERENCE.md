# Quick Reference: Category-Based Booking Workflows

## Current Implementation Status

### ✅ Healing Category
**Status**: Fully Implemented  
**Screen**: `UnifiedAppointmentBookingScreen`  
**Features**:
- Calendar grid with month navigation
- Real-time time slot availability
- Consultant selection
- Single-screen booking experience

**Entry Points**:
- `healing_detail_screen.dart` → Always routes to unified booking
- `service_detail_page_new.dart` → Routes to unified booking if `categoryName.contains('healing')`

---

### ⏳ Numerology
**Status**: Partial (has custom form)  
**Screen**: `NumerologyServiceFormScreen`  
**Next Steps**: Discuss integration with booking system

---

### ⏳ Card Reading
**Status**: Not Yet Implemented  
**Next Steps**: 
1. Discuss unique workflow requirements
2. Design card reading booking experience
3. Implement category-specific screen

---

### ⏳ Rituals
**Status**: Not Yet Implemented  
**Next Steps**:
1. Discuss unique workflow requirements
2. Design rituals booking experience
3. Implement category-specific screen

---

## How to Add a New Category Workflow

### Step 1: Check Category in `service_detail_page_new.dart`

```dart
final isHealingCategory = widget.categoryName?.toLowerCase().contains('healing') ?? false;
final isNumerologyCategory = widget.categoryName?.toLowerCase().contains('numerology') ?? false;
final isCardReadingCategory = widget.categoryName?.toLowerCase().contains('card reading') ?? false;
// Add more as needed

if (isHealingCategory) {
  // Navigate to unified booking
} else if (isNumerologyCategory) {
  // Navigate to numerology form
} else if (isCardReadingCategory) {
  // Navigate to card reading booking
} else {
  // Show coming soon message
}
```

### Step 2: Create Category-Specific Screen

Create a new file like:
- `lib/features/services/card_reading_booking_screen.dart`
- `lib/features/services/rituals_booking_screen.dart`

### Step 3: Register Route in `main.dart`

```dart
case '/card_reading_booking':
  return MaterialPageRoute(
    builder: (_) => CardReadingBookingScreen(...),
  );
```

### Step 4: Test the Flow

1. Navigate to service category
2. Select a service
3. Verify correct booking screen appears
4. Complete booking flow

---

## Important Notes

⚠️ **Do NOT** use `UnifiedAppointmentBookingScreen` for non-Healing services  
⚠️ Each category may have unique requirements - discuss before implementing  
⚠️ Always check `categoryName` before routing to category-specific screens  

---

## Quick Checklist for Each Category

- [ ] Discuss unique workflow requirements
- [ ] Design booking screen mockup
- [ ] Implement category-specific screen
- [ ] Add route in `main.dart`
- [ ] Update `service_detail_page_new.dart` routing logic
- [ ] Test complete flow
- [ ] Document in this guide

---

## Code Locations

| Component | File Path |
|-----------|-----------|
| Unified Booking (Healing) | `lib/features/services/unified_appointment_booking_screen.dart` |
| Service Detail Page | `lib/features/services/service_detail_page_new.dart` |
| Healing Detail Screen | `lib/features/services/healing_detail_screen.dart` |
| Numerology Form | `lib/features/services/numerology_service_form_screen.dart` |
| Service Listing | `lib/features/services/service_detail_screen.dart` |
| App Routing | `lib/main.dart` |

---

## Summary

Currently, **only Healing category uses the unified appointment booking**. All other categories will be implemented one-by-one with their own unique workflows as discussed with requirements.
