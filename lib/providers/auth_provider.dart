import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart'
    show
        AuthChangeEvent,
        AuthException,
        AuthRetryableFetchException,
        AuthState,
        FileOptions,
        FunctionException,
        UserAttributes;

import '../models/address.dart';
import '../services/google_auth_service.dart';
import '../services/location_tracking_service.dart';
import '../services/push_service.dart';
import '../services/pwned_password_service.dart';
import '../services/supabase_service.dart';

enum UserRole { customer, seller, delivery, admin }

UserRole roleFromString(String value) {
  switch (value) {
    case 'seller':
      return UserRole.seller;
    case 'delivery':
      return UserRole.delivery;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.customer;
  }
}

class AuthProvider extends ChangeNotifier {
  String? _userId;
  String _email = '';
  String _userName = 'Guest';
  String _phone = '';
  String _address = '';
  UserRole _role = UserRole.customer;
  bool _isOnline = false;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;
  // True after tapping "Skip": the user browses the store without an account
  // and is asked to log in when they go to check out. Session-only.
  bool _isGuest = false;
  List<Address> _addresses = [];
  String? _avatarUrl;

  bool get isLoggedIn => _userId != null;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  bool get isGuest => _isGuest && _userId == null;

  void continueAsGuest() {
    if (_isGuest) return;
    _isGuest = true;
    notifyListeners();
  }

  String? get error => _error;
  String get userId => _userId ?? '';
  String get email => _email;
  String get userName => _userName;
  String get phone => _phone;
  // A delivery address kept on this phone — for guests, and for anyone who
  // hasn't saved one to their account yet. (Live location / map pick.)
  String _localAddress = '';
  double? _localLat;
  double? _localLng;
  static const _localAddressKey = 'delivery_address';
  static const _localLatKey = 'delivery_address_lat';
  static const _localLngKey = 'delivery_address_lng';

  /// Where orders are delivered: the account's default address, else the one
  /// set on this phone, else empty.
  String get address => _address.isNotEmpty ? _address : _localAddress;

  /// Map position of [address], when it has one.
  double? get deliveryLat => getDefaultAddress()?.lat ?? _localLat;
  double? get deliveryLng => getDefaultAddress()?.lng ?? _localLng;

  UserRole get role => _role;
  bool get isOnline => _isOnline;
  List<Address> get addresses => List.unmodifiable(_addresses);
  String? get avatarUrl => _avatarUrl;

  /// Set when the signed-in user's profile row could not be read: the user
  /// is logged in, but name, role and addresses are still the defaults.
  /// The app retries in the background and the Profile screen shows a note
  /// until the read lands — the role decides which home the user gets, so
  /// this failure must never be silent.
  bool _profileStale = false;
  bool get profileStale => _profileStale;

  static const _sessionPrefsKey = 'supabase_session';

  StreamSubscription<AuthState>? _authSub;

  AuthProvider() {
    // The plain Supabase Dart client keeps its session in memory only, so we
    // mirror every session change (sign-in, token refresh) to disk ourselves
    // and feed it back through recoverSession() on the next launch.
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
      onError: (Object e) => debugPrint('auth state error: $e'),
    );
    _loadLocalAddress();
    _restoreSession();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _onAuthStateChange(AuthState state) {
    final session = state.session;
    if (session != null) {
      _persistSession(jsonEncode(session.toJson()));
    } else if (state.event == AuthChangeEvent.signedOut) {
      _clearPersistedSession();
    }
  }

