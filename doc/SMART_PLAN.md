# Smart Plan

## Objective
- Deliver a working mobile MVP for football playground booking.
- Prioritize the shortest path to validating the booking experience.
- Keep implementation aligned with the documented MVP scope only.

## Scope Baseline
- Included:
  - Basic login
  - View available slots
  - Book a slot
  - Add optional services
  - Basic/manual payment placeholder
  - Booking confirmation
  - Admin view bookings
- Excluded:
  - WhatsApp integration
  - Push notifications
  - Advanced payments
  - Reports
  - Loyalty system

## Planning Principles
- Build UI-first with mock data before backend integration.
- Keep architecture scalable from day one.
- Avoid implementing features excluded from the MVP.
- Convert broad requirements into small, testable deliverables.

## Execution Phases

### Phase 1: Foundation
- Initialize Flutter project with Dart.
- Create clean folder structure for screens, widgets, data, models, and services.
- Add base navigation and theme setup.
- Define shared Dart models for user, slot, booking, payment, and service.

### Phase 2: Core Player Experience
- Build login screen with basic placeholder flow.
- Build available slots screen using mock data.
- Build slot details or booking summary screen.
- Allow selection of optional services:
  - Drinks
  - Photography
  - Referee
- Enforce business rule that ball is included by default.

### Phase 3: Booking Flow
- Create booking review screen.
- Add manual/basic payment placeholder step.
- Create booking confirmation screen.
- Store booking state locally or in mock service layer.

### Phase 4: Basic Admin Experience
- Build admin bookings list screen.
- Show booking status and selected services.
- Support simple status updates in mock mode if needed.

### Phase 5: Backend Readiness
- Prepare service layer boundaries for future Supabase integration.
- Isolate mock repositories from UI logic.
- Keep authentication and booking APIs abstracted behind service modules.

## Prioritized Delivery Order
1. App initialization
2. Project structure
3. Navigation shell
4. Available slots UI
5. Booking flow UI
6. Optional services logic
7. Payment placeholder
8. Booking confirmation
9. Admin bookings view
10. Supabase-ready service layer

## Milestones

### Milestone 1
- Flutter app runs successfully.
- Folder structure is ready.
- Navigation is working.

### Milestone 2
- Player can browse available slots.
- Player can start and complete a mock booking flow.

### Milestone 3
- Optional services and payment placeholder are connected to the booking summary.
- Confirmation screen reflects final booking details.

### Milestone 4
- Admin can view bookings in a basic dashboard/list screen.
- Codebase is prepared for later Supabase integration.

## Risks And Controls
- Risk: Old docs still mention notifications and richer payments.
  - Control: Treat `MVP Scope.md`, `SYSTEM_CONTEXT.md`, and `DECISIONS_LOG.md` as the active source of truth.
- Risk: Backend work may slow delivery.
  - Control: Use mock data first and keep backend behind interfaces.
- Risk: UI grows without structure.
  - Control: Start with scalable folders and shared types/components.

## Definition Of Success
- A user can open the app, view slots, create a booking, add optional services, complete a manual payment step, and see confirmation.
- An admin can view bookings.
- The project is ready to replace mock data with Supabase later.

## Immediate Next Action
- Initialize Flutter project with Dart and a scalable structure.
