# 🎨 Unified Booking Screen - Visual & Code Guide

## Screen Layout Diagram

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ← Back  Service Name              ┃ AppBar
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

┌─────────────────────────────────────┐
│                                     │
│  ┌──────────────────────────────┐   │
│  │ 💜 Consultation              │   │  Service Info Card
│  │    ₹500 - 60 minutes         │   │
│  └──────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Select Consultant (if multiple)    │  Consultant Section (Optional)
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ John │ │ Sarah│ │ Emma │        │
│  └──────┘ └──────┘ └──────┘        │
└─────────────────────────────────────┘

┌─────────────────────┬───────────────┐
│                     │               │
│   CALENDAR          │ TIME SLOTS    │
│                     │               │
│   December 2025     │ Select a time │
│   < December >      │               │
│                     │ ┌──────────┐  │
│   Sun Mon Tue ...   │ │ 9:00 am  │  │
│  [  ] [ 1] [ 2]     │ ├──────────┤  │
│  [ 7] [■8 ] [ 9]    │ │10:00 am  │  │
│  [14] [15] [16]     │ ├──────────┤  │
│  [21] [22] [23]     │ │11:00 am  │  │
│  [28] [29] [30]     │ ├──────────┤  │
│                     │ │ 2:00 pm  │  │
│                     │ ├──────────┤  │
│                     │ │ 3:00 pm  │  │
│                     │ ├──────────┤  │
│                     │ │ 4:00 pm  │  │
│                     │ └──────────┘  │
│                     │               │
└─────────────────────┴───────────────┘

┌─────────────────────────────────────┐
│ Timezone: [Asia/Kolkata ▼]          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│                                     │
│   [  BOOK APPOINTMENT BUTTON  ]     │
│                                     │
└─────────────────────────────────────┘
```

## Color Scheme

| Element | Primary | Secondary | Text |
|---------|---------|-----------|------|
| Selected Date | #B5006E | #E84C3D | White |
| Selected Time | #B5006E | #E84C3D | White |
| Service Card | #6B4C8A | #E84C3D | Black |
| Button | #E84C3D | #B5006E | White |
| Disabled | #CCCCCC | #EEEEEE | Gray |
| Background | White | Light Gray | Black |

**Color Constants Used**:
- `BrandColors.cardinalPink` = #B5006E
- `BrandColors.ecstasy` = #E84C3D
- `BrandColors.jacaranda` = #6B4C8A
- `BrandColors.codGrey` = #222222
- `BrandColors.alabaster` = #FAFAF8

## State Variables Breakdown

```dart
// Loading/Error States
bool _isLoading = false;           // Initial data load
bool _isSlotsLoading = false;      // Slots API loading
String? _errorMessage = null;      // Error display

// Data Collections
List<OdooStaff> _staffMembers = []; // Available consultants
List<OdooAppointmentSlot> _availableSlots = []; // Available times

// Selected Values
DateTime _selectedDate = DateTime.now();      // Picked date
OdooAppointmentSlot? _selectedSlot = null;    // Picked time
int? _selectedStaffId = null;                 // Picked consultant
String _selectedTimezone = 'Asia/Kolkata';    // Picked timezone
```

## Key Methods Explained

### 1. `_loadInitialData()` - Initial Setup
```
Called in initState
├─ _loadStaffMembers()
│  └─ Fetches list of available consultants
└─ _loadAvailableSlots()
   └─ Fetches available times for today
```

### 2. `_onDateSelected(DateTime date)` - Date Changed
```
Called when calendar date tapped
├─ Update _selectedDate
├─ Clear _selectedSlot
└─ Call _loadAvailableSlots()
   └─ Fetch new times for selected date
```

### 3. `_onStaffSelected(int staffId)` - Consultant Changed
```
Called when consultant chip tapped
├─ Update _selectedStaffId
├─ Clear _selectedSlot
└─ Call _loadAvailableSlots()
   └─ Fetch new times for consultant
```

### 4. `_onSlotSelected(OdooAppointmentSlot slot)` - Time Selected
```
Called when time chip tapped
└─ Update _selectedSlot
   └─ Enable booking button
