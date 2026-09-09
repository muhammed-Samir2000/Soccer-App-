import '../../slots/domain/time_slot.dart';
import 'match_result.dart';
import 'optional_service.dart';

enum BookingStatus { tentative, confirmed, recurring }

class Booking {
  Booking({
    required this.reference,
    required this.playerId,
    required this.playerName,
    required this.slot,
    required List<OptionalService> services,
    required this.totalPrice,
    required this.status,
    required this.fieldNumber,
    this.phoneNumber = '',
    this.matchResult,
  }) : services = List<OptionalService>.unmodifiable(services);

  final String reference;
  final String playerId;
  final String playerName;
  final TimeSlot slot;
  final List<OptionalService> services;
  final int totalPrice;
  final BookingStatus status;
  final int fieldNumber;
  final String phoneNumber;
  final MatchResult? matchResult;

  /// Stable payload reserved for a future QR renderer and reception scanner.
  String get qrPayload =>
      '$reference|field-$fieldNumber|${slot.startTime.toIso8601String()}';

  Booking copyWith({
    String? playerName,
    TimeSlot? slot,
    BookingStatus? status,
    int? fieldNumber,
    String? phoneNumber,
    MatchResult? matchResult,
  }) => Booking(
    reference: reference,
    playerId: playerId,
    playerName: playerName ?? this.playerName,
    slot: slot ?? this.slot,
    services: services,
    totalPrice: totalPrice,
    status: status ?? this.status,
    fieldNumber: fieldNumber ?? this.fieldNumber,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    matchResult: matchResult ?? this.matchResult,
  );
}
