import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import '../models/shared_models.dart';
import 'shared_api_service.dart';

/// 用户认证服务
/// 根据新数据库设计重新构建
class AuthService {
  static const String baseUrl = 'http://localhost:3000/api'; // 数据库API服务器地址
  static FullUserInfo? _currentUser;
  static String? _authToken;
  
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// 获取当前用户
  static FullUserInfo? get currentUser => _currentUser;
  
  /// 获取认证令牌
  static String? get authToken => _authToken;
  
  /// 是否已登录
  static bool get isLoggedIn => _currentUser != null && _authToken != null;

  /// 设置认证令牌
  static void _setAuthToken(String? token) {
    _authToken = token;
    SharedApiService.setAuthToken(token);
    if (token != null) {
      _headers['Authorization'] = 'Bearer $token';
    } else {
      _headers.remove('Authorization');
    }
  }

  /// 用户登录
  static Future<ApiResponse<FullUserInfo>> login({
    required String phone,
    required String password,
    required UserType userType,
  }) async {
    try {
      final response = await SharedApiService.login(
        phone: phone,
        password: password,
        userType: userType.value,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _setAuthToken(data['token'] as String?);
        
        // 获取完整用户信息
        final userInfo = await SharedApiService.getUserInfo(data['user_id'] as String);
        if (userInfo != null) {
          _currentUser = userInfo;
          return ApiResponse(
            success: true,
            message: '登录成功',
            data: userInfo,
          );
        } else {
          return ApiResponse(
            success: false,
            message: '获取用户信息失败',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? '登录失败',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络连接失败: $e',
      );
    }
  }

  /// 用户注册
  static Future<ApiResponse<FullUserInfo>> register({
    required String username,
    required String phone,
    required String password,
    required String nickname,
    required int gender,
    required String birthday,
    required UserType userType,
  }) async {
    try {
      final response = await SharedApiService.register(
        username: username,
        phone: phone,
        password: password,
        nickname: nickname,
        gender: gender,
        birthday: birthday,
        userType: userType.value,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _setAuthToken(data['token'] as String?);
        
        // 获取完整用户信息
        final userInfo = await SharedApiService.getUserInfo(data['user_id'] as String);
        if (userInfo != null) {
          _currentUser = userInfo;
          return ApiResponse(
            success: true,
            message: '注册成功',
            data: userInfo,
          );
        } else {
          return ApiResponse(
            success: false,
            message: '获取用户信息失败',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? '注册失败',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络连接失败: $e',
      );
    }
  }

  /// 刷新用户信息
  static Future<bool> refreshUserInfo() async {
    if (_currentUser == null) return false;
    
    try {
      final userInfo = await SharedApiService.getUserInfo(_currentUser!.user.id);
      if (userInfo != null) {
        _currentUser = userInfo;
        return true;
      }
      return false;
    } catch (e) {
      print('刷新用户信息失败: $e');
      return false;
    }
  }

  /// 更新用户信息
  static Future<bool> updateUserInfo(Map<String, dynamic> updateData) async {
    if (_currentUser == null) return false;
    
    try {
      final success = await SharedApiService.updateUserInfo(_currentUser!.user.id, updateData);
      if (success) {
        await refreshUserInfo();
      }
      return success;
    } catch (e) {
      print('更新用户信息失败: $e');
      return false;
    }
  }

  /// 修改密码
  static Future<ApiResponse<bool>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return ApiResponse(
        success: false,
        message: '用户未登录',
      );
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${_currentUser!.user.id}/password'),
        headers: _headers,
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      final data = json.decode(response.body);
      return ApiResponse(
        success: data['success'] == true,
        message: data['message'] ?? (data['success'] == true ? '密码修改成功' : '密码修改失败'),
        data: data['success'] == true,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络连接失败: $e',
      );
    }
  }

  /// 忘记密码
  static Future<ApiResponse<bool>> forgotPassword(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: _headers,
        body: json.encode({'phone': phone}),
      );

      final data = json.decode(response.body);
      return ApiResponse(
        success: data['success'] == true,
        message: data['message'] ?? (data['success'] == true ? '重置密码链接已发送' : '发送失败'),
        data: data['success'] == true,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络连接失败: $e',
      );
    }
  }

  /// 验证令牌
  static Future<bool> validateToken() async {
    if (_authToken == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/validate-token'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // 刷新用户信息
          await refreshUserInfo();
          return true;
        }
      }
      
