import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent, // 移除波紋效果
        highlightColor: Colors.transparent, // 移除高亮效果
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconSize: 24, // 縮小圖標尺寸
          selectedFontSize: 10, // 縮小選中時的字體
          unselectedFontSize: 10, // 縮小未選中時的字體
          unselectedItemColor: Colors.grey,
          selectedItemColor: Colors.blue,
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed, // 防止點擊動畫
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              activeIcon: Icon(Icons.home, color: Colors.blue),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music),
              label: 'Library',
              activeIcon: Icon(Icons.library_music, color: Colors.blue),
            ),
          ],
          onTap: onTap,
        ),
      ),
    );
  }
}
