import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_match_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_match.dart';
import 'package:soccer_booking_app/features/bookings/domain/match_participant.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  final Booking booking = Booking(
    reference: 'HAGZ-TEAM-1',
    playerId: 'organizer-1',
    playerName: 'الكابتن أحمد',
    slot: TimeSlot(
      id: 'team-slot',
      startTime: DateTime(2026, 9, 15, 19),
      endTime: DateTime(2026, 9, 15, 20),
      status: SlotStatus.booked,
    ),
    services: const [],
    totalPrice: 800,
    status: BookingStatus.confirmed,
    fieldNumber: 1,
  );

  test('creates one match with the booking organizer already going', () async {
    final MockMatchRepository repository = MockMatchRepository();

    final BookingMatch first = await repository.getOrCreateForBooking(booking);
    final BookingMatch second = await repository.getOrCreateForBooking(booking);

    expect(first, same(second));
    expect(first.capacity, 10);
    expect(first.goingCount, 1);
    expect(first.participants.single.isOrganizer, isTrue);
    expect(first.participants.single.status, MatchParticipationStatus.going);
  });

  test(
    'records an invitee response without exposing contact details',
    () async {
      final MockMatchRepository repository = MockMatchRepository();
      final BookingMatch match = await repository.getOrCreateForBooking(
        booking,
        capacity: 3,
      );

      final BookingMatch updated = await repository.respondToInvite(
        inviteToken: match.inviteToken,
        playerId: 'player-2',
        playerName: 'كابتن علي',
        status: MatchParticipationStatus.going,
      );

      expect(updated.goingCount, 2);
      expect(updated.participants.last.displayName, 'كابتن علي');
      expect(updated.participants.last.status, MatchParticipationStatus.going);
    },
  );

  test('does not allow the going count to exceed match capacity', () async {
    final MockMatchRepository repository = MockMatchRepository();
    final BookingMatch match = await repository.getOrCreateForBooking(
      booking,
      capacity: 2,
    );
    await repository.respondToInvite(
      inviteToken: match.inviteToken,
      playerId: 'player-2',
      playerName: 'كابتن علي',
      status: MatchParticipationStatus.going,
    );

    await expectLater(
      repository.respondToInvite(
        inviteToken: match.inviteToken,
        playerId: 'player-3',
        playerName: 'كابتن كريم',
        status: MatchParticipationStatus.going,
      ),
      throwsStateError,
    );
  });
}
