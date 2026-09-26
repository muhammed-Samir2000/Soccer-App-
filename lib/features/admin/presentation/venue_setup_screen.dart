import 'package:flutter/material.dart';

import '../domain/venue_profile.dart';
import '../domain/venue_profile_repository.dart';

class VenueSetupScreen extends StatefulWidget {
  const VenueSetupScreen({super.key, required this.repository,
    required this.onSaved, this.initialVenue});
  final VenueProfileRepository repository;
  final VenueProfile? initialVenue;
  final VoidCallback onSaved;

  @override
  State<VenueSetupScreen> createState() => _VenueSetupScreenState();
}

class _VenueSetupScreenState extends State<VenueSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _count;
  late final TextEditingController _price;
  int? _opening;
  int? _closing;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final venue = widget.initialVenue;
    _name = TextEditingController(text: venue?.name ?? '');
    _count = TextEditingController(text: venue?.fieldCount.toString() ?? '');
    _price = TextEditingController(text: venue?.hourlyPrice.toString() ?? '');
    _opening = venue?.openingHour;
    _closing = venue?.closingHour;
  }

  @override
  void dispose() {
    _name.dispose(); _count.dispose(); _price.dispose();
    super.dispose();
  }

  int? _number(String value) {
    var normalized = value.trim();
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i');
    }
    return int.tryParse(normalized);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final venue = VenueProfile(
      id: widget.initialVenue?.id ?? '', name: _name.text.trim(),
      fieldCount: _number(_count.text) ?? 0,
      hourlyPrice: _number(_price.text) ?? 0,
      openingHour: _opening ?? -1, closingHour: _closing ?? -1,
    );
    final invalid = venue.validate();
    if (invalid != null) { setState(() => _error = invalid); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repository.saveVenue(venue);
      if (mounted) widget.onSaved();
    } catch (_) {
      if (mounted) setState(() => _error =
        'الحفظ ما اكتملش. راجع اتصالك وصلاحية حساب الإدارة، وبعدين جرّب تاني.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.initialVenue == null ? 'إعداد الملعب' : 'بيانات الملعب والأسعار')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
      child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('بياناتك دي هتظهر للاعبين، ومواعيدك وسعر الساعة هيتحسبوا على أساسها.'),
        const SizedBox(height: 24),
        TextFormField(controller: _name, enabled: !_saving, maxLength: 100,
          decoration: const InputDecoration(labelText: 'اسم الملعب'),
          validator: (v) => (v?.trim().length ?? 0) < 2 ? 'اكتب اسم الملعب.' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _count, enabled: !_saving, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'عدد الملاعب', helperText: 'من 1 إلى 12 ملعب'),
          validator: (v) => (_number(v ?? '') ?? 0) < 1 || (_number(v ?? '') ?? 0) > 12 ? 'اكتب عدد من 1 إلى 12.' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _price, enabled: !_saving, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'سعر الساعة لكل ملعب', suffixText: 'ج.م'),
          validator: (v) => (_number(v ?? '') ?? 0) < 1 || (_number(v ?? '') ?? 0) > 100000 ? 'اكتب سعر صحيح بالجنيه.' : null),
        const SizedBox(height: 20),
        _hourPicker('ساعة الفتح', _opening, (v) => setState(() => _opening = v)),
        const SizedBox(height: 16),
        _hourPicker('ساعة القفل', _closing, (v) => setState(() => _closing = v)),
        const SizedBox(height: 12),
        const Text('المواعيد بتوقيت القاهرة. لو القفل قبل الفتح، يبقى في اليوم التالي.'),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 24),
        FilledButton(onPressed: _saving ? null : _save,
          child: Text(_saving ? 'بنحفظ البيانات...' : 'حفظ بيانات الملعب')),
      ])),
    )),
  );

  Widget _hourPicker(String label, int? value, ValueChanged<int?> changed) =>
    DropdownButtonFormField<int>(initialValue: value, decoration: InputDecoration(labelText: label),
      items: List.generate(24, (hour) => DropdownMenuItem(value: hour,
        child: Text(TimeOfDay(hour: hour, minute: 0).format(context)))),
      onChanged: _saving ? null : changed,
      validator: (hour) => hour == null ? 'اختار الساعة.' : null);
}
