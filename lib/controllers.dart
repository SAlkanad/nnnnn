import 'package:flutter/material.dart';
import 'models.dart';
import 'services.dart';
import 'core.dart';
import 'dart:io';
import 'settings_screens.dart';
class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  String? _lastBiometricError;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get rememberMe => _rememberMe;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  String? get lastBiometricError => _lastBiometricError;

  set rememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  AuthController() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check biometric availability
      await _checkBiometricAvailability();
      
      // Check for auto-login user
      final autoLoginUser = await AuthService.checkAutoLogin();
      if (autoLoginUser != null) {
        _currentUser = autoLoginUser;
        await _updateBiometricStatus();
        notifyListeners();
      }
      
      // Load remember me preference
      _rememberMe = await AuthService.shouldAutoLogin();
      notifyListeners();
    } catch (e) {
      print('❌ Auth initialization error: $e');
      _lastBiometricError = 'خطأ في تهيئة النظام';
      notifyListeners();
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      _biometricAvailable = await BiometricService.isBiometricAvailable();
      _availableBiometrics = await BiometricService.getAvailableBiometrics();
      _lastBiometricError = null;
      
      print('🔍 Biometric status updated:');
      print('  Available: $_biometricAvailable');
      print('  Types: $_availableBiometrics');
      
      notifyListeners();
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      _biometricAvailable = false;
      _availableBiometrics = [];
      _lastBiometricError = 'خطأ في فحص البصمة';
      notifyListeners();
    }
  }

  Future<void> _updateBiometricStatus() async {
    if (_currentUser != null) {
      try {
        _biometricEnabled = await BiometricService.isBiometricEnabled(_currentUser!.id);
        _lastBiometricError = null;
      } catch (e) {
        print('❌ Error updating biometric status: $e');
        _biometricEnabled = false;
        _lastBiometricError = 'خطأ في تحديث حالة البصمة';
      }
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _lastBiometricError = null;
    notifyListeners();

    try {
      _currentUser = await AuthService.login(username, password);
      
      // Save credentials if remember me is enabled
      await AuthService.saveCredentials(username, password, _rememberMe);
      
      // Update biometric status for the logged-in user
      await _updateBiometricStatus();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Login error: $e');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<bool> loginWithBiometric(String username) async {
    if (!_biometricAvailable) {
      throw BiometricException('البصمة غير متاحة على هذا الجهاز');
    }

    _isLoading = true;
    _lastBiometricError = null;
    notifyListeners();

    try {
      // Check if biometric is enabled for this user
      final isEnabled = await BiometricService.isBiometricEnabled(username);
      if (!isEnabled) {
        throw BiometricException('البصمة غير مفعلة لهذا المستخدم');
      }

      // Authenticate with biometrics
      final authenticated = await BiometricService.authenticateWithBiometrics(
        reason: 'استخدم بصمتك لتسجيل الدخول'
      );

      if (authenticated) {
        // Get saved credentials for biometric login
        final credentials = await getSavedCredentials();
        if (credentials['username'] == username && credentials['password'] != null) {
          _currentUser = await AuthService.login(username, credentials['password']!, useBiometric: true);
          _biometricEnabled = true;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw BiometricException('لا توجد بيانات محفوظة لهذا المستخدم');
        }
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Biometric login error: $e');
      _isLoading = false;
      _lastBiometricError = e.toString();
      notifyListeners();
      
      // Re-throw BiometricException as-is
      if (e is BiometricException) {
        rethrow;
      }
      
      // Wrap other exceptions
      throw BiometricException('خطأ في تسجيل الدخول بالبصمة: e.toString()}');
    }
  }

  Future<void> enableBiometric() async {
    if (_currentUser == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    if (!_biometricAvailable) {
      throw BiometricException('البصمة غير متاحة على هذا الجهاز');
    }

    try {
      await BiometricService.enableBiometric(_currentUser!.id);
      _biometricEnabled = true;
      _lastBiometricError = null;
      notifyListeners();
      
      print('✅ Biometric enabled for user: ${_currentUser!.id}');
    } catch (e) {
      print('❌ Error enabling biometric: $e');
      _lastBiometricError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disableBiometric() async {
    if (_currentUser == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    try {
      await BiometricService.disableBiometric(_currentUser!.id);
      _biometricEnabled = false;
      _lastBiometricError = null;
      notifyListeners();
      
      print('✅ Biometric disabled for user: ${_currentUser!.id}');
    } catch (e) {
      print('❌ Error disabling biometric: $e');
      _lastBiometricError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> checkBiometricAvailability() async {
    await _checkBiometricAvailability();
    return _biometricAvailable;
  }

  Future<bool> isBiometricEnabledForUser(String username) async {
    try {
      return await BiometricService.isBiometricEnabled(username);
    } catch (e) {
      print('❌ Error checking biometric enabled for user: $e');
      return false;
    }
  }

  Future<BiometricInfo> getBiometricInfo() async {
    try {
      final info = await BiometricService.getBiometricInfo();
      return BiometricInfo(
        isAvailable: info.isAvailable,
        isEnabled: _biometricEnabled,
        availableTypes: info.availableTypes,
      );
    } catch (e) {
      print('❌ Error getting biometric info: $e');
      return BiometricInfo(
        isAvailable: false,
        isEnabled: false,
        availableTypes: [],
      );
    }
  }

  Future<bool> testBiometricAuthentication() async {
    if (!_biometricAvailable) {
      throw BiometricException('البصمة غير متاحة على هذا الجهاز');
    }

    try {
      return await BiometricService.authenticateWithBiometrics(
        reason: 'اختبار المصادقة ببصمة الإصبع'
      );
    } catch (e) {
      print('❌ Biometric test error: $e');
      _lastBiometricError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetBiometricSettings() async {
    try {
      await BiometricService.resetBiometricSettings();
      _biometricEnabled = false;
      _lastBiometricError = null;
      await _checkBiometricAvailability();
      
      print('✅ Biometric settings reset');
    } catch (e) {
      print('❌ Error resetting biometric settings: $e');
      _lastBiometricError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshBiometricStatus() async {
    await _checkBiometricAvailability();
    if (_currentUser != null) {
      await _updateBiometricStatus();
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
      _currentUser = null;
      _biometricEnabled = false;
      _lastBiometricError = null;
      notifyListeners();
      
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
      // Still clear the current user even if logout fails
      _currentUser = null;
      _biometricEnabled = false;
      notifyListeners();
    }
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    try {
      return await AuthService.getSavedCredentials();
    } catch (e) {
      print('❌ Error getting saved credentials: $e');
      return {'username': null, 'password': null};
    }
  }

  // Helper method to get user-friendly biometric status message
  String getBiometricStatusMessage() {
    if (_lastBiometricError != null) {
      return _lastBiometricError!;
    }

    if (!_biometricAvailable) {
      return 'البصمة غير متاحة على هذا الجهاز';
    }

    if (_availableBiometrics.isEmpty) {
      return 'لا توجد بيانات بيومترية مسجلة في الجهاز';
    }

    if (_currentUser != null && _biometricEnabled) {
      return 'البصمة مفعلة ومتاحة للاستخدام';
    }

    final types = _availableBiometrics.map((type) {
      switch (type) {
        case BiometricType.fingerprint:
          return 'بصمة الإصبع';
        case BiometricType.face:
          return 'التعرف على الوجه';
        case BiometricType.iris:
          return 'مسح القزحية';
        default:
          return 'مصادقة بيومترية';
      }
    }).join(' و ');

    return 'متاح: $types';
  }

  // Helper method to get appropriate icon for biometric type
  IconData getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else {
      return Icons.security;
    }
  }

  // Clear any cached error messages
  void clearBiometricError() {
    _lastBiometricError = null;
    notifyListeners();
  }
}

class ClientController extends ChangeNotifier {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  List<UserModel> _users = [];
  Map<String, UserModel> _userCache = {};
  bool _isLoading = false;
  ClientFilter _currentFilter = ClientFilter();

  List<ClientModel> get clients => _filteredClients.isEmpty && !_currentFilter.hasActiveFilters 
      ? _clients 
      : _filteredClients;
  bool get isLoading => _isLoading;
  ClientFilter get currentFilter => _currentFilter;
  List<UserModel> get users => _users;

  Future<void> loadClients(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        _clients = await DatabaseService.getAllClients();
        _users = await DatabaseService.getAllUsers();
        _buildUserCache();
      } else {
        _clients = await DatabaseService.getClientsByUser(userId);
      }
      
      final settings = await DatabaseService.getAdminSettings();
      final statusSettings = settings['clientStatusSettings'] ?? {};
      final greenDays = statusSettings['greenDays'] ?? 30;
      final yellowDays = statusSettings['yellowDays'] ?? 30;
      final redDays = statusSettings['redDays'] ?? 1;
      
      for (int i = 0; i < _clients.length; i++) {
        final updatedClient = _clients[i].copyWith(
          status: StatusCalculator.calculateStatus(
            _clients[i].entryDate,
            greenDays: greenDays,
            yellowDays: yellowDays,
            redDays: redDays,
          ),
          daysRemaining: StatusCalculator.calculateDaysRemaining(_clients[i].entryDate),
        );
        _clients[i] = updatedClient;
      }

      await _applyCurrentFilter(userId, isAdmin: isAdmin);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  void _buildUserCache() {
    _userCache.clear();
    for (final user in _users) {
      _userCache[user.id] = user;
    }
  }

  Future<void> applyFilter(ClientFilter filter, String userId, {bool isAdmin = false}) async {
    _currentFilter = filter;
    await _applyCurrentFilter(userId, isAdmin: isAdmin);
    notifyListeners();
  }

  Future<void> _applyCurrentFilter(String userId, {bool isAdmin = false}) async {
    try {
      _filteredClients = await DatabaseService.getFilteredClients(
        userId: isAdmin ? null : userId,
        isAdmin: isAdmin,
        filterByUser: _currentFilter.userFilter,
        filterByStatus: _currentFilter.statusFilter,
        filterByVisaType: _currentFilter.visaTypeFilter,
        startDate: _currentFilter.startDate,
        endDate: _currentFilter.endDate,
      );

      if (_currentFilter.searchQuery != null && _currentFilter.searchQuery!.isNotEmpty) {
        final searchLower = _currentFilter.searchQuery!.toLowerCase();
        _filteredClients = _filteredClients.where((client) {
          final name = client.clientName.toLowerCase();
          final phone = client.clientPhone;
          final secondPhone = client.secondPhone ?? '';
          
          return name.contains(searchLower) ||
              phone.contains(_currentFilter.searchQuery!) ||
              secondPhone.contains(_currentFilter.searchQuery!);
        }).toList();
      }
    } catch (e) {
      _filteredClients = [];
    }
  }

  void clearFilter() {
    _currentFilter = ClientFilter();
    _filteredClients = [];
    notifyListeners();
  }

  Future<void> searchClients(String query, String userId, {bool isAdmin = false}) async {
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    await _applyCurrentFilter(userId, isAdmin: isAdmin);
    notifyListeners();
  }

  void clearSearch() {
    _currentFilter = _currentFilter.copyWith(searchQuery: '');
    _filteredClients = [];
    notifyListeners();
  }

  Future<void> addClient(ClientModel client, List<File>? images) async {
    try {
      await DatabaseService.saveClient(client, images);
      
      _clients.insert(0, client);
      
      if (_currentFilter.hasActiveFilters) {
        final authController = _currentFilter.userFilter ?? client.createdBy;
        await _applyCurrentFilter(authController);
      }
      
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateClient(ClientModel client, List<File>? images) async {
    try {
      await DatabaseService.saveClient(client, images);
      
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
      }
      
      final filteredIndex = _filteredClients.indexWhere((c) => c.id == client.id);
      if (filteredIndex != -1) {
        _filteredClients[filteredIndex] = client;
      }
      
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateClientStatus(String clientId, ClientStatus status) async {
    try {
      await DatabaseService.updateClientStatus(clientId, status);
      
      final index = _clients.indexWhere((client) => client.id == clientId);
      if (index != -1) {
        _clients[index] = _clients[index].copyWith(
          status: status,
          hasExited: status == ClientStatus.white,
        );
      }
      
      final filteredIndex = _filteredClients.indexWhere((client) => client.id == clientId);
      if (filteredIndex != -1) {
        _filteredClients[filteredIndex] = _filteredClients[filteredIndex].copyWith(
          status: status,
          hasExited: status == ClientStatus.white,
        );
      }
      
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await DatabaseService.deleteClient(clientId);
      
      _clients.removeWhere((client) => client.id == clientId);
      _filteredClients.removeWhere((client) => client.id == clientId);
      
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> refreshClients(String userId, {bool isAdmin = false}) async {
    await StatusUpdateService.forceUpdateAllStatuses();
    await loadClients(userId, isAdmin: isAdmin);
  }

  List<ClientModel> getClientsByStatus(ClientStatus status) {
    final currentClients = clients;
    return currentClients.where((client) => client.status == status).toList();
  }

  List<ClientModel> getExpiringClients(int days) {
    final currentClients = clients;
    return currentClients.where((client) => 
      client.daysRemaining <= days && 
      client.daysRemaining >= 0 && 
      !client.hasExited
    ).toList();
  }

  String? getUserNameById(String userId) {
    try {
      if (_userCache.containsKey(userId)) {
        return _userCache[userId]!.name;
      }
      final user = _users.firstWhere((u) => u.id == userId);
      return user.name;
    } catch (e) {
      return null;
    }
  }

  int getClientsCount() => _clients.length;
  
  int getActiveClientsCount() => _clients.where((c) => !c.hasExited).length;
  
  int getExitedClientsCount() => _clients.where((c) => c.hasExited).length;
}

class UserController extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await DatabaseService.getAllUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> addUser(UserModel user) async {
    try {
      await DatabaseService.saveUser(user);
      _users.insert(0, user);
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await DatabaseService.saveUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        await DatabaseService.clearCache();
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await DatabaseService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> freezeUser(String userId, String reason) async {
    try {
      await DatabaseService.freezeUser(userId, reason);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = UserModel(
          id: _users[index].id,
          username: _users[index].username,
          password: _users[index].password,
          role: _users[index].role,
          name: _users[index].name,
          phone: _users[index].phone,
          email: _users[index].email,
          isActive: _users[index].isActive,
          isFrozen: true,
          freezeReason: reason,
          validationEndDate: _users[index].validationEndDate,
          createdAt: _users[index].createdAt,
          createdBy: _users[index].createdBy,
        );
        await DatabaseService.clearCache();
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> unfreezeUser(String userId) async {
    try {
      await DatabaseService.unfreezeUser(userId);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = UserModel(
          id: _users[index].id,
          username: _users[index].username,
          password: _users[index].password,
          role: _users[index].role,
          name: _users[index].name,
          phone: _users[index].phone,
          email: _users[index].email,
          isActive: _users[index].isActive,
          isFrozen: false,
          freezeReason: null,
          validationEndDate: _users[index].validationEndDate,
          createdAt: _users[index].createdAt,
          createdBy: _users[index].createdBy,
        );
        await DatabaseService.clearCache();
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> setUserValidation(String userId, DateTime endDate) async {
    try {
      await DatabaseService.setUserValidation(userId, endDate);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = UserModel(
          id: _users[index].id,
          username: _users[index].username,
          password: _users[index].password,
          role: _users[index].role,
          name: _users[index].name,
          phone: _users[index].phone,
          email: _users[index].email,
          isActive: _users[index].isActive,
          isFrozen: _users[index].isFrozen,
          freezeReason: _users[index].freezeReason,
          validationEndDate: endDate,
          createdAt: _users[index].createdAt,
          createdBy: _users[index].createdBy,
        );
        await DatabaseService.clearCache();
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<List<ClientModel>> getUserClients(String userId) async {
    try {
      return await DatabaseService.getClientsByUser(userId);
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendNotificationToUser(String userId, String message) async {
    try {
      final notification = NotificationModel(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.userValidationExpiring,
        title: 'إشعار من الإدارة',
        message: message,
        targetUserId: userId,
        createdAt: DateTime.now(),
      );
      
      await DatabaseService.saveNotification(notification);
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendNotificationToAllUsers(String message) async {
    try {
      for (final user in _users) {
        await sendNotificationToUser(user.id, message);
      }
    } catch (e) {
      throw e;
    }
  }
}

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        final settings = await DatabaseService.getAdminSettings();
        final adminFilters = settings['adminFilters'] ?? {};
        final showOnlyMyNotifications = adminFilters['showOnlyMyNotifications'] ?? false;
        
        if (showOnlyMyNotifications) {
          _notifications = await DatabaseService.getNotificationsByUser(userId);
        } else {
          _notifications = await DatabaseService.getAllNotifications();
        }
      } else {
        _notifications = await DatabaseService.getNotificationsByUser(userId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await DatabaseService.markNotificationAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          targetUserId: _notifications[index].targetUserId,
          clientId: _notifications[index].clientId,
          isRead: true,
          priority: _notifications[index].priority,
          createdAt: _notifications[index].createdAt,
          scheduledFor: _notifications[index].scheduledFor,
        );
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendWhatsAppToClient(ClientModel client, String message) async {
    try {
      final formattedMessage = MessageTemplates.formatMessage(
        message,
        {
          'clientName': client.clientName,
          'daysRemaining': client.daysRemaining.toString(),
        }
      );
      
      await WhatsAppService.sendClientMessage(
        phoneNumber: client.clientPhone,
        country: client.phoneCountry,
        message: formattedMessage,
        clientName: client.clientName,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> callClient(ClientModel client) async {
    try {
      await WhatsAppService.callClient(
        phoneNumber: client.clientPhone,
        country: client.phoneCountry,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendWhatsAppToUser(UserModel user, String message) async {
    try {
      final formattedMessage = MessageTemplates.formatMessage(
        message,
        {
          'userName': user.name,
        }
      );
      
      await WhatsAppService.sendUserMessage(
        phoneNumber: user.phone,
        message: formattedMessage,
        userName: user.name,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> createClientExpiringNotification(ClientModel client) async {
    try {
      final settings = await DatabaseService.getAdminSettings();
      final whatsappMessages = settings['whatsappMessages'] ?? {};
      final defaultMessage = whatsappMessages['clientMessage'] ?? 
          MessageTemplates.whatsappMessages['client_default'];

      final notification = NotificationModel(
        id: '${client.id}_expiring_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.clientExpiring,
        title: 'تنبيه انتهاء تأشيرة',
        message: MessageTemplates.formatMessage(defaultMessage!, {
          'clientName': client.clientName,
          'daysRemaining': client.daysRemaining.toString(),
        }),
        targetUserId: client.createdBy,
        clientId: client.id,
        priority: _getPriorityFromDays(client.daysRemaining),
        createdAt: DateTime.now(),
      );

      await DatabaseService.saveNotification(notification);
      _notifications.insert(0, notification);
      
      await NotificationService.showNotification(
        id: notification.hashCode,
        title: notification.title,
        body: notification.message,
        payload: notification.id,
      );
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> createUserValidationNotification(UserModel user) async {
    try {
      final daysRemaining = user.validationEndDate?.difference(DateTime.now()).inDays ?? 0;
      final settings = await DatabaseService.getAdminSettings();
      final whatsappMessages = settings['whatsappMessages'] ?? {};
      final defaultMessage = whatsappMessages['userMessage'] ?? 
          MessageTemplates.whatsappMessages['user_default'];

      final notification = NotificationModel(
        id: '${user.id}_validation_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.userValidationExpiring,
        title: 'تنبيه انتهاء صلاحية الحساب',
        message: MessageTemplates.formatMessage(defaultMessage!, {
          'userName': user.name,
          'daysRemaining': daysRemaining.toString(),
        }),
        targetUserId: user.id,
        priority: _getPriorityFromDays(daysRemaining),
        createdAt: DateTime.now(),
      );

      await DatabaseService.saveNotification(notification);
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  NotificationPriority _getPriorityFromDays(int days) {
    if (days <= 2) return NotificationPriority.high;
    if (days <= 5) return NotificationPriority.medium;
    return NotificationPriority.low;
  }

  List<NotificationModel> getClientNotifications() {
    return _notifications.where((n) => n.type == NotificationType.clientExpiring).toList();
  }

  List<NotificationModel> getUserNotifications() {
    return _notifications.where((n) => n.type == NotificationType.userValidationExpiring).toList();
  }

  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }
}

class SettingsController extends ChangeNotifier {
  Map<String, dynamic> _adminSettings = {};
  Map<String, dynamic> _userSettings = {};
  bool _isLoading = false;

  Map<String, dynamic> get adminSettings => _adminSettings;
  Map<String, dynamic> get userSettings => _userSettings;
  bool get isLoading => _isLoading;

  Future<void> loadAdminSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _adminSettings = await DatabaseService.getAdminSettings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> loadUserSettings(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userSettings = await DatabaseService.getUserSettings(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateAdminSettings(Map<String, dynamic> settings) async {
    try {
      await DatabaseService.saveAdminSettings(settings);
      _adminSettings = settings;
      await DatabaseService.clearCache();
      await StatusUpdateService.forceUpdateAllStatuses();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await DatabaseService.saveUserSettings(userId, settings);
      _userSettings = settings;
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateStatusSettings(StatusSettings settings) async {
    try {
      _adminSettings['clientStatusSettings'] = settings.toMap();
      await DatabaseService.saveAdminSettings(_adminSettings);
      await DatabaseService.clearCache();
      await StatusUpdateService.forceUpdateAllStatuses();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      _adminSettings['clientNotificationSettings'] = {
        'firstTier': settings.clientTiers[0].toMap(),
        'secondTier': settings.clientTiers[1].toMap(),
        'thirdTier': settings.clientTiers[2].toMap(),
      };
      _adminSettings['userNotificationSettings'] = {
        'firstTier': settings.userTiers[0].toMap(),
        'secondTier': settings.userTiers[1].toMap(),
        'thirdTier': settings.userTiers[2].toMap(),
      };
      await DatabaseService.saveAdminSettings(_adminSettings);
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateWhatsAppMessages(String clientMessage, String userMessage) async {
    try {
      _adminSettings['whatsappMessages'] = {
        'clientMessage': clientMessage,
        'userMessage': userMessage,
      };
      await DatabaseService.saveAdminSettings(_adminSettings);
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAdminFilters(bool showOnlyMyClients, bool showOnlyMyNotifications) async {
    try {
      _adminSettings['adminFilters'] = {
        'showOnlyMyClients': showOnlyMyClients,
        'showOnlyMyNotifications': showOnlyMyNotifications,
      };
      await DatabaseService.saveAdminSettings(_adminSettings);
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}