      // 令牌无效，清除登录状态
      logout();
      return false;
    } catch (e) {
      print('验证令牌失败: $e');
      return false;
    }
  }

  /// 用户登出
  static void logout() {
    _currentUser = null;
    _setAuthToken(null);
  }

  /// 检查用户权限
  static bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    
    // 根据用户类型判断权限
    switch (_currentUser!.user.userType) {
      case UserType.admin:
        return true; // 管理员拥有所有权限
      case UserType.service:
        return ['view_users', 'manage_live', 'manage_content'].contains(permission);
      case UserType.anchor:
        return ['create_live', 'manage_own_live', 'upload_video'].contains(permission);
      case UserType.consumer:
        return ['view_live', 'send_message', 'send_gift'].contains(permission);
      default:
        return false;
    }
  }

  /// 检查是否可以评论
  static bool canComment() {
    if (_currentUser == null) return false;
    
    // 根据消费等级判断评论权限
    if (_currentUser!.user.userType == UserType.consumer && _currentUser!.consumerInfo != null) {
      return _currentUser!.consumerInfo!.consumptionLevel >= 2; // 需要2级以上才能评论
    }
    
    // 其他用户类型默认可以评论
    return _currentUser!.user.userType != UserType.consumer;
  }

  /// 检查是否可以连麦
  static bool canMic() {
    if (_currentUser == null) return false;
    
    // 根据消费等级判断连麦权限
    if (_currentUser!.user.userType == UserType.consumer && _currentUser!.consumerInfo != null) {
      return _currentUser!.consumerInfo!.consumptionLevel >= 20; // 需要20级以上才能连麦
    }
    
    // 其他用户类型默认可以连麦
    return _currentUser!.user.userType != UserType.consumer;
  }

  /// 获取用户显示名称
  static String getUserDisplayName() {
    if (_currentUser == null) return '未登录';
    return _currentUser!.user.nickname.isNotEmpty 
        ? _currentUser!.user.nickname 
        : _currentUser!.user.username;
  }

  /// 获取用户头像
  static String getUserAvatar() {
    if (_currentUser == null) return 'https://via.placeholder.com/100';
    return _currentUser!.user.avatar ?? 'https://via.placeholder.com/100';
  }

  /// 获取用户类型显示文本
  static String getUserTypeText() {
    if (_currentUser == null) return '未知';
    
    switch (_currentUser!.user.userType) {
      case UserType.admin:
        return '管理员';
      case UserType.service:
        return '客服';
      case UserType.anchor:
        return '主播';
      case UserType.consumer:
        return '用户';
      default:
        return '未知';
    }
  }

  /// 获取消费等级文本
  static String getConsumerLevelText() {
    if (_currentUser == null || 
        _currentUser!.user.userType != UserType.consumer || 
        _currentUser!.consumerInfo == null) {
      return '';
    }
    
    return 'VIP${_currentUser!.consumerInfo!.vipLevel}';
  }

  /// 模拟登录（用于测试）
  static Future<ApiResponse<FullUserInfo>> mockLogin(UserType userType) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 1));
    
    final now = DateTime.now();
    final userId = 'mock_${userType.name}_${now.millisecondsSinceEpoch}';
    
    final user = User(
      id: userId,
      username: 'test_${userType.name}',
      phone: '13800138000',
      nickname: '测试${_getUserTypeDisplayName(userType)}',
      avatar: 'https://via.placeholder.com/100',
      gender: 1,
      birthday: DateTime.parse('1990-01-01'),
      userType: userType,
      status: UserStatus.normal,
      registerTime: now,
    );
    
    FullUserInfo fullUserInfo;
    
    switch (userType) {
      case UserType.consumer:
        fullUserInfo = FullUserInfo(
          user: user,
          consumerInfo: ConsumerInfo(
            userId: userId,
            vipLevel: 1,
            consumptionLevel: 3,
            balance: 500.0,
            totalSpent: 1000.0,
          ),
        );
        break;
      case UserType.anchor:
        fullUserInfo = FullUserInfo(
          user: user,
          anchorInfo: AnchorInfo(
            userId: userId,
            liveLevel: 5,
            fansCount: 1000,
            totalIncome: 2000.0,
            withdrawable: 1500.0,
            withdrawn: 500.0,
            verifyStatus: 1,
          ),
        );
        break;
      case UserType.service:
        fullUserInfo = FullUserInfo(
          user: user,
          serviceInfo: ServiceInfo(
            userId: userId,
            kefuNickname: '客服小助手',
          ),
        );
        break;
      case UserType.admin:
        fullUserInfo = FullUserInfo(
          user: user,
          adminInfo: AdminInfo(
            userId: userId,
            adminNickname: '系统管理员',
          ),
        );
        break;
      default:
        fullUserInfo = FullUserInfo(user: user);
    }
    
    _currentUser = fullUserInfo;
    _setAuthToken('mock_token_${userId}');
    
    return ApiResponse(
      success: true,
      message: '登录成功',
      data: fullUserInfo,
    );
  }
  
  static String _getUserTypeDisplayName(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return '管理员';
      case UserType.service:
        return '客服';
      case UserType.anchor:
        return '主播';
      case UserType.consumer:
        return '用户';
      default:
        return '未知';
    }
  }
}