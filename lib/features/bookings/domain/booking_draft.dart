import '../../slots/domain/time_slot.dart';
import 'optional_service.dart';

class BookingDraft {
  BookingDraft({
    required this.slot,
    required this.basePrice,
    List<OptionalService> selectedServices = const [],
  }) : selectedServices = List<OptionalService>.unmodifiable(selectedServices);

  final TimeSlot slot;
  final int basePrice;
  final List<OptionalService> selectedServices;

  int get servicesTotal => selectedServices.fold<int>(
    0,
    (int total, OptionalService service) => total + service.price,
  );

  int get totalPrice => basePrice + servicesTotal;

  bool hasService(String serviceId) {
    return selectedServices.any(
      (OptionalService service) => service.id == serviceId,
    );
  }

  BookingDraft toggleService(OptionalService service) {
    final List<OptionalService> updatedServices = List<OptionalService>.from(
      selectedServices,
    );
    final int existingIndex = updatedServices.indexWhere(
      (OptionalService selected) => selected.id == service.id,
    );

    if (existingIndex == -1) {
      updatedServices.add(service);
    } else {
      updatedServices.removeAt(existingIndex);
    }

    return BookingDraft(
      slot: slot,
      basePrice: basePrice,
      selectedServices: updatedServices,
    );
  }
}
