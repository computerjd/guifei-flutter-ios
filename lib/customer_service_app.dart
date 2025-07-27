import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/customer_service_dashboard.dart';
import 'screens/customer_service_chat_list.dart';
import 'screens/customer_service_chat_detail.dart';
import 'screens/customer_service_login.dart';
import 'models/customer_service_models.dart';
import 'services/customer_service.dart';
import 'services/auth_service.dart';

// 客服App主入口
class CustomerServiceApp extends StatelessWidget {
  const CustomerServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '贵妃直播 - 客服端',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = AuthService.isLoggedIn;
      final isLoginPage = state.matchedLocation == '/';
      
      // 如果未登录且不在登录页，重定向到登录页
      if (!isLoggedIn && !isLoginPage) {
        return '/';
      }
      
      // 如果已登录且在登录页，重定向到主界面
      if (isLoggedIn && isLoginPage) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CustomerServiceLogin(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const CustomerServiceMainScreen(),
      ),
      GoRoute(
        path: '/chat/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return CustomerServiceChatDetail(sessionId: sessionId);
        },
      ),
    ],
  );
}

// 客服主界面
class CustomerServiceMainScreen extends StatefulWidget {
  const CustomerServiceMainScreen({super.key});

  @override
  State<CustomerServiceMainScreen> createState() => _CustomerServiceMainScreenState();
}

class _CustomerServiceMainScreenState extends State<CustomerServiceMainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const CustomerServiceDashboard(),
    const CustomerServiceChatList(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '工作台',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '会话列表',
          ),
        ],
      ),
    );
  }
}

// 启动客服App的函数
void runCustomerServiceApp() {
  runApp(const CustomerServiceApp());
}

// 主入口函数
void main() {
  runCustomerServiceApp();
}