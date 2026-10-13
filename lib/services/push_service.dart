import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/notifications_screen.dart';
import 'supabase_service.dart';

/// Push notifications through Firebase Cloud Messaging.
///
/// Rules:
/// 1. Until android/app/google-services.json is in the app, all of this
///    quietly does nothing — no prompt, no crash. The Gradle side only
///    applies the google-services plugin when that file exists, so the
///    build passes either way.
/// 2. The device token is kept in the Supabase table `device_tokens`
///    (created by supabase/device_tokens.sql) for the signed-in user only.
///    Signing in or out re-registers it; a guest's token is never stored.
/// 3. A message that lands while the app is open still shows a heads-up,
///    and nudges the in-app inbox to reload.
/// 4. Tapping a notification — from the tray or in the app — opens the
///    notifications screen.
class PushService {
  /// The MaterialApp's navigator key, set from main(): a tapped
  /// notification routes through it, wherever the app happens to be.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Set by the root screen: runs after a push lands, so the inbox
  /// refreshes without leaving the current page.
  static VoidCallback? onPush;

  static const _channelId = 'duggu_push';
  static const _channelName = 'Duggu Store updates';

  /// A new order landing — for the seller whose store it's for, and the
  /// rider it gets assigned to — is the one alert either of them is
  /// actively waiting on, so it gets its own loud, distinct sound instead
  /// of blending into every other update. send-push and the
  /// notify_push_on_insert trigger mark it with data.loud = 'true'
  /// (supabase/notifications_push.sql decides which titles count).
  static const _loudChannelId = 'duggu_order_alert';
  static const _loudChannelName = 'New orders';

  /// Pause, three short buzzes, pause, one long one — noticeably not the
  /// single default buzz every other notification gets.
  static final _loudVibration = Int64List.fromList(
    [0, 250, 120, 250, 120, 250, 300, 500],
  );

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();
  static bool _localReady = false;
  static bool _ttsReady = false;
  static bool _started = false;
  static String? _token;
  static StreamSubscription<dynamic>? _authSub;

  /// Called once from main(). Safe even when Firebase has no config.
  static Future<void> start() async {
    if (_started) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (_) {
      // No google-services.json in this build: push stays off.
      return;
    }
    _started = true;
    try {
      await _prepareLocal();
      final messaging = FirebaseMessaging.instance;
      // On Android 13+ this is the notification-permission prompt; on
      // older versions it returns right away.
      await messaging.requestPermission();
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      _token = await messaging.getToken();
      await _registerToken();
      messaging.onTokenRefresh.listen((token) async {
        _token = token;
        await _registerToken();
      });
      FirebaseMessaging.onMessage.listen((message) async {
        await _show(message);
        onPush?.call();
      });
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openInbox());
      // Launched by tapping a heads-up while the app was closed.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openInbox();
      // Keep the server in step with sign-in and sign-out.
      await _authSub?.cancel();
      _authSub = SupabaseService.client.auth.onAuthStateChange
          .listen((_) => _registerToken());
    } catch (e) {
      // Push is a bonus: anything unexpected must never break the app.
      debugPrint('push: disabled (${e.runtimeType})');
    }
  }

  static Future<void> _prepareLocal() async {
    if (_localReady) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (_) => _openInbox(),
    );
    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Order, delivery and account updates.',
        importance: Importance.max,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _loudChannelId,
        _loudChannelName,
        description: 'A new order comes in, or a run is assigned to you.',
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('order_alert'),
        enableVibration: true,
        vibrationPattern: _loudVibration,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    // The one prompt Android 13+ needs before any heads-up can appear.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _localReady = true;
  }

  /// The heads-up itself. Also runs on the background isolate, where
  /// nothing else of the app is alive yet — so it initialises what it
  /// needs instead of assuming main() already did.
  static Future<void> _show(RemoteMessage message) async {
    try {
      await _prepareLocal();
    } catch (e) {
      debugPrint('push: notifications unavailable (${e.runtimeType})');
      return;
    }
    // A push meant for another account — one that was signed in on this
    // phone before — is dropped: never shown, never read out. The signed-in
    // account is kept in prefs because this also runs on the background
    // isolate, where no Supabase session is loaded.
    final recipient = message.data['user_id'] as String?;
    if (recipient != null && recipient.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (prefs.getString(_signedInKey) != recipient) return;
    }
    final notification = message.notification;
    final title = notification?.title ?? 'Duggu Store';
    final body = notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    final loud = message.data['loud'] == 'true';
    await _local.show(
      notification?.hashCode ?? message.messageId?.hashCode ?? 0,
      title,
      body,
      NotificationDetails(
        android: loud
            ? AndroidNotificationDetails(
                _loudChannelId,
                _loudChannelName,
                channelDescription:
                    'A new order comes in, or a run is assigned to you.',
                importance: Importance.max,
                priority: Priority.max,
                sound: const RawResourceAndroidNotificationSound(
                  'order_alert',
                ),
                enableVibration: true,
                vibrationPattern: _loudVibration,
                audioAttributesUsage: AudioAttributesUsage.alarm,
              )
            : const AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: 'Order, delivery and account updates.',
                importance: Importance.max,
                priority: Priority.high,
              ),
      ),
    );
    // A sound alone still needs reading to notice it's an order and not
    // some other alert; speaking the title out is the actual "loud
    // announcement" — the sound and vibration just get a hand reaching for
    // the phone in the first place. Awaited so a background isolate isn't
    // torn down mid-sentence.
    if (loud) await _announce(title);
  }

  static Future<void> _announce(String text) async {
    try {
      if (!_ttsReady) {
        await _tts.setLanguage('en-IN');
        await _tts.setSpeechRate(0.46);
        await _tts.setVolume(1);
        await _tts.setPitch(1);
        _ttsReady = true;
      }
      await _tts.speak(text);
    } catch (e) {
      // Speech is a bonus on top of the sound and vibration, which have
      // already fired — never let this crash the notification pipeline.
      debugPrint('push: announcement failed (${e.runtimeType})');
    }
  }

  static void _openInbox() {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  static const _signedInKey = 'push_signed_in_user';

  /// Lets go of this phone's token before the account signs out, while the
  /// session still exists — afterwards nothing would be allowed to.
  static Future<void> releaseForSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_signedInKey);
      final token = _token;
      if (token == null || token.isEmpty) return;
      await SupabaseService.client
          .rpc('release_device_token', params: {'p_token': token});
    } catch (e) {
      debugPrint('push: token release failed (${e.runtimeType})');
    }
  }

  static Future<void> _registerToken() async {
    final user = SupabaseService.client.auth.currentUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        await prefs.remove(_signedInKey);
      } else {
        await prefs.setString(_signedInKey, user.id);
      }
    } catch (e) {
      debugPrint('push: could not remember the account (${e.runtimeType})');
    }
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      // Through the server: the table's own rules only let an account touch
      // its own rows, so the next account on this phone could never take
      // over a token the last one registered.
      if (user == null) {
        // Guests are not targeted: drop any row this device left behind.
        await SupabaseService.client
            .rpc('release_device_token', params: {'p_token': token});
      } else {
        await SupabaseService.client.rpc('claim_device_token', params: {
          'p_token': token,
          'p_platform': defaultTargetPlatform.name,
        });
      }
    } catch (e) {
      // The table comes from supabase/device_tokens.sql: until it exists,
      // pushes still arrive — they just aren't targeted per account.
      debugPrint('push: token registration failed (${e.runtimeType})');
    }
  }
}

/// Runs on a separate isolate when a data message arrives while the app is
/// backgrounded or closed.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) =>
    PushService._show(message);
