import 'package:flutter/foundation.dart';

import 'app_user.dart';

/// Holds the signed-in user while the mock application is running.
///
/// A production implementation must restore this from a verified provider
/// session and enforce the same role checks on the backend.
class AppSession extends ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.role == UserRole.admin;

  void signIn(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }
}
