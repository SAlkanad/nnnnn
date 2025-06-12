import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services.dart';
import 'firebase_options.dart';
import 'network_utils.dart';
import 'models.dart';

class AppInitializationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      await _initializeFirebase();
      await _initializeNotifications();
      _initializeTimezone();
      await _initializeNetworkMonitoring();
      await _requestPermissions();
      await _initializeBiometrics();
      await _ensureDefaultAdmin();
      await _initializeCache();
      _startBackgroundServices();

      print('✅ App initialization completed successfully');
    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    }
  }

  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    print('✅ Firebase initialized');
  }

  static Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification received: ${response.payload}');
      },
    );

    print('✅ Notifications initialized');
  }

  static void _initializeTimezone() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    print('✅ Timezone initialized');
  }

  static Future<void> _initializeNetworkMonitoring() async {
    await NetworkUtils.initialize();
    print('✅ Network monitoring initialized');
  }

  static Future<void> _requestPermissions() async {
    final permissions = [
      Permission.notification,
      Permission.storage,
      Permission.camera,
      Permission.photos,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      print('Permission ${permission.toString()}: ${status.toString()}');
    }

    print('✅ Permissions requested');
  }

  static Future<void> _initializeBiometrics() async {
    try {
      final isAvailable = await BiometricService.isBiometricAvailable();
      final availableTypes = await BiometricService.getAvailableBiometrics();
      
      print('✅ Biometrics initialized - Available: $isAvailable, Types: $availableTypes');
    } catch (e) {
      print('⚠️ Biometrics initialization failed: $e');
    }
  }

  static Future<void> _ensureDefaultAdmin() async {
    try {
      await AuthService.createDefaultAdmin();
      print('✅ Default admin verified/created');
    } catch (e) {
      print('❌ Failed to create default admin: $e');
      rethrow;
    }
  }

  static Future<void> _initializeCache() async {
    try {
      CacheManager.clear();
      CacheManager.clearExpired();
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('✅ Cache initialized and cleared');
    } catch (e) {
      print('⚠️ Cache initialization warning: $e');
    }
  }

  static void _startBackgroundServices() {
    StatusUpdateService.startPeriodicUpdates();
    NotificationService.startScheduledNotifications();
    
    print('✅ Background services started');
  }

  static Future<void> dispose() async {
    try {
      StatusUpdateService.stopPeriodicUpdates();
      NotificationService.stopScheduledNotifications();
      NetworkUtils.dispose();
      CacheManager.clear();
      
      print('✅ App cleanup completed');
    } catch (e) {
      print('⚠️ App cleanup warning: $e');
    }
  }
}

class StatusUpdateService {
  static Timer? _updateTimer;
  static bool _isRunning = false;

  static void startPeriodicUpdates() {
    if (_isRunning) return;
    
    _isRunning = true;
    _updateTimer = Timer.periodic(Duration(hours: 1), (timer) async {
      try {
        await forceUpdateAllStatuses();
        CacheManager.clearExpired();
      } catch (e) {
        print('❌ Periodic status update failed: $e');
      }
    });
    
    print('✅ Periodic status updates started');
  }

  static void stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isRunning = false;
    
    print('✅ Periodic status updates stopped');
  }

  static Future<void> forceUpdateAllStatuses() async {
    try {
      CacheManager.clear('clients');
      CacheManager.clear('users');
      CacheManager.clear('notifications');
      
      final clients = await DatabaseService.getAllClients();
      final now = DateTime.now();
      
      for (final client in clients) {
        final daysSinceEntry = now.difference(client.entryDate).inDays;
        final daysRemaining = _calculateDaysRemaining(client.visaType, daysSinceEntry);
        final newStatus = _calculateStatus(daysRemaining);
        
        if (client.status != newStatus || client.daysRemaining != daysRemaining) {
          await DatabaseService.updateClientStatus(client.id, newStatus);
        }
      }
      
      print('✅ All client statuses updated');
    } catch (e) {
      print('❌ Status update failed: $e');
      throw e;
    }
  }

  static int _calculateDaysRemaining(VisaType visaType, int daysSinceEntry) {
    int totalDays;
    switch (visaType) {
      case VisaType.umrah:
        totalDays = 30;
        break;
      case VisaType.hajj:
        totalDays = 45;
        break;
      case VisaType.visit:
        totalDays = 90;
        break;
      case VisaType.work:
        totalDays = 365;
        break;
    }
    return totalDays - daysSinceEntry;
  }

  static ClientStatus _calculateStatus(int daysRemaining) {
    if (daysRemaining <= 0) {
      return ClientStatus.white;
    } else if (daysRemaining <= 1) {
      return ClientStatus.red;
    } else if (daysRemaining <= 30) {
      return ClientStatus.yellow;
    } else {
      return ClientStatus.green;
    }
  }
}

class NotificationService {
  static Timer? _notificationTimer;
  static bool _isRunning = false;

  static get CommunicationService => null;

  static void startScheduledNotifications() {
    if (_isRunning) return;
    
    _isRunning = true;
    _notificationTimer = Timer.periodic(Duration(minutes: 30), (timer) async {
      try {
        await _processScheduledNotifications();
      } catch (e) {
        print('❌ Scheduled notifications failed: $e');
      }
    });
    
    print('✅ Scheduled notifications started');
  }

  static void stopScheduledNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _isRunning = false;
    
    print('✅ Scheduled notifications stopped');
  }

  static Future<void> _processScheduledNotifications() async {
    try {
      final clients = await DatabaseService.getAllClients();
      final settings = await DatabaseService.getAdminSettings();
      final notificationSettings = NotificationSettings.fromMap(settings['notificationSettings'] ?? {});
      
      for (final client in clients) {
        if (client.hasExited) continue;
        
        await _checkClientNotifications(client, notificationSettings);
      }
      
      print('✅ Scheduled notifications processed');
    } catch (e) {
      print('❌ Notification processing failed: $e');
    }
  }

  static Future<void> _checkClientNotifications(
    ClientModel client, 
    NotificationSettings settings
  ) async {
    for (final tier in settings.clientTiers) {
      if (client.daysRemaining <= tier.days && client.daysRemaining > 0) {
        final notification = NotificationModel(
          id: '',
          type: NotificationType.clientExpiring,
          title: 'تنبيه انتهاء تأشيرة',
          message: tier.message.replaceAll('{clientName}', client.clientName)
              .replaceAll('{daysRemaining}', client.daysRemaining.toString()),
          targetUserId: client.createdBy,
          clientId: client.id,
          priority: _getPriority(client.daysRemaining),
          createdAt: DateTime.now(),
        );
        
        await DatabaseService.saveNotification(notification);
        await _sendWhatsAppMessage(client, tier.message);
      }
    }
  }

  static NotificationPriority _getPriority(int daysRemaining) {
    if (daysRemaining <= 1) return NotificationPriority.high;
    if (daysRemaining <= 5) return NotificationPriority.medium;
    return NotificationPriority.low;
  }

  static Future<void> _sendWhatsAppMessage(ClientModel client, String message) async {
    try {
      final formattedMessage = message
          .replaceAll('{clientName}', client.clientName)
          .replaceAll('{daysRemaining}', client.daysRemaining.toString());
      
      await CommunicationService.sendWhatsAppMessage(
        client.fullClientPhone,
        formattedMessage,
      );
    } catch (e) {
      print('⚠️ WhatsApp message failed for ${client.clientName}: $e');
    }
  }
}