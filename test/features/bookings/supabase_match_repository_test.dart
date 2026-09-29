import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/bookings/data/supabase_match_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/match_participant.dart';

void main() {
  test('maps an invite preview without exposing roster identities', () {
    final match = SupabaseMatchRepository.decode(<String, dynamic>{
      'booking_reference': 'HAGZ-1001',
      'organizer_name': 'الكابتن أحمد',
      'starts_at': '2026-10-01T17:00:00Z',
      'ends_at': '2026-10-01T18:00:00Z',
      'field_number': 2,
      'player_capacity': 10,
      'going_count': 4,
    }, inviteToken: 'safe-link-token');

    expect(match.organizerId, isEmpty);
    expect(match.participants, isEmpty);
    expect(match.goingCount, 4);
    expect(match.inviteToken, 'safe-link-token');
  });

  test('maps a protected organizer roster and attendance states', () {
    final match = SupabaseMatchRepository.decode(<String, dynamic>{
      'booking_reference': 'HAGZ-1001',
      'organizer_id': 'organizer-id',
      'organizer_name': 'الكابتن أحمد',
      'starts_at': '2026-10-01T17:00:00Z',
      'ends_at': '2026-10-01T18:00:00Z',
      'field_number': 2,
      'player_capacity': 10,
      'going_count': 1,
      'participants': <Map<String, dynamic>>[
        <String, dynamic>{
          'player_id': 'organizer-id',
          'display_name': 'الكابتن أحمد',
          'status': 'going',
          'is_organizer': true,
        },
        <String, dynamic>{
          'player_id': 'player-id',
          'display_name': 'كريم',
          'status': 'not_going',
          'is_organizer': false,
        },
      ],
    });

    expect(match.participants, hasLength(2));
    expect(match.participants.last.status, MatchParticipationStatus.notGoing);
    expect(match.goingCount, 1);
  });
}
