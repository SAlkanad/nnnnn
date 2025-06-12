import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'services.dart';
import 'settings_screens.dart';
import 'screens.dart';
import 'models.dart';
import 'core.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'controllers.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => LoginScreen(),
          settings: RouteSettings(name: '/'),
        );

      case '/admin_dashboard':
        return MaterialPageRoute(
          builder: (_) => AdminDashboard(),
          settings: RouteSettings(name: '/admin_dashboard'),
        );

      case '/user_dashboard':
        return MaterialPageRoute(
          builder: (_) => UserDashboard(),
          settings: RouteSettings(name: '/user_dashboard'),
        );

      case '/admin/add_client':
        return MaterialPageRoute(
          builder: (_) => ClientFormScreen(),
          settings: RouteSettings(name: '/admin/add_client'),
        );

      case '/admin/edit_client':
        final client = settings.arguments as ClientModel?;
        return MaterialPageRoute(
          builder: (_) => ClientFormScreen(client: client),
          settings: RouteSettings(name: '/admin/edit_client'),
        );

      case '/admin/manage_clients':
        return MaterialPageRoute(
          builder: (_) => ClientManagementScreen(),
          settings: RouteSettings(name: '/admin/manage_clients'),
        );

      case '/admin/manage_users':
        return MaterialPageRoute(
          builder: (_) => UserManagementScreen(),
          settings: RouteSettings(name: '/admin/manage_users'),
        );

      case '/admin/add_user':
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(),
          settings: RouteSettings(name: '/admin/add_user'),
        );

      case '/admin/edit_user':
        final user = settings.arguments as UserModel?;
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(user: user),
          settings: RouteSettings(name: '/admin/edit_user'),
        );

      case '/admin/user_clients':
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => UserClientsScreen(user: user),
          settings: RouteSettings(name: '/admin/user_clients'),
        );

      case '/admin/notifications':
        return MaterialPageRoute(
          builder: (_) => AdminNotificationsScreen(),
          settings: RouteSettings(name: '/admin/notifications'),
        );

      case '/admin/settings':
        return MaterialPageRoute(
          builder: (_) => AdminSettingsScreen(),
          settings: RouteSettings(name: '/admin/settings'),
        );

      case '/user/add_client':
        return MaterialPageRoute(
          builder: (_) => UserClientFormScreen(),
          settings: RouteSettings(name: '/user/add_client'),
        );

      case '/user/edit_client':
        final client = settings.arguments as ClientModel?;
        return MaterialPageRoute(
          builder: (_) => UserClientFormScreen(client: client),
          settings: RouteSettings(name: '/user/edit_client'),
        );

      case '/user/manage_clients':
        return MaterialPageRoute(
          builder: (_) => UserClientManagementScreen(),
          settings: RouteSettings(name: '/user/manage_clients'),
        );

      case '/user/notifications':
        return MaterialPageRoute(
          builder: (_) => UserNotificationsScreen(),
          settings: RouteSettings(name: '/user/notifications'),
        );

      case '/user/settings':
        return MaterialPageRoute(
          builder: (_) => UserSettingsScreen(),
          settings: RouteSettings(name: '/user/settings'),
        );

      case '/view_images':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ImageViewer(
            imageUrls: args['imageUrls'] as List<String>,
            initialIndex: args['initialIndex'] as int? ?? 0,
            clientName: args['clientName'] as String?,
          ),
          settings: RouteSettings(name: '/view_images'),
        );

      case '/client_images':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ClientImagesScreen(
            client: args['client'] as ClientModel,
            canEdit: args['canEdit'] as bool? ?? false,
          ),
          settings: RouteSettings(name: '/client_images'),
        );

      case '/biometric_setup':
        return MaterialPageRoute(
          builder: (_) => BiometricSetupScreen(),
          settings: RouteSettings(name: '/biometric_setup'),
        );

      case '/not_found':
        return MaterialPageRoute(
          builder: (_) => NotFoundScreen(),
          settings: RouteSettings(name: '/not_found'),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => NotFoundScreen(),
          settings: RouteSettings(name: '/not_found'),
        );
    }
  }

  static void pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }

  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  static void pushAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      routeName, 
      (route) => false,
      arguments: arguments,
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة غير موجودة'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              'الصفحة المطلوبة غير موجودة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'تحقق من الرابط وحاول مرة أخرى',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: Text('العودة للصفحة الرئيسية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientImagesScreen extends StatefulWidget {
  final ClientModel client;
  final bool canEdit;

  const ClientImagesScreen({
    Key? key,
    required this.client,
    this.canEdit = false,
  }) : super(key: key);

  @override
  State<ClientImagesScreen> createState() => _ClientImagesScreenState();
}

