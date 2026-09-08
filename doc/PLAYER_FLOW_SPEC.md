# Player Flow Spec

## Purpose
- Define the core player experience for the MVP booking flow.
- Serve as the implementation reference for the first Flutter UI screens.

## Scope
- Player login entry
- Available slots browsing
- Slot selection
- Optional services selection
- Booking summary
- Manual/basic payment placeholder
- Booking confirmation

## User Journey
1. Player opens the app.
2. Player enters through a basic login flow.
3. Player sees available slots for a selected day.
4. Player selects one available slot.
5. Player reviews booking details.
6. Player optionally adds services.
7. Player proceeds through a manual/basic payment step.
8. Player sees booking confirmation.

## Screen Breakdown

### 1. Login Screen
- Goal:
  - Let the user enter the app with a simple MVP flow.
- Required Elements:
  - App title
  - Phone or name input placeholder
  - Login button
- MVP Behavior:
  - No advanced authentication required yet.
  - Can route the user into player flow directly in mock mode.

### 2. Available Slots Screen
- Goal:
  - Show the player available booking times.
- Required Elements:
  - Day selector or current day label
  - List of slots
  - Slot card with:
    - Time
    - Status
    - Price if needed
- MVP Behavior:
  - Available slots are selectable.
  - Booked slots are disabled.
  - Held slots can be shown as unavailable if included in mock data.

### 3. Booking Summary Screen
- Goal:
  - Confirm the selected slot and let the player customize the booking.
- Required Elements:
  - Selected slot time
  - Base booking price
  - Included ball indicator
  - Optional services list
  - Running total
  - Continue button
- MVP Behavior:
  - Ball is always included automatically.
  - Player can add only:
    - Drinks
    - Photography
    - Referee

### 4. Payment Placeholder Screen
- Goal:
  - Represent the MVP payment step without advanced integration.
- Required Elements:
  - Payment instructions or placeholder explanation
  - Total amount
  - Continue or confirm payment button
- MVP Behavior:
  - Uses manual/basic payment flow only.
  - No payment gateway integration.

### 5. Booking Confirmation Screen
- Goal:
  - Give the player clear success feedback.
- Required Elements:
  - Success message
  - Booking reference or mock booking id
  - Slot time
  - Selected services
  - Final total
- MVP Behavior:
  - Confirms that booking has been created in mock mode.

## Interaction Rules
- User cannot continue without selecting a slot.
- Booked slots must not be tappable.
- Ball cannot be removed from the booking.
- Services can be toggled on and off.
- Total updates when services change.
- Confirmation screen must reflect the exact final booking state.

## Data Needed For UI

### Slot
- `id`
- `time`
- `status`
- `price`

### Service
- `id`
- `name`
- `price`
- `selected`

### Booking Draft
- `selected_slot_id`
- `selected_services`
- `base_price`
- `total`

## Acceptance Criteria
- Player can reach the slots screen from login.
- Player can distinguish available and unavailable slots.
- Player can select one slot and proceed.
- Player sees that ball is included by default.
- Player can add drinks, photography, and referee only.
- Player sees the total update before confirmation.
- Player can complete the mock payment step.
- Player sees a final confirmation summary.

## Implementation Readiness
- Ready for conversion into Flutter screens once Phase 1 environment setup is completed.
