# SPECKIT - Flutter Implementation Contract

## 1. Purpose And Authority

This document is the execution contract for the Football Playground Booking MVP. It tells a human developer or an AI coding agent what to build, how to structure the code, how to validate work, and how to hand off to the next phase.

Priority when documents disagree:

1. `SPECKIT.md`
2. `DECISIONS_LOG.md`
3. `SYSTEM_CONTEXT.md`
4. `WORKFLOW_LOG.md`
5. Older planning documents

The active stack is **Flutter and Dart**. References to React Native in older documents are obsolete and must not be used for implementation.

## 2. Product Definition

Build an Android-first mobile MVP for booking football playground time slots. The MVP validates the booking journey with mock data before a real backend is connected.

Users:

- `Player`: logs in, browses slots, creates a booking, selects optional services, completes a manual payment placeholder, and sees confirmation.
- `Admin`: views bookings and their status.

## 3. MVP Scope

Included:

- Basic mock login
- Available slots by day
- Slot selection and booking draft
- Optional services: drinks, photography, referee
- Booking summary and price total
- Manual/basic payment placeholder
- Booking confirmation
- Admin bookings list

Excluded until a later approved phase:

- WhatsApp and push notifications
- Real payment gateway or receipt verification
- Reports, offers, loyalty, tournaments
- Real Supabase integration

Business rules:

- A ball is included in every booking, with no option to remove it.
- Only `available` slots can be selected; `held` and `booked` slots are unavailable.
- Services can be selected and removed; the total updates immediately.
- Confirmation must match the final booking draft exactly.
- The app has only two roles: `player` and `admin`.

## 4. Engineering Standards

- Use stable Flutter and Dart tools. Run `flutter doctor` before initialization and record the result in `WORKFLOW_LOG.md`.
- Keep the app null-safe, formatted with `dart format`, and free of analyzer errors.
- Build small, focused widgets. A screen coordinates state and layout; reusable widgets render focused UI pieces.
- Do not place mock data, navigation logic, or pricing calculations inside presentation widgets.
- Use immutable domain models with `const` constructors where possible.
- Use repositories/interfaces so mock data can later be replaced by Supabase without rewriting screens.
- Prefer readable names, simple control flow, and explicit types at boundaries. Do not add abstractions until they solve a concrete need.
- Add tests for business rules and repository behavior. Add widget tests for critical screens and user-visible states.
- Never hard-code secrets, API keys, or production URLs.
- Every phase must update `WORKFLOW_LOG.md`, run its verification commands, and leave the next-phase prompt at the end of the final response.

## 5. Target Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    utils/
  features/
    auth/
      data/
      domain/
      presentation/
    slots/
      data/
      domain/
      presentation/
    bookings/
      data/
      domain/
      presentation/
    admin/
      presentation/
  shared/
    widgets/
  main.dart
test/
  features/
```

Use this structure as a destination, not busywork. Create folders only when the phase needs them. Dependencies flow inward: presentation depends on domain contracts; data implements those contracts; domain does not depend on Flutter UI or a backend SDK.

## 6. Data Contracts

Minimum models:

- `AppUser(id, name, role)` where role is `player` or `admin`
- `Playground(id, name, basePrice)`
- `TimeSlot(id, date, startTime, endTime, status)` where status is `available`, `held`, or `booked`
- `OptionalService(id, name, price)`
- `BookingDraft(slot, selectedServices, basePrice)` with a calculated total
- `Booking(id, playerId, slot, services, total, status)`
- `Payment(bookingId, method, status)`

The booking total is calculated in domain logic: `basePrice + sum(selected service prices)`. The included ball has no optional-service entry and does not change the price.

## 7. Phased Delivery Plan

### Phase 0 - Environment And Foundation

Goal: create a runnable Flutter application with a maintainable starting structure.

Start prompt:

```text
Start Phase 0: Environment And Foundation for the Football Playground Booking MVP.

Read `doc/SPECKIT.md`, `doc/WORKFLOW_LOG.md`, and `doc/DECISIONS_LOG.md` before editing. This project uses Flutter and Dart only; legacy React Native references are obsolete. Inspect the current workspace and preserve all existing documentation and user changes.

