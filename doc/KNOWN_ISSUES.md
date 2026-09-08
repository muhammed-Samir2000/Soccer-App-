# Known Issues

## Current Limitations
- No real backend yet.
- Using mock data initially.
- No payment integration yet.
- No notifications yet.
- OTP contracts are prepared but no phone-number verification or SMS provider is connected.
- Booking confirmation reserves a QR payload and UI location, but does not render or scan a QR code yet.
- Notification toggles are stored in mock memory only; no push, SMS, WhatsApp, scheduled reminder, or marketing message is sent.
- Field allocation, recurring bookings, permissions, and match results are mock in-memory data. A real backend must enforce concurrent booking rules and persist all updates.
- Flutter SDK is available at `F:\Apps\flutter-sdk`, but its `bin` folder is not in `PATH`; the project currently invokes it by absolute path.
- Android emulators are listed by Flutter, but the attempted `Pixel_7` launch remained `offline`; a manual Android app run could not be completed. Resolve emulator boot/ADB readiness before Android release validation.
- The supported Chrome launch reached the Flutter debug-service connection wait during this session, but the tool session did not receive a completed connection confirmation; repeat an interactive Chrome run before release validation.
