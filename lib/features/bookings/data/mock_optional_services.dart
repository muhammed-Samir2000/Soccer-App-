import '../domain/optional_service.dart';

class MockOptionalServices {
  const MockOptionalServices._();

  static const List<OptionalService> all = [
    OptionalService(id: 'drinks', name: 'مشروبات ساقعة', price: 60),
    OptionalService(id: 'photography', name: 'تصوير الماتش', price: 250),
    OptionalService(id: 'referee', name: 'حكم', price: 300),
  ];
}