First run `flutter doctor` and record its outcome in `doc/WORKFLOW_LOG.md`. If Flutter is ready, initialize the Flutter project at the repository root, then establish the baseline structure described in SPECKIT, app theme, routing shell, a minimal launch screen, and a smoke test. Keep the application null-safe, avoid secrets, and do not add backend or out-of-scope MVP features.

Run `dart format --set-exit-if-changed .`, `flutter analyze`, and `flutter test`; perform an emulator or supported-target launch if available. Update `doc/WORKFLOW_LOG.md` after each meaningful action and update `doc/CURRENT_PHASE.md`, `doc/NEXT_TASK.md`, and `doc/KNOWN_ISSUES.md` to reflect the outcome.

At the end of your response, provide only the exact Phase 1 prompt from `doc/SPECKIT.md` so the user can copy it to begin the next phase.
```

Deliverables:

- Verify Flutter environment and record `flutter doctor` result.
- Create the Flutter project in the repository root.
- Add the baseline folder structure, app theme, and routing shell.
- Add a minimal launch screen proving navigation works.
- Configure analyzer and a passing smoke test.

Acceptance criteria:

- `flutter analyze` passes.
- `flutter test` passes.
- The application starts on an Android emulator or supported target.

Completion prompt for the next phase:

```text
Continue the Football Playground Booking MVP from Phase 1: Core Player Experience.

Read `doc/SPECKIT.md`, `doc/WORKFLOW_LOG.md`, and `doc/DECISIONS_LOG.md` before editing. The project must remain Flutter/Dart only. Review the workflow log to understand the exact current state and preserve existing work.

Implement the player entry and slot browsing slice using mock data: a basic role-aware mock login, an available-slots screen with a day label/selector, and clear available, held, and booked states. Only available slots can be tapped. Use domain models and repository contracts; do not put mock data inside widgets. Add focused tests, run formatting/analyzer/tests, then update `doc/WORKFLOW_LOG.md` with every meaningful action and result.

At the end of your response, provide only the exact Phase 2 prompt from `doc/SPECKIT.md` so the user can copy it to begin the next phase.
```

### Phase 1 - Core Player Experience

Goal: allow a player to enter the app and select an available time slot.

Deliverables:

- Mock login/entry with player role.
- Slot models, mock repository, and slot status UI.
- Day selection or a clearly labelled current day.
- Navigation from an available slot to booking summary.

Acceptance criteria:

- Booked and held slots are visibly unavailable and cannot be selected.
- An available slot opens the booking summary route.
- Tests cover slot availability behavior.

Completion prompt for the next phase:

```text
Continue the Football Playground Booking MVP from Phase 2: Booking Draft And Optional Services.

Read `doc/SPECKIT.md`, `doc/WORKFLOW_LOG.md`, and `doc/DECISIONS_LOG.md` before editing. Preserve the completed Flutter structure and player slot-selection flow.

Implement the booking summary for the selected slot. It must show the base price, the included ball as non-removable, and toggles for only drinks, photography, and referee. Store the selection in a BookingDraft/domain state object and calculate the total outside presentation widgets. The user must be able to continue only when a slot is selected. Add unit tests for total calculation and widget tests for service selection. Run formatting, analyzer, and tests; record all work in `doc/WORKFLOW_LOG.md`.

At the end of your response, provide only the exact Phase 3 prompt from `doc/SPECKIT.md`.
```

### Phase 2 - Booking Draft And Optional Services

Goal: produce a correct, reviewable booking draft.

Deliverables:

- Booking summary screen.
- Optional-service selection and calculated total.
- Domain validation for a selected slot.
- Handoff to payment placeholder.

Acceptance criteria:

- Ball remains included and cannot be removed.
- Total changes correctly as services are toggled.
- Only allowed services are available.

Completion prompt for the next phase:

```text
Continue the Football Playground Booking MVP from Phase 3: Payment Placeholder And Confirmation.

Read `doc/SPECKIT.md`, `doc/WORKFLOW_LOG.md`, and `doc/DECISIONS_LOG.md` before editing. Keep the existing booking draft and pricing rules intact.

Add a manual/basic payment placeholder screen; do not integrate a real payment provider. On completion, create a mock Booking from the validated draft and show a confirmation screen with booking reference, slot time, selected services, and final total. The confirmation data must exactly match the draft. Add tests for booking creation and confirmation rendering. Run formatting, analyzer, and tests; update `doc/WORKFLOW_LOG.md`.