```

### 5. `_confirmBooking()` - Submit Booking
```
Called when "Book Appointment" tapped
├─ Validate (date & time selected)
├─ Call createAppointmentBooking API
├─ Handle success → show snackbar → pop screen
└─ Handle error → show snackbar → stay on screen
```

## UI Builder Methods

| Method | Purpose | Returns |
|--------|---------|---------|
| `_buildErrorWidget()` | Show error message | Widget |
| `_buildServiceInfoCard()` | Service details at top | Widget |
| `_buildConsultantSection()` | Consultant selector | List<Widget> |
| `_buildCalendarSection()` | Calendar picker | Widget |
| `_buildTimeSlotsSection()` | Time slot chips | Widget |
| `_buildTimezoneSection()` | Timezone dropdown | Widget |
| `_buildConfirmButton()` | Booking button | Widget |

## Data Flow Diagram

```
┌─────────────────┐
│  initState()    │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────┐
│ _loadInitialData()           │
├──────────────────────────────┤
│ ├─ _loadStaffMembers()       │
│ │  └─ getAppointmentStaff()  │
│ │     ↓ OdooApiService       │
│ │     ↓ _staffMembers        │
│ │                             │
│ └─ _loadAvailableSlots()     │
│    └─ getAppointmentSlots()  │
│       ↓ OdooApiService       │
│       ↓ _availableSlots      │
└──────────────────────────────┘
         │
         ▼
    ┌─────────────────────────┐
    │   UI Renders            │
    │   ├─ Calendar           │
    │   ├─ Time Slots         │
    │   ├─ Consultants        │
    │   └─ Service Info       │
    └──────────┬──────────────┘
               │
    ┌──────────▼────────────────────────┐
    │  User Interaction                │
    │  ├─ Date Changed?                │
    │  │  └─ _onDateSelected()         │
    │  │     └─ _loadAvailableSlots()  │
    │  │                                │
    │  ├─ Consultant Changed?          │
    │  │  └─ _onStaffSelected()        │
    │  │     └─ _loadAvailableSlots()  │
    │  │                                │
    │  ├─ Time Selected?               │
    │  │  └─ _onSlotSelected()         │
    │  │     └─ Enable Book Button     │
    │  │                                │
    │  └─ Book Clicked?                │
    │     └─ _confirmBooking()         │
    │        └─ createAppointmentBooking() │
    │           ├─ Success             │
    │           │  └─ Show Snackbar    │
    │           │  └─ Pop Screen       │
    │           │                      │
    │           └─ Error               │
    │              └─ Show Error       │
    └──────────────────────────────────┘
```

## Route Configuration

In `main.dart`:
```dart
UnifiedAppointmentBookingScreen.route: (context) {
  final args = ModalRoute.of(context)?.settings.arguments 
    as Map<String, dynamic>?;
  return UnifiedAppointmentBookingScreen(
    appointmentTypeId: args?['appointmentTypeId'] as int? ?? 0,
    serviceName: args?['serviceName'] as String? ?? 'Service',
    price: args?['price'] as double?,
    serviceImage: args?['serviceImage'] as String?,
    durationMinutes: args?['durationMinutes'] as int?,
  );
},
```

## Navigation Implementation

From any service detail screen:
```dart
Navigator.pushNamed(
  context,
  '/unified_appointment_booking', // Route name
  arguments: {
    'appointmentTypeId': 5,           // REQUIRED
    'serviceName': 'Consultation',    // REQUIRED
    'price': 500.0,                   // Optional
    'durationMinutes': 60,            // Optional
    'serviceImage': 'url/...',        // Optional
  },
);
```

## Error States

| Error | When | Display |
|-------|------|---------|
| Failed to load staff | API fails | Error banner + try again |
| Failed to load slots | API fails | Error banner + no slots |
| No slots available | Empty response | "No available slots for this date" |
| Booking failed | API error | Snackbar with error message |
| Missing date/time | User tries book without selecting | Validation snackbar |

## Loading States

```
Initial Load
├─ _isLoading = true
├─ Show CircularProgressIndicator
└─ Fetch staff + slots
   └─ _isLoading = false

Date Change
├─ _isSlotsLoading = true
├─ Show spinner in slots section
└─ Fetch new slots
   └─ _isSlotsLoading = false

Booking
├─ _isLoading = true
├─ Button shows spinner
└─ Submit booking
   └─ _isLoading = false
   └─ Pop screen or show error
```

## Responsive Behavior

| Screen Size | Layout | Behavior |
|------------|--------|----------|
| Mobile < 600px | Column | Stacked: Calendar on top, Slots below |
| Tablet 600-900px | Column | Stacked with wider padding |
| Desktop > 900px | Row (if space) | Side-by-side calendar & slots |

## Accessibility Features

✅ **Implemented**:
- Proper color contrast for readability
- Icon + text labels for buttons
- Clear error messages
- Loading indicators for long operations
- Disabled state for unavailable options

---

*All color codes and UI specifications can be found in `BrandColors` and `BrandTheme`*