class _ClientImagesScreenState extends State<ClientImagesScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صور العميل - ${widget.client.clientName}'),
        actions: [
          if (widget.canEdit)
            IconButton(
              icon: Icon(Icons.add_photo_alternate),
              onPressed: _addImages,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : widget.client.imageUrls.isEmpty
              ? _buildEmptyState()
              : _buildImageGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'لا توجد صور للعميل',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (widget.canEdit) ...[
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addImages,
              icon: Icon(Icons.add_photo_alternate),
              label: Text('إضافة صور'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: widget.client.imageUrls.length,
      itemBuilder: (context, index) {
        return _buildImageTile(index);
      },
    );
  }

  Widget _buildImageTile(int index) {
    final imageUrl = widget.client.imageUrls[index];
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewImage(index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.error,
                color: Colors.red,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.white, size: 20),
                      onPressed: () => _downloadImage(imageUrl),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    if (widget.canEdit)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteImage(index),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewImage(int index) {
    Navigator.pushNamed(
      context,
      '/view_images',
      arguments: {
        'imageUrls': widget.client.imageUrls,
        'initialIndex': index,
        'clientName': widget.client.clientName,
      },
    );
  }

  void _addImages() async {
    setState(() => _isLoading = true);
    try {
      final result = await ImageService.pickMultipleImages();
      if (result != null && result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة ${result.length} صورة')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إضافة الصور')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _downloadImage(String imageUrl) async {
    try {
      await ImageService.downloadImage(imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحميل الصورة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الصورة')),
      );
    }
  }

  void _deleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف الصورة'),
        content: Text('هل تريد حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف الصورة')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف الصورة')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Enhanced BiometricSetupScreen
class BiometricSetupScreen extends StatefulWidget {
  final String? username;
  final bool isFromSettings;

  const BiometricSetupScreen({
    Key? key,
    this.username,
    this.isFromSettings = false,
  }) : super(key: key);

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen>
    with TickerProviderStateMixin {
  bool _isChecking = true;
  bool _isAvailable = false;
  bool _isEnabled = false;
  List<BiometricType> _availableTypes = [];
  String _statusMessage = '';
  String? _errorMessage;

  late AnimationController _pulseController;
  late AnimationController _checkController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkBiometricStatus() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final isAvailable = await BiometricService.isBiometricAvailable();
      final availableTypes = await BiometricService.getAvailableBiometrics();
      
      bool isEnabled = false;
      if (widget.username != null) {
        isEnabled = await BiometricService.isBiometricEnabled(widget.username!);
      }

      setState(() {
        _isAvailable = isAvailable;
        _availableTypes = availableTypes;
        _isEnabled = isEnabled;
        _statusMessage = _generateStatusMessage();
        _isChecking = false;
      });

      if (_isAvailable) {
        _pulseController.stop();
        _checkController.forward();
      }
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _isEnabled = false;
        _errorMessage = e.toString();
        _statusMessage = 'خطأ في فحص البصمة';
        _isChecking = false;
      });
      _pulseController.stop();
    }
  }

  String _generateStatusMessage() {
    if (!_isAvailable) {
      if (_availableTypes.isEmpty) {
        return 'لا توجد بيانات بيومترية مسجلة على هذا الجهاز.\nيرجى إضافة بصمة إصبع أو وجه في إعدادات الجهاز.';
      }
      return 'البصمة غير متاحة على هذا الجهاز.';
    }

    if (_isEnabled) {
      return 'البصمة مفعلة ومتاحة للاستخدام.';
    }

    final types = _availableTypes.map((type) {
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

    return 'يمكنك استخدام $types لتسجيل الدخول السريع والآمن.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFromSettings ? 'إعدادات البصمة' : 'إعداد البصمة'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBiometricIcon(),
                    const SizedBox(height: 32),
                    _buildStatusCard(),
                    const SizedBox(height: 32),
                    _buildInstructions(),
                  ],
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricIcon() {
    IconData iconData;
    Color iconColor;

    if (_isChecking) {
      iconData = Icons.fingerprint;
      iconColor = Colors.grey;
    } else if (!_isAvailable) {
      iconData = Icons.fingerprint_outlined;
      iconColor = Colors.red;
    } else if (_isEnabled) {
      iconData = _getPrimaryBiometricIcon();
      iconColor = Colors.green;
    } else {
      iconData = _getPrimaryBiometricIcon();
      iconColor = Colors.blue;
    }

    Widget iconWidget = Icon(
      iconData,
      size: 100,
      color: iconColor,
    );

    if (_isChecking) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: iconWidget,
          );
        },
      );
    } else if (_isAvailable) {
      return AnimatedBuilder(
        animation: _checkAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _checkAnimation.value,
            child: iconWidget,
          );
        },
      );
    }

    return iconWidget;
  }

  Widget _buildStatusCard() {
    Color cardColor;
    Color textColor;
    IconData statusIcon;

    if (_isChecking) {
      cardColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      statusIcon = Icons.search;
    } else if (!_isAvailable) {
      cardColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      statusIcon = Icons.error_outline;
    } else if (_isEnabled) {
      cardColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
    } else {
      cardColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      statusIcon = Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    if (_isChecking || !_isAvailable) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'نصائح مهمة:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._getInstructionsList().map((instruction) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.grey.shade600)),
                Expanded(
                  child: Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isAvailable && !_isEnabled && widget.username != null) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isChecking ? null : _enableBiometric,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: Icon(_getPrimaryBiometricIcon()),
              label: Text(
                'تفعيل البصمة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        if (_isAvailable && _isEnabled && widget.username != null) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _testBiometric,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: Icon(Icons.play_arrow),
              label: Text(
                'اختبار البصمة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _disableBiometric,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.fingerprint_outlined, color: Colors.red),
              label: Text(
                'إلغاء تفعيل البصمة',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (!_isAvailable) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openDeviceSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.settings),
              label: Text(
                'فتح إعدادات الجهاز',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Always show refresh button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _checkBiometricStatus,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.refresh),
            label: Text(
              'إعادة فحص',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        // Close/Skip button
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context, _isEnabled),
          child: Text(
            widget.isFromSettings ? 'إغلاق' : (_isEnabled ? 'متابعة' : 'تخطي'),
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  String _getStatusTitle() {
    if (_isChecking) {
      return 'جاري فحص البصمة...';
    } else if (!_isAvailable) {
      return 'البصمة غير متاحة';
    } else if (_isEnabled) {
      return 'البصمة مفعلة';
    } else {
      return 'البصمة متاحة';
    }
  }

  IconData _getPrimaryBiometricIcon() {
    if (_availableTypes.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableTypes.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableTypes.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else {
      return Icons.security;
    }
  }

  List<String> _getInstructionsList() {
    List<String> instructions = [];

    if (_availableTypes.contains(BiometricType.fingerprint)) {
      instructions.addAll([
        'تأكد من نظافة وجفاف إصبعك',
        'ضع إصبعك بالكامل على المستشعر',
        'لا تضغط بقوة مفرطة على المستشعر',
      ]);
    }

    if (_availableTypes.contains(BiometricType.face)) {
      instructions.addAll([
        'تأكد من وجود إضاءة كافية',
        'انظر مباشرة إلى الكاميرا',
        'احتفظ بالجهاز على مستوى العين',
      ]);
    }

    instructions.addAll([
      'يمكنك إلغاء البصمة في أي وقت من الإعدادات',
      'البصمة تعمل فقط مع هذا الجهاز',
    ]);

    return instructions;
  }

  Future<void> _enableBiometric() async {
    if (widget.username == null) {
      _showMessage('خطأ: اسم المستخدم غير متوفر', isError: true);
      return;
    }

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      await authController.enableBiometric();
      
      setState(() {
        _isEnabled = true;
        _statusMessage = _generateStatusMessage();
      });

      _showMessage('تم تفعيل البصمة بنجاح');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    }
  }

  Future<void> _disableBiometric() async {
    if (widget.username == null) {
      _showMessage('خطأ: اسم المستخدم غير متوفر', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء تفعيل البصمة'),
        content: Text('هل أنت متأكد من إلغاء تفعيل البصمة؟ ستحتاج لإدخال كلمة المرور عند تسجيل الدخول.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authController = Provider.of<AuthController>(context, listen: false);
        await authController.disableBiometric();
        
        setState(() {
          _isEnabled = false;
          _statusMessage = _generateStatusMessage();
        });

        _showMessage('تم إلغاء تفعيل البصمة');
      } catch (e) {
        _showMessage(e.toString(), isError: true);
      }
    }
  }

  Future<void> _testBiometric() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.testBiometricAuthentication();
      
      if (success) {
        _showMessage('تم اختبار البصمة بنجاح');
      } else {
        _showMessage('فشل في اختبار البصمة', isError: true);
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    }
  }

  Future<void> _openDeviceSettings() async {
    try {
      // This would open device settings - implementation depends on platform
      _showMessage('يرجى فتح إعدادات الجهاز وإضافة بصمة أو وجه في قسم الحماية والأمان');
    } catch (e) {
      _showMessage('لا يمكن فتح إعدادات الجهاز تلقائياً', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}