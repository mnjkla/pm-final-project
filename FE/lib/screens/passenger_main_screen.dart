import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'home_screen.dart';    // Màn hình đặt xe cũ
import 'profile_screen.dart'; // Màn hình hồ sơ mới

class PassengerMainScreen extends StatefulWidget {
  const PassengerMainScreen({super.key});

  @override
  State<PassengerMainScreen> createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends State<PassengerMainScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với từng Tab
  final List<Widget> _screens = [
    const HomeScreen(),      // Tab 0: Đặt xe (Bản đồ)
    const Center(child: Text("Hoạt động (Đang phát triển)")), // Tab 1: Lịch sử
    const ProfileScreen(),   // Tab 2: Cá nhân
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giúp giữ trạng thái màn hình (không bị load lại khi chuyển tab)
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.darkGreen, // Màu khi chọn (Xanh lá)
        unselectedItemColor: Colors.grey,       // Màu khi không chọn
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,    // Cố định vị trí (quan trọng nếu có >3 tab)
        showUnselectedLabels: true,
        elevation: 10,                          // Đổ bóng cho đẹp
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: "Đặt xe",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: "Hoạt động",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }
}