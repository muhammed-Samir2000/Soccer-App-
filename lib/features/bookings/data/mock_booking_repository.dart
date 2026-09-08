import '../domain/booking.dart';
import '../domain/booking_draft.dart';
import '../domain/booking_repository.dart';
import '../domain/match_result.dart';
import '../domain/optional_service.dart';
import '../../slots/domain/time_slot.dart';

class MockBookingRepository implements BookingRepository {
  MockBookingRepository({
    this.firstReferenceNumber = 1001,
    List<Booking> initialBookings = const [],
  }) : _nextReferenceNumber = firstReferenceNumber,
       _bookings = List<Booking>.from(initialBookings);

  factory MockBookingRepository.seeded() {
    final TimeSlot slot = TimeSlot(
      id: 'slot-seeded-001',
      startTime: DateTime(2026, 9, 7, 18),
      endTime: DateTime(2026, 9, 7, 19),
      status: SlotStatus.booked,
    );
    return MockBookingRepository(
      initialBookings: [
        Booking(
          reference: 'HAGZ-1000',
          playerId: 'player-seeded-001',
          playerName: 'الكابتن كريم',
          slot: slot,
          services: const [
            OptionalService(id: 'referee', name: 'حكم', price: 300),
          ],
          totalPrice: 1100,
          status: BookingStatus.confirmed,
          fieldNumber: 1,
        ),
      ],
    );
  }

  final int firstReferenceNumber;
  int _nextReferenceNumber;
  int _fieldCount = 3;
  final List<Booking> _bookings;

  @override
  Future<Booking> createBooking(BookingDraft draft) async {
    return _create(
      playerId: 'player-001',
      playerName: 'الكابتن أحمد',
      draft: draft,
      status: BookingStatus.confirmed,
    );
  }

  @override
  Future<List<Booking>> getBookings() async =>
      List<Booking>.unmodifiable(_bookings);

  @override
  Future<List<Booking>> getBookingsForPlayer(String playerId) async =>
      List<Booking>.unmodifiable(
        _bookings.where((Booking booking) => booking.playerId == playerId),
      );

  @override
  Future<Booking> createTentativeBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  }) => _create(
    playerId: 'phone-$phoneNumber',
    playerName: playerName,
    draft: draft,
    status: BookingStatus.tentative,
  );

  @override
  Future<Booking> createAdminBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
    required BookingStatus status,
  }) {
    final String cleanedName = playerName.trim();
    final String cleanedPhone = phoneNumber.trim();
    if (cleanedName.isEmpty) {
      throw ArgumentError('اكتب اسم اللاعب أو المجموعة.');
    }
    if (cleanedPhone.isEmpty) {
      throw ArgumentError('اكتب رقم هاتف للتواصل.');
    }
    return _create(
      playerId: 'phone-$cleanedPhone',
      playerName: cleanedName,
      draft: draft,
      status: status,
    );
  }

  @override
  Future<Booking> createRecurringBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  }) => _create(
    playerId: 'phone-$phoneNumber',
    playerName: playerName,
    draft: draft,
    status: BookingStatus.recurring,
  );

  @override
  Future<void> saveMatchResult({
    required String bookingReference,
    required MatchResult result,
  }) async {
    final int index = _bookings.indexWhere(
      (Booking booking) => booking.reference == bookingReference,
    );
    if (index == -1) {
      throw StateError('Booking not found');
    }
    _bookings[index] = _bookings[index].copyWith(matchResult: result);
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    final int index = _bookings.indexWhere(
      (Booking item) => item.reference == booking.reference,
    );
    if (index == -1) {
      throw StateError('Booking not found');
    }
    final Set<int> occupiedFields = _bookings
        .where(
          (Booking item) =>
              item.reference != booking.reference &&
              item.slot.startTime == booking.slot.startTime &&
              item.slot.endTime == booking.slot.endTime,
        )
        .map((Booking item) => item.fieldNumber)
        .toSet();
    final List<int> availableFields = List<int>.generate(
      _fieldCount,
      (int fieldIndex) => fieldIndex + 1,
    ).where((int field) => !occupiedFields.contains(field)).toList();
    if (availableFields.isEmpty) {
      throw StateError('كل الملاعب محجوزة في هذا الموعد.');
    }
    _bookings[index] = booking.copyWith(fieldNumber: availableFields.first);
  }

  @override
  Future<void> deleteBooking(String bookingReference) async {
    _bookings.removeWhere(
      (Booking booking) => booking.reference == bookingReference,
    );
  }

  @override
  Future<void> updateFieldCount(int fieldCount) async {
    if (fieldCount < 1 || fieldCount > 12) {
      throw ArgumentError('عدد الملاعب لازم يكون بين 1 و12.');
    }
    if (_bookings.any((Booking booking) => booking.fieldNumber > fieldCount)) {
      throw StateError(
        'مش ينفع تقلل العدد عن الملاعب اللي عليها حجوزات حالياً.',
      );
    }
    _fieldCount = fieldCount;
  }

  Future<Booking> _create({
    required String playerId,
    required String playerName,
    required BookingDraft draft,
    required BookingStatus status,
  }) async {
    final Set<int> occupiedFields = _bookings
        .where(
          (Booking booking) =>
              booking.slot.startTime == draft.slot.startTime &&
              booking.slot.endTime == draft.slot.endTime,
        )
        .map((Booking booking) => booking.fieldNumber)
        .toSet();
    final List<int> availableFields = List<int>.generate(
      _fieldCount,
      (int index) => index + 1,
    ).where((int field) => !occupiedFields.contains(field)).toList();
    if (availableFields.isEmpty) {
      throw StateError('كل الملاعب محجوزة في هذا الموعد.');
    }
    final Booking booking = Booking(
      reference: 'HAGZ-$_nextReferenceNumber',
      playerId: playerId,
      playerName: playerName,
      slot: draft.slot,
      services: draft.selectedServices,
      totalPrice: draft.totalPrice,
      status: status,
      fieldNumber: availableFields.first,
    );
    _nextReferenceNumber++;
    _bookings.add(booking);
    return booking;
  }
}
