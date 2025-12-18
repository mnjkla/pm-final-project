
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Màn hình bản đồ cũ
import '../core/app_colors.dart'; // Màu sắc (nếu có) hoặc dùng Colors.green

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Tab hiện tại

  // Danh sách các màn hình tương ứng với các Tab
  final List<Widget> _screens = [
    const HomeScreen(),       // Tab 0: Bản đồ
    const PlaceholderScreen(title: "Lịch sử chuyến đi", icon: Icons.history), // Tab 1: Hoạt động (Tạm)
    const PlaceholderScreen(title: "Tài khoản của bạn", icon: Icons.person),  // Tab 2: Tài khoản (Tạm)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng IndexedStack để giữ trạng thái bản đồ khi chuyển tab (không bị load lại)
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Hoạt động',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[700], // Màu chủ đạo
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Cố định vị trí các nút
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

// Widget tạm để hiển thị cho Tab Hoạt động & Tài khoản
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}