import 'package:flutter/material.dart';
import '../core/app_colors.dart'; // Import file màu từ Core

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- HEADER & AVATAR ---
          SizedBox(
            height: size.height * 0.35,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Nền xanh
                Container(
                  height: size.height * 0.28,
                  width: double.infinity,
                  color: AppColors.lightBackground, // Dùng màu từ Core
                  padding: const EdgeInsets.only(top: 60, left: 20),
                  child: const Text(
                    "Admin",
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.black54,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Avatar tròn
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 65,
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?q=80&w=200&auto=format&fit=crop',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- SEARCH BAR ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  "Chọn điểm đến",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 50),

          // --- SERVICE BUTTONS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildServiceButton(Icons.two_wheeler, "Bike"),
              _buildServiceButton(Icons.directions_car, "Car"),
              _buildServiceButton(Icons.inventory_2, "Delivery"),
            ],
          ),

          const Spacer(),

          // --- FAKE BOTTOM BAR ---
          Container(
            height: 80,
            color: AppColors.lightBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => _buildBottomDot()),
            ),
          ),
        ],
      ),
    );
  }

  // Widget con: Nút dịch vụ
  Widget _buildServiceButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Icon(icon, size: 40, color: AppColors.darkGreen),
        ),
        const SizedBox(height: 10),
        // Có thể thêm Text label ở đây nếu muốn
      ],
    );
  }

  // Widget con: Chấm tròn bottom bar
  Widget _buildBottomDot() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}