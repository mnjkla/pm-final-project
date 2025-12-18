import 'package:flutter/material.dart';
import 'driver_home_screen.dart'; // Màn hình bản đồ cũ

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedIndex = 0; // Tab hiện tại

  // Danh sách các màn hình con
  final List<Widget> _screens = [
    const DriverHomeScreen(), // Tab 0: Bản đồ & Nhận cuốc
    const DriverEarningsScreen(), // Tab 1: Thu nhập (Tạo bên dưới)
    const DriverProfileScreen(),  // Tab 2: Tài khoản (Tạo bên dưới)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng IndexedStack để giữ trạng thái Online/Offline của bản đồ khi chuyển tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            activeIcon: Icon(Icons.navigation, size: 30),
            label: 'Nhận cuốc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            activeIcon: Icon(Icons.attach_money, size: 30),
            label: 'Thu nhập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person, size: 30),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent, // Màu chủ đạo của Tài xế là Xanh dương
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

// --- MÀN HÌNH GIẢ LẬP: THU NHẬP ---
class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thu nhập hôm nay"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tổng thu nhập
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tổng thu nhập", style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 5),
                      Text("1.250.000đ", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                  Icon(Icons.account_balance_wallet, size: 40, color: Colors.blue[300]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Lịch sử chuyến đi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            // Danh sách chuyến đi
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, i) {
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                    title: Text("Chuyến xe #${1000 + i}"),
                    subtitle: const Text("14:30 - Hoàn thành"),
                    trailing: const Text("+45.000đ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH GIẢ LẬP: TÀI KHOẢN ---
class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hồ sơ tài xế")),
      body: ListView(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            accountName: Text("Nguyễn Văn Tài Xế", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text("Bien so: 59-T1 123.45"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blue)),
          ),
          ListTile(leading: const Icon(Icons.star, color: Colors.orange), title: const Text("Đánh giá: 4.9 sao")),
          ListTile(leading: const Icon(Icons.two_wheeler), title: const Text("Thông tin xe")),
          ListTile(leading: const Icon(Icons.settings), title: const Text("Cài đặt ứng dụng")),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Đăng xuất", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}