# Code Structure Overview

## UnifiedAppointmentBookingScreen - Main Class Structure

```dart
class UnifiedAppointmentBookingScreen extends StatefulWidget
  └─ const UnifiedAppointmentBookingScreen()
     ├─ appointmentTypeId: int (required)
     ├─ serviceName: String (required)
     ├─ price: double? (optional)
     ├─ serviceImage: String? (optional)
     └─ durationMinutes: int? (optional)

class _UnifiedAppointmentBookingScreenState extends State<UnifiedAppointmentBookingScreen>
  │
  ├─ Properties:
  │  ├─ final OdooApiService _apiService
  │  ├─ bool _isDisposed
  │  ├─ bool _isLoading
  │  ├─ bool _isSlotsLoading
  │  ├─ String? _errorMessage
  │  ├─ List<OdooStaff> _staffMembers
  │  ├─ List<OdooAppointmentSlot> _availableSlots
  │  ├─ DateTime _selectedDate
  │  ├─ OdooAppointmentSlot? _selectedSlot
  │  ├─ int? _selectedStaffId
  │  ├─ String _selectedTimezone
  │  └─ const List<String> _timezones
  │
  ├─ Lifecycle Methods:
  │  ├─ initState()
  │  │  └─ _loadInitialData()
  │  └─ dispose()
  │     └─ _isDisposed = true
  │
  ├─ Core Business Logic:
  │  ├─ _safeSetState(VoidCallback fn)
  │  │  └─ Safely calls setState with disposal check
  │  │
  │  ├─ _loadInitialData() async
  │  │  ├─ Set loading = true
  │  │  ├─ _loadStaffMembers()
  │  │  ├─ _loadAvailableSlots()
  │  │  └─ Set loading = false
  │  │
  │  ├─ _loadStaffMembers() async
  │  │  ├─ Call odooApi.getAppointmentStaff()
  │  │  ├─ Update _staffMembers
  │  │  └─ Auto-select if only one
  │  │
  │  ├─ _loadAvailableSlots() async
  │  │  ├─ Set isSlotsLoading = true
  │  │  ├─ Call odooApi.getAppointmentSlots()
  │  │  ├─ Update _availableSlots
  │  │  └─ Set isSlotsLoading = false
  │  │
  │  ├─ _onDateSelected(DateTime date)
  │  │  ├─ Update _selectedDate
  │  │  ├─ Clear _selectedSlot
  │  │  └─ Call _loadAvailableSlots()
  │  │
  │  ├─ _onStaffSelected(int staffId)
  │  │  ├─ Update _selectedStaffId
  │  │  ├─ Clear _selectedSlot
  │  │  └─ Call _loadAvailableSlots()
  │  │
  │  ├─ _onSlotSelected(OdooAppointmentSlot slot)
  │  │  └─ Update _selectedSlot
  │  │
  │  └─ _confirmBooking() async
  │     ├─ Validate selections
  │     ├─ Call odooApi.createAppointmentBooking()
  │     ├─ Show success snackbar
  │     ├─ Pop screen
  │     └─ Or show error on failure
  │
  └─ UI Builder Methods:
     ├─ build(BuildContext context)
     │  └─ Main Scaffold with SafeArea → SingleChildScrollView → Column
     │
     ├─ _buildErrorWidget(TextTheme tt)
     │  └─ Container with red background + error icon + message
     │
     ├─ _buildServiceInfoCard(TextTheme tt)
     │  └─ Container with service name, icon, price
     │
     ├─ _buildConsultantSection(TextTheme tt)
     │  └─ List<Widget> with consultant selector chips
     │
     ├─ _buildCalendarSection(TextTheme tt)
     │  └─ Container with:
     │     ├─ Month/year header with nav buttons
     │     ├─ Day labels (Sun, Mon, ...)
     │     └─ GridView of date buttons
     │
     ├─ _buildTimeSlotsSection(TextTheme tt)
     │  └─ Column with:
     │     ├─ Loading indicator (conditional)
     │     ├─ No slots message (conditional)
     │     └─ Wrap of time slot chips
     │
     ├─ _buildTimezoneSection(TextTheme tt)
     │  └─ Row with dropdown selector
     │
     └─ _buildConfirmButton(TextTheme tt)
        └─ ElevatedButton (disabled until ready)
```

## Main.dart Route Configuration

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

## Integration Points