At the end of your response, provide only the exact Phase 4 prompt from `doc/SPECKIT.md`.
```

### Phase 3 - Payment Placeholder And Confirmation

Goal: complete the player journey with transparent mock-payment behavior.

Deliverables:

- Manual payment instruction/placeholder screen.
- Mock booking creation.
- Confirmation screen with full final details.

Acceptance criteria:

- No live payment integration is introduced.
- Confirmation reflects the finalized booking exactly.
- Completed bookings can be exposed to the admin mock repository.

Completion prompt for the next phase:

```text
Continue the Football Playground Booking MVP from Phase 4: Basic Admin Bookings.

Read `doc/SPECKIT.md`, `doc/WORKFLOW_LOG.md`, and `doc/DECISIONS_LOG.md` before editing. Preserve player flow behavior and use the same booking domain model.

Implement a basic admin entry and bookings list. Each row must show player name, slot/date/time, booking status, selected optional services, and total. Use the repository contract, not widget-local mock lists. Keep scope limited to viewing bookings; do not add reports, offers, or real payment approval. Add tests for mapping booking data to the list states. Run formatting, analyzer, and tests; update `doc/WORKFLOW_LOG.md`.

At the end of your response, provide only the exact Phase 5 prompt from `doc/SPECKIT.md`.
```

### Phase 4 - Basic Admin Bookings

Goal: let an admin inspect the bookings created in mock mode.

Deliverables:

- Admin entry/navigation.
- Bookings list and clear empty/loading/error presentation states where relevant.
- Reuse of shared booking domain model.

Acceptance criteria:

- Admin can see mock/completed bookings with correct details.
- No out-of-scope administration features are implemented.

Completion prompt for the next phase:

```text
Continue the Football Playground Booking MVP from Phase 5: Supabase Readiness And Quality Gate.

Read `doc/SPECKIT.md`, `doc/WORKFLOW_LOG.md`, and `doc/DECISIONS_LOG.md` before editing. Do not connect a real Supabase project unless credentials and explicit approval are provided.

Refine repository interfaces and dependency boundaries so mock implementations can later be replaced by Supabase. Add configuration placeholders that contain no secrets, improve error/empty states where missing, and perform the MVP quality gate: formatting, analyzer, unit/widget tests, and a manual emulator run. Document any known limitations in `doc/KNOWN_ISSUES.md` and all results in `doc/WORKFLOW_LOG.md`.

At the end of your response, provide the final completion summary and state that no further phase should start without an approved backend scope.
```

### Phase 5 - Supabase Readiness And Quality Gate

Goal: finish an MVP that is maintainable and ready for a later backend connection.

Deliverables:

- Repository contracts isolated from mock implementations.
- No secrets in source control; documented configuration requirements only.
- Quality checks and known limitations recorded.

Acceptance criteria:

- Player completes the mock booking flow.
- Admin can view bookings.
- `dart format --set-exit-if-changed .`, `flutter analyze`, and `flutter test` pass.
- The workflow log accurately reflects implementation and verification.

## 8. Mandatory Agent Handoff Protocol

For every future coding session:

1. Read this file, `WORKFLOW_LOG.md`, and `DECISIONS_LOG.md` before changing files.
2. Inspect the current source tree and existing tests; never overwrite unrelated user work.
3. Work only on the active phase and its acceptance criteria.
4. Update `WORKFLOW_LOG.md` after each meaningful action, decision, test run, blocker, or completed deliverable.
5. Run the required verification commands before claiming a phase is complete.
6. Update `CURRENT_PHASE.md`, `NEXT_TASK.md`, and `KNOWN_ISSUES.md` when their state changes.
7. At the very end of a successfully completed phase, output the exact next-phase prompt from this document, with no edits, so the user can copy it.
8. After every completed user-requested change set, run the required verification, review `git status`, create a descriptive Git commit, and push it to the configured `origin/main`. Record the commit hash and push outcome in `WORKFLOW_LOG.md`. Do not commit secrets, generated build outputs, or local logs.

If blocked, record the blocker and the exact recovery action in `WORKFLOW_LOG.md`; do not silently skip verification or move to the next phase.

## 9. Global Definition Of Done

The MVP is complete when a player can log in, browse slots, select an available one, add allowed services, complete the manual payment placeholder, and receive a correct booking confirmation; an admin can view bookings; and all quality checks pass.
