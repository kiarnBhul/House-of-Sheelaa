# Quick Reference: Unified Appointment Booking Flow

## Files Modified/Created

| File | Type | Changes |
|------|------|---------|
| `lib/features/services/unified_appointment_booking_screen.dart` | **NEW** | Complete unified booking screen |
| `lib/main.dart` | Modified | Added route for unified booking |
| `lib/features/services/healing_detail_screen.dart` | Modified | Route to unified booking |
| `lib/features/services/service_detail_page_new.dart` | Modified | Route to unified booking |

## Route Information

**Route Name**: `/unified_appointment_booking`

**Required Arguments**:
- `appointmentTypeId` (int): ID of the appointment type
- `serviceName` (String): Name of the service

**Optional Arguments**:
- `price` (double): Service price
- `durationMinutes` (int): Duration in minutes
- `serviceImage` (String): URL to service image

## Navigation Example

```dart
Navigator.pushNamed(
  context,
  '/unified_appointment_booking',
  arguments: {
    'appointmentTypeId': 5,
    'serviceName': 'Healing Consultation',
    'price': 500.0,
    'durationMinutes': 60,
  },
);
```

## Screen Features (As Per Your Screenshot)

### Left/Top Panel: Calendar
- Month/Year display with navigation buttons
- Full calendar grid showing dates
- Past dates are disabled/greyed out
- Selected date highlighted in gradient (pink/ecstasy)
- Click date to update time slots

### Right/Bottom Panel: Time Slots
- Available time slots shown as selectable chips
- Time format: 12-hour with AM/PM (e.g., "9:00 am")
- Selected slot highlighted in gradient
- Auto-updates when date or consultant changes
- Shows "No available slots" message if none exist

### Service Info (Always Visible at Top)
- Service name
- Price
- Gradient icon background

### Additional UI Elements
- **Consultant Selector**: Shows if multiple consultants available
- **Timezone Selector**: Asia/Kolkata (default) or UTC
- **Loading Indicator**: Shows while fetching data
- **Error Message**: Displays if data fetch fails
- **Confirm Button**: Disabled until date & time selected

## State Management

The screen uses `_safeSetState` to prevent `setState` calls after disposal:

```dart
void _safeSetState(VoidCallback fn) {
  if (!mounted || _isDisposed) return;
  setState(fn);
}
```

## API Calls Made

1. **Load Staff**: `getAppointmentStaff(appointmentTypeId)`
2. **Load Slots**: `getAppointmentSlots(appointmentTypeId, date, staffId?)`
3. **Create Booking**: `createAppointmentBooking(...)`

## Error Handling

- Shows error banner if data loading fails
- Displays "No available slots" for empty slot lists
- Shows validation errors if user tries to book without selecting date/time
- Success snackbar shows booking confirmation with date and time
- Failure snackbar shows error message

## Testing Checklist

- [ ] Service detail screen opens unified booking on appointment-based services
- [ ] Calendar displays correctly with month navigation
- [ ] Past dates are disabled
- [ ] Time slots update when date changes
- [ ] Consultant selection appears only when multiple available
- [ ] Booking confirmation shows success message
- [ ] Navigate back works properly
- [ ] Loading indicators display during API calls
- [ ] Error messages display on API failures
