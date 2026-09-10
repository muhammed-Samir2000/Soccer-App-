import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_dependencies.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SoccerBookingApp extends StatelessWidget {
  SoccerBookingApp({
    super.key,
    AppDependencies? dependencies,
    this.initialRoute = AppRouter.launchRoute,
  }) : dependencies = dependencies ?? AppDependencies.mock();

  final AppDependencies dependencies;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'احجز ملعبك',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter(dependencies).onGenerateRoute,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