  Future<void> _persistSession(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionPrefsKey, json);
    } catch (e) {
      debugPrint('Saving session failed: $e');
    }
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionPrefsKey);
    } catch (e) {
      debugPrint('Clearing session failed: $e');
    }
  }

  Future<void> _recoverPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_sessionPrefsKey);
      if (stored == null) return;
      await SupabaseService.client.auth.recoverSession(stored);
    } on AuthRetryableFetchException catch (e) {
      // Offline (or server unreachable): keep the saved session so the next
      // launch can try again instead of forcing a fresh login.
      debugPrint('Session recovery deferred: $e');
    } on AuthException catch (e) {
      // Refresh token is invalid/revoked — the saved session is useless.
      debugPrint('Session recovery failed: $e');
      await _clearPersistedSession();
    } catch (e) {
      debugPrint('Session recovery failed: $e');
    }
  }

  Future<void> _restoreSession() async {
    if (SupabaseService.client.auth.currentSession == null) {
      await _recoverPersistedSession();
    }
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      await _loadProfile(session.user.id);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadProfile(String userId) async {
    _userId = userId;
    _isGuest = false;
    _email = SupabaseService.client.auth.currentUser?.email ?? '';
    try {
      final rows = await SupabaseService.client
          .from('profiles')
          .select('full_name, phone, role, is_online, avatar_url')
          .eq('id', userId)
          .limit(1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        _userName = (row['full_name'] as String?)?.trim().isNotEmpty == true
            ? row['full_name'] as String
            : _email;
        _phone = row['phone'] as String? ?? '';
        _role = roleFromString(row['role'] as String? ?? 'customer');
        _isOnline = row['is_online'] as bool? ?? false;
        _avatarUrl = row['avatar_url'] as String?;
      }

      // All saved addresses (and the default one) — now, not only when the
      // address screen is opened.
      await loadAddresses();
      _profileStale = false;
    } catch (e) {
      // Keep whatever defaults we already have — a profile read failure
      // shouldn't block the user from being considered logged in. But the
      // half-loaded state is flagged, retried in the background, and shown
      // on the Profile screen: a seller or admin quietly landing in the
      // customer app is exactly what this catch used to hide.
      debugPrint('Profile load failed: $e');
      if (!_profileStale) {
        _profileStale = true;
        _scheduleProfileRetries();
      }
    }
  }

  /// The waits between background re-reads of a failed profile load.
  static const _profileRetryWaits = [
    Duration(seconds: 2),
    Duration(seconds: 6),
    Duration(seconds: 15),
  ];

  void _scheduleProfileRetries() {
    for (final wait in _profileRetryWaits) {
      Future<void>.delayed(wait, _retryProfileOnce);
    }
  }

  Future<void> _retryProfileOnce() async {
    if (!_profileStale) return;
    final uid = _userId;
    if (uid == null) return;
    await _loadProfile(uid);
    if (!_profileStale) notifyListeners();
  }

  /// Re-reads the signed-in user's profile row — the "Try again" behind the
  /// stale-profile note on the Profile screen.
  Future<void> refreshProfile() async {
    final uid = _userId;
    if (uid == null) return;
    await _loadProfile(uid);
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String referralCode = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final passwordStatus = await PwnedPasswordService.check(password);
      if (passwordStatus != PwnedPasswordStatus.safe) {
        _error = _passwordSafetyMessage(passwordStatus);
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final res = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      final user = res.user;
      if (user == null) {
        _error = 'Check your email to confirm your account, then log in.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      // Trigger only seeds full_name — write phone ourselves.
      if (phone.isNotEmpty) {
        await SupabaseService.client
            .from('profiles')
            .update({'phone': phone}).eq('id', user.id);
      }
      // A friend's code is a bonus, never a reason to fail the sign-up.
      if (referralCode.trim().isNotEmpty) {
        try {
          await SupabaseService.client.rpc('apply_referral', params: {
            'p_new_user_id': user.id,
            'p_referral_code': referralCode.trim(),
          });
        } catch (e) {
          debugPrint('apply_referral failed: $e');
        }
      }
      await _loadProfile(user.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('signUp failed: $e');
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) {
        _error = 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await _loadProfile(user.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('signIn failed: $e');
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Signs in (or, for a first tap, signs up) with a Google account. The
  /// database's own `handle_new_user` trigger creates the `profiles` row on
  /// a brand-new account exactly as it does for an email sign-up, so there
  /// is nothing extra to write here — only the session to load from.
  ///
  /// Returns false with nothing in [error] when the account picker was
  /// simply dismissed; that is not a failure worth telling anyone about.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // null = the account picker was dismissed; a plain cancel, not an
      // error worth surfacing (the button treats it the same way).
      final response = await GoogleAuthService.signIn();
      if (response == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        _error = 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await _loadProfile(user.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Signs in with a phone number instead of an email, via the `phone-login`
  /// edge function (Supabase auth itself has no phone/password grant here —
  /// every account was created with an email, and the number lives on
  /// `profiles`). The function looks up the email for that number and
  /// performs the ordinary password grant server-side, returning a GoTrue
  /// session verbatim.
  Future<bool> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await SupabaseService.client.functions.invoke(
        'phone-login',
        body: {'phone': phone.trim(), 'password': password},
      );
      await SupabaseService.client.auth.recoverSession(
        jsonEncode(response.data),
      );
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        _error = 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await _loadProfile(user.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map ? details['error'] as String? : null;
      _error = switch (code) {
        'multiple_accounts' =>
          'Multiple accounts use this number. Log in with email instead.',
        'invalid_credentials' => 'Invalid phone number or password.',
        _ => 'Something went wrong. Please try again.',
      };
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('signInWithPhone failed: $e');
      _error = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Emails a password-reset link. Returns null on success, or a message
  /// that can be shown to the user.
  ///
  /// `redirectTo` is the app's own deep link (see DeepLinkService /
  /// AndroidManifest.xml / Info.plist) so the link opens Infinity directly
  /// instead of a browser tab — it must also be added under Authentication →
  /// URL Configuration → Redirect URLs in the Supabase dashboard, or GoTrue
  /// rejects it and falls back to the project's Site URL.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.duggustore.app://reset-password',
      );
      return null;
    } on AuthRetryableFetchException {
      return 'No internet connection. Please try again.';
    } catch (e) {
      debugPrint('Password reset failed: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('rate limit') || msg.contains('too many')) {
        return 'Too many attempts. Please wait a minute and try again.';
      }
      return "Couldn't send the reset email. Please try again.";
    }
  }

  /// Turns the link a password-reset (or magic-link) email opened the app
  /// with into a real session, and reports whether it was a recovery link —
  /// the only kind DeepLinkService acts on, by sending the user to
  /// ResetPasswordScreen to set a new password.
  Future<bool> completeAuthCallback(Uri uri) async {
    final response = await SupabaseService.client.auth.getSessionFromUrl(uri);
    return response.redirectType == 'recovery';
  }

  /// Sets a new password for the signed-in user — used right after a
  /// password-reset link opens the app (see completeAuthCallback above).
  /// Returns null on success, or a message that can be shown to the user.
  Future<String?> updatePassword(String newPassword) async {
    try {
      final passwordStatus = await PwnedPasswordService.check(newPassword);
      if (passwordStatus != PwnedPasswordStatus.safe) {
        return _passwordSafetyMessage(passwordStatus);
      }
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null;
    } on AuthRetryableFetchException {
      return 'No internet connection. Please try again.';
    } catch (e) {
      debugPrint('Password update failed: $e');
      return "Couldn't update the password. Please try again.";
    }
  }

  String _passwordSafetyMessage(PwnedPasswordStatus status) => switch (status) {
        PwnedPasswordStatus.breached =>
          'This password has appeared in known data breaches. Choose a different password.',
        PwnedPasswordStatus.unavailable =>
          'Could not verify password safety. Check your connection and try again.',
        PwnedPasswordStatus.safe => '',
      };

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('User already registered')) {
      return 'This email is already registered. Try logging in.';
    }
    if (msg.contains('Password should be')) {
      return 'Password must be at least 6 characters.';
    }
    // Says exactly what is wrong (and that retrying will not fix it) rather
    // than the generic line below, which reads as a network hiccup worth
    // trying again.
    if (msg.contains('Google sign-in is not set up') ||
        msg.contains("didn't return a usable sign-in token")) {
      return e is AuthException ? e.message : msg;
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> signOut() async {
    // While the session still exists: stop this phone getting the pushes
    // of the account that is leaving.
    await PushService.releaseForSignOut();
    // Stop location tracking if the user was a delivery partner.
    await LocationTrackingService.instance.dispose();
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {
      // Best-effort on purpose: even when the server call fails, the local
      // state below is still cleared, so the next person on this phone
      // never inherits this session.
    }
    _userId = null;
    _isGuest = false;
    _profileStale = false;
    _email = '';
    _userName = 'Guest';
    _phone = '';
    _address = '';
    _addresses = [];
    _role = UserRole.customer;
    _isOnline = false;
    _avatarUrl = null;
    notifyListeners();
  }

  /// Saves the name and phone on the signed-in account. Returns false,
  /// changing nothing on screen, when the server could not be told.
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    if (_userId == null) return false;
    try {
      await SupabaseService.client.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
      }).eq('id', _userId!);
      _userName = fullName;
      _phone = phone;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Profile update failed: $e');
      return false;
    }
  }

  /// Uploads [bytes] as the signed-in user's avatar (overwriting any
  /// previous one at the same path) and updates their profile.
  Future<bool> updateAvatar(Uint8List bytes) async {
    if (_userId == null) return false;
    try {
      final path = '$_userId/avatar.jpg';
      await SupabaseService.client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      final url =
          SupabaseService.client.storage.from('avatars').getPublicUrl(path);
      final bustedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': bustedUrl}).eq('id', _userId!);
      _avatarUrl = bustedUrl;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Avatar upload failed: $e');
      return false;
    }
  }

  /// Self-service upgrade from customer to seller/delivery, matching the
  /// simplified role-switch flow (no separate approval step yet).
  Future<bool> switchRole(UserRole newRole) async {
    if (_userId == null) return false;
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'role': newRole.name}).eq('id', _userId!);
      _role = newRole;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Becomes a seller: creates the `sellers` business-profile row that
  /// `seller_documents` and product listings key off (switchRole() alone
  /// only flips profiles.role and leaves no seller application behind),
  /// then switches the role.
  Future<bool> becomeSeller({
    required String businessName,
    required String ownerName,
  }) async {
    if (_userId == null) return false;
    try {
      await SupabaseService.client.from('sellers').upsert({
        'id': _userId,
        'business_name': businessName,
        'owner_name': ownerName,
        'email': _email,
        'phone': _phone,
      });
      return await switchRole(UserRole.seller);
    } catch (e) {
      debugPrint('becomeSeller failed: $e');
      return false;
    }
  }

  /// Becomes a delivery partner: creates the `delivery_partners` row that
  /// `delivery_partner_documents` and delivery assignment key off.
  Future<bool> becomeDeliveryPartner({
    required String fullName,
    required String vehicleType,
    String vehicleNumber = '',
  }) async {
    if (_userId == null) return false;
    try {
      await SupabaseService.client.from('delivery_partners').upsert({
        'id': _userId,
        'full_name': fullName,
        'email': _email,
        'phone': _phone,
        'vehicle_type': vehicleType,
        if (vehicleNumber.isNotEmpty) 'vehicle_number': vehicleNumber,
      });
      return await switchRole(UserRole.delivery);
    } catch (e) {
      debugPrint('becomeDeliveryPartner failed: $e');
      return false;
    }
  }

  /// Flips the "accepting orders" flag, optimistically on screen first.
  /// Returns false and reverts when the server could not be told, so the
  /// switch never shows a status the server does not know about.
  Future<bool> setOnlineStatus(bool online) async {
    if (_userId == null) return false;
    _isOnline = online;
    notifyListeners();
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'is_online': online}).eq('id', _userId!);
      return true;
    } catch (e) {
      debugPrint('setOnlineStatus failed: $e');
      _isOnline = !online;
      notifyListeners();
      return false;
    }
  }

  // --- delivery address ---------------------------------------------------

  Future<void> _loadLocalAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _localAddress = prefs.getString(_localAddressKey) ?? '';
      _localLat = prefs.getDouble(_localLatKey);
      _localLng = prefs.getDouble(_localLngKey);
      notifyListeners();
    } catch (_) {
      // Best-effort: this address is a convenience copy kept on the
      // phone, and starting without one is always a valid state.
    }
  }

  /// Remembers a delivery address on this phone — used by guests, and by
  /// anyone who hasn't saved an address yet.
  Future<void> setLocalAddress(
    String address, {
    double? lat,
    double? lng,
  }) async {
    _localAddress = address.trim();
    _localLat = lat;
    _localLng = lng;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localAddressKey, _localAddress);
      if (lat != null && lng != null) {
        await prefs.setDouble(_localLatKey, lat);
        await prefs.setDouble(_localLngKey, lng);
      } else {
        await prefs.remove(_localLatKey);
        await prefs.remove(_localLngKey);
      }
    } catch (_) {
      // Best-effort: the in-memory copy above is already set, so this
      // session keeps the address; losing the on-disk copy only means it
      // won't survive a relaunch.
    }
  }

  /// Makes [address] the place to deliver to. Signed-in users get it saved
  /// to their account (a single "Current location" entry is updated in place
  /// rather than adding a new one each time); guests keep it on the phone.
  Future<bool> setDeliveryLocation(
    String address, {
    double? lat,
    double? lng,
    String label = 'Current location',
  }) async {
    if (_userId == null) {
      await setLocalAddress(address, lat: lat, lng: lng);
      return true;
    }
    final draft = Address(
      id: '',
      label: label,
      fullAddress: address.trim(),
      lat: lat,
      lng: lng,
      isDefault: true,
    );
    final existing = _addresses.where((a) => a.label == label).toList();
    return existing.isEmpty
        ? addAddress(draft)
        : updateAddress(existing.first.id, draft);
  }

  Future<void> loadAddresses() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final rows = await SupabaseService.client
          .from('addresses')
          .select()
          .eq('user_id', uid)
          .order('is_default', ascending: false)
          .order('created_at');
      _addresses = rows
          .map((r) => Address.fromRow(r, fullName: _userName, phone: _phone))
          .toList();
      _address = getDefaultAddress()?.fullAddress ?? '';
    } catch (e) {
      debugPrint('Loading addresses failed: $e');
    }
    notifyListeners();
  }

  Future<void> _clearDefaults(String uid) {
    return SupabaseService.client
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', uid)
        .eq('is_default', true);
  }

  /// Saves a new address. It becomes the default if it's the first one or
  /// [Address.isDefault] is set.
  Future<bool> addAddress(Address address) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final makeDefault = address.isDefault || _addresses.isEmpty;
      if (makeDefault) await _clearDefaults(uid);
      await SupabaseService.client
          .from('addresses')
          .insert(address.copyWith(isDefault: makeDefault).toRow(uid));
      await loadAddresses();
      return true;
    } catch (e) {
      debugPrint('Adding address failed: $e');
      return false;
    }
  }

  Future<bool> updateAddress(String id, Address address) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      if (address.isDefault) await _clearDefaults(uid);
      await SupabaseService.client
          .from('addresses')
          .update(address.toRow(uid))
          .eq('id', id)
          .eq('user_id', uid);
      await loadAddresses();
      return true;
    } catch (e) {
      debugPrint('Updating address failed: $e');
      return false;
    }
  }

  Future<bool> setDefaultAddress(String id) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _clearDefaults(uid);
      await SupabaseService.client
          .from('addresses')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', uid);
      await loadAddresses();
      return true;
    } catch (e) {
      debugPrint('Setting default address failed: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(String id) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await SupabaseService.client
          .from('addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', uid);
      await loadAddresses();
      // Never leave the account without a default while addresses remain.
      if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
        await setDefaultAddress(_addresses.first.id);
      }
      return true;
    } catch (e) {
      debugPrint('Deleting address failed: $e');
      return false;
    }
  }

  Address? getDefaultAddress() {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  void clearAddresses() {
    _addresses = [];
    notifyListeners();
  }
}
