import 'package:flutter/material.dart';
import 'home_screen.dart'; // Màn hình đặt xe cũ của bạn
import 'profile_screen.dart'; // Màn hình cá nhân (Bước 3)
import '../core/app_colors.dart';

class PassengerMainScreen extends StatefulWidget {
  const PassengerMainScreen({super.key});

  @override
  State<PassengerMainScreen> createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends State<PassengerMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),        // Tab 0: Đặt xe
    const Center(child: Text("Hoạt động")), // Tab 1: Lịch sử (Làm sau)
    const ProfileScreen(),     // Tab 2: Cá nhân
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Giữ trạng thái các tab khi chuyển đổi
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Hoạt động"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cá nhân"),
        ],
      ),
    );
  }
}