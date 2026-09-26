import 'package:flutter/material.dart';
import '../domain/venue_profile.dart';
import '../domain/venue_profile_repository.dart';
import 'venue_setup_screen.dart';

/// Runs after authentication; authorization is also enforced by the setup RPC.
class VenueSetupGate extends StatefulWidget {
  const VenueSetupGate({super.key, required this.repository,
    required this.canConfigure, required this.builder});
  final VenueProfileRepository repository;
  final bool canConfigure;
  final Widget Function(VenueProfile) builder;
  @override
  State<VenueSetupGate> createState() => _VenueSetupGateState();
}

class _VenueSetupGateState extends State<VenueSetupGate> {
  late Future<VenueProfile?> _venue;
  @override
  void initState() { super.initState(); _venue = widget.repository.getVenue(); }
  void _reload() => setState(() => _venue = widget.repository.getVenue());
  @override
  Widget build(BuildContext context) => FutureBuilder<VenueProfile?>(
    future: _venue,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(appBar: AppBar(title: const Text('بيانات الملعب')),
          body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('تعذر تحميل بيانات الملعب. راجع الاتصال وحاول تاني.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: const Text('إعادة المحاولة')),
          ])));
      }
      final venue = snapshot.data;
      if (venue != null) return widget.builder(venue);
      if (widget.canConfigure) return VenueSetupScreen(repository: widget.repository, onSaved: _reload);
      return Scaffold(appBar: AppBar(title: const Text('الملعب لسه بيتجهز')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(24), child: Text(
            'الإدارة لسه بتكمل بيانات الملعب وأسعاره. جرّب تاني بعد ما الإعداد يكتمل.',
            textAlign: TextAlign.center)),
          OutlinedButton(onPressed: _reload, child: const Text('تحديث')),
        ])));
    },
  );
}