### From healing_detail_screen.dart
```dart
_handleBookAppointment() {
  Navigator.pushNamed(
    context,
    '/unified_appointment_booking',
    arguments: {
      'appointmentTypeId': widget.serviceId,
      'serviceName': widget.serviceName,
      'price': widget.price ?? _serviceDetails?.price ?? 0.0,
      'durationMinutes': widget.durationMinutes,
    },
  );
}
```

### From service_detail_page_new.dart
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.pushNamed(
      context,
      '/unified_appointment_booking',
      arguments: {
        'appointmentTypeId': appointmentId,
        'serviceName': widget.serviceName,
        'price': widget.price ?? 0.0,
        'durationMinutes': widget.durationMinutes,
      },
    );
  },
  ...
)
```

## API Service Integration

### Calls Made
```dart
// 1. Get Staff
List<OdooStaff> staff = await odooApi.getAppointmentStaff(
  appointmentTypeId: int
);

// 2. Get Slots
List<OdooAppointmentSlot> slots = await odooApi.getAppointmentSlots(
  appointmentTypeId: int,
  date: DateTime,
  staffId: int? (optional)
);

// 3. Create Booking
Map<String, dynamic> result = await odooApi.createAppointmentBooking(
  appointmentTypeId: int,
  dateTime: DateTime,
  staffId: int,
  customerName: String,
  customerEmail: String,
  customerPhone: String,
  notes: String
);
```

## Data Models Used

```dart
// OdooStaff
class OdooStaff {
  int id;
  String name;
  // ... other fields
}

// OdooAppointmentSlot
class OdooAppointmentSlot {
  DateTime startTime;
  DateTime endTime;
  int staffId;
  String? staffName;
  // ... other fields
}
```

## Widget Tree Structure

```
Scaffold
├─ AppBar
│  ├─ Leading: Back Button
│  └─ Title: Service Name
│
└─ Body
   ├─ CircularProgressIndicator (if loading)
   │
   └─ SafeArea
      └─ SingleChildScrollView
         └─ Padding
            └─ Column
               ├─ ErrorWidget (if error)
               ├─ ServiceInfoCard
               ├─ ConsultantSection (if multiple)
               ├─ CalendarSection
               │  ├─ Navigation Row (prev/next)
               │  ├─ Day Labels Row
               │  └─ GridView (calendar grid)
               ├─ TimeSlotsSection
               │  └─ Wrap (time chips)
               │     or Loading
               │     or No Slots Message
               ├─ TimezoneSection
               │  └─ DropdownButton
               ├─ ConfirmButton
               └─ Bottom Spacing
```

## State Management Pattern

```
setState Called
    ↓
_safeSetState(fn)
    ├─ Check if mounted
    ├─ Check if _isDisposed
    ├─ If safe: setState(fn)
    └─ If not: return (no-op)

This prevents:
- setState after dispose errors
- Memory leaks
- Null reference errors
```

## Error Handling Layers

```
Layer 1: Try-Catch in Methods
  └─ Catches API errors
  └─ Sets _errorMessage
  └─ Updates UI with error state

Layer 2: Validation Before Operations
  └─ Checks for required selections
  └─ Shows snackbar for missing input
  └─ Prevents invalid bookings

Layer 3: UI Error Display
  └─ Error banner at top
  └─ Disabled states
  └─ Helpful error messages

Layer 4: Fallback UI States
  └─ No slots message
  └─ Loading indicators
  └─ Empty state handling
```

## Responsive Layout Behavior

```
Mobile (< 600px)
  └─ Stacked Layout (Column)
     ├─ Service Info Card (full width)
     ├─ Consultant Section (if exists)
     ├─ Calendar (full width)
     ├─ Time Slots (full width)
     ├─ Timezone (full width)
     └─ Button (full width)

Tablet (600-900px)
  └─ Same as mobile with wider padding

Desktop (> 900px)
  └─ Could use Row for calendar + slots
     (Currently uses Column, can be enhanced)
```

## Performance Optimizations

```
1. Memoized Calculations
   └─ Calendar month/year calculated once

2. Efficient List Rendering
   └─ Uses .map().toList() instead of manual loops

3. Minimal Rebuilds
   └─ Only rebuilds affected widgets on state change

4. Safe Navigation
   └─ Null-coalescing and null-checking throughout

5. Smart API Calls
   └─ Only calls API when necessary
   └─ Reuses data when possible
```

---

This structure ensures:
✅ Clean, maintainable code
✅ Proper separation of concerns
✅ Safe state management
✅ Efficient rendering
✅ Comprehensive error handling
✅ Professional UX